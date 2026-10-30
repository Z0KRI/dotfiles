#!/usr/bin/env python3
"""Empareja UN dispositivo Bluetooth y muestra su código por stdout.

Lo arranca data/bluetooth/PairingRepository.qml al tocar "Conectar" en
Ajustes › Bluetooth, y se cierra solo al terminar. Existe porque Quickshell no
trae un "agente de emparejamiento": la pieza que BlueZ llama cuando hace falta
un código. Sin agente, BlueZ no puede emparejar un teclado.

Cómo funciona
-------------
1. Se registra ante BlueZ como agente (org.bluez.AgentManager1.RegisterAgent).
2. Llama él mismo a Device1.Pair(). Ese detalle importa: BlueZ le pasa las
   peticiones de código al agente DEL QUE PIDIÓ emparejar. Así no hace falta
   ser el agente "por defecto" del sistema, ni pelearse con bluetoothctl o
   blueman si también están corriendo.
3. Lo que BlueZ le pide (mostrar un PIN, confirmar un número...) sale por stdout
   como una línea JSON, y la respuesta de la shell llega por stdin, también en
   JSON. Una línea por mensaje.
4. Al emparejar, conecta el dispositivo, se da de baja y sale.

Si este proceso muere a media espera, BlueZ cancela el emparejamiento solo: el
Pair() iba atado a su conexión al bus.

Mensajes (stdout)
-----------------
    {"event": "started"}                        agente listo, emparejando
    {"event": "pin", "code": "494235"}          escríbelo en el teclado (PIN clásico)
    {"event": "passkey", "code": "...", "entered": 2}
                                                escríbelo; `entered` = dígitos ya tecleados
    {"event": "confirm", "code": "123456"}      ¿coincide con el de la otra pantalla?
    {"event": "enter-pin"}                      el aparato pide que TÚ escribas un PIN
    {"event": "enter-passkey"}                  ídem, un número de hasta 6 cifras
    {"event": "cancelled"}                      BlueZ retiró la petición: el código ya no
                                                hace falta (también justo antes del final)
    {"event": "paired"}
    {"event": "connected"}
    {"event": "done"}                           última línea si todo salió bien
    {"event": "failed", "error": "org.bluez.Error...", "message": "..."}

Órdenes (stdin)
---------------
    {"action": "accept"}                        "sí coincide"
    {"action": "reject"}
    {"action": "pin", "value": "0000"}
    {"action": "passkey", "value": "123456"}
    {"action": "cancel"}

Uso:  pair-agent.py AA:BB:CC:DD:EE:FF
Salida: 0 emparejado · 1 falló o se canceló · 2 uso incorrecto · 3 falta python-gobject
"""

import json
import os
import re
import signal
import sys


def emit(event, **fields):
    fields["event"] = event
    print(json.dumps(fields, ensure_ascii=False), flush=True)


try:
    import gi

    gi.require_version("Gio", "2.0")
    from gi.repository import Gio, GLib
except (ImportError, ValueError):
    emit("failed", error="dotfiles.Error.NoGObject", message="falta python-gobject")
    sys.exit(3)


BLUEZ = "org.bluez"
DEVICE = "org.bluez.Device1"
AGENT_PATH = "/org/dotfiles/quickshell/pairagent"

# KeyboardDisplay: "tengo pantalla y teclado". Es lo que dice una computadora.
# Con eso BlueZ elige el método correcto con cada aparato: a un teclado le
# muestra un código para escribir; a un teléfono, un número para comparar.
CAPABILITY = "KeyboardDisplay"

# Escribir el código en el teclado toma su tiempo. BlueZ corta cada petición a
# los 60 s; esto es solo el tope de la llamada a Pair(), por si BlueZ no
# contestara nunca.
PAIR_TIMEOUT_MS = 120_000
CONNECT_TIMEOUT_MS = 30_000
SHORT_TIMEOUT_MS = 5_000

AGENT_XML = """
<node>
  <interface name="org.bluez.Agent1">
    <method name="Release"/>
    <method name="RequestPinCode">
      <arg type="o" name="device" direction="in"/>
      <arg type="s" name="pincode" direction="out"/>
    </method>
    <method name="DisplayPinCode">
      <arg type="o" name="device" direction="in"/>
      <arg type="s" name="pincode" direction="in"/>
    </method>
    <method name="RequestPasskey">
      <arg type="o" name="device" direction="in"/>
      <arg type="u" name="passkey" direction="out"/>
    </method>
    <method name="DisplayPasskey">
      <arg type="o" name="device" direction="in"/>
      <arg type="u" name="passkey" direction="in"/>
      <arg type="q" name="entered" direction="in"/>
    </method>
    <method name="RequestConfirmation">
      <arg type="o" name="device" direction="in"/>
      <arg type="u" name="passkey" direction="in"/>
    </method>
    <method name="RequestAuthorization">
      <arg type="o" name="device" direction="in"/>
    </method>
    <method name="AuthorizeService">
      <arg type="o" name="device" direction="in"/>
      <arg type="s" name="uuid" direction="in"/>
    </method>
    <method name="Cancel"/>
  </interface>
</node>
"""

ADDRESS = re.compile(r"^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$")

# Lo que se puede contestar a cada petición pendiente.
ANSWERS = {
    "confirm": {"accept", "reject"},
    "enter-pin": {"pin", "reject"},
    "enter-passkey": {"passkey", "reject"},
}


class Failure(Exception):
    def __init__(self, error, message=""):
        super().__init__(message)
        self.error = error
        self.message = message


def error_name(error):
    """El nombre D-Bus de un GLib.Error ("org.bluez.Error.AuthenticationFailed")."""
    if Gio.DBusError.is_remote_error(error):
        name = Gio.DBusError.get_remote_error(error) or ""
        Gio.DBusError.strip_remote_error(error)
        return name
    if error.matches(Gio.io_error_quark(), Gio.IOErrorEnum.TIMED_OUT):
        return "dotfiles.Error.Timeout"
    return "dotfiles.Error.Local"


class Pairing:
    def __init__(self, address):
        self.address = address.upper()
        self.loop = GLib.MainLoop()
        self.bus = None
        self.device_path = None
        self.registration = 0
        self.registered = False
        self.finished = False
        self.exit_code = 1

        # La petición de BlueZ que espera respuesta de la shell, si hay una:
        # (tipo, invocación). Solo una a la vez: BlueZ no pide dos.
        self.waiting = None

        self.stdin_buffer = b""

    # ── arranque ──────────────────────────────────────────────────

    def run(self):
        try:
            self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
            self.bluez = self.owner_of(BLUEZ)
            self.device_path, paired = self.find_device()
            self.register_agent()
        except Failure as failure:
            self.fail(failure.error, failure.message)
            return self.exit_code

        GLib.io_add_watch(
            sys.stdin.fileno(),
            GLib.PRIORITY_DEFAULT,
            GLib.IOCondition.IN | GLib.IOCondition.HUP | GLib.IOCondition.ERR,
            self.on_stdin,
        )
        for number in (signal.SIGTERM, signal.SIGINT):
            GLib.unix_signal_add(GLib.PRIORITY_HIGH, number, self.on_signal)

        # De confianza ANTES de emparejar: así BlueZ no pregunta por cada
        # servicio al conectar, y después se reconecta solo.
        self.set_trusted()

        emit("started")
        if paired:
            self.on_paired()
        else:
            self.call_device("Pair", PAIR_TIMEOUT_MS, self.on_pair_finished)

        self.loop.run()
        return self.exit_code

    def owner_of(self, name):
        try:
            reply = self.bus.call_sync(
                "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                "GetNameOwner", GLib.Variant("(s)", (name,)), GLib.VariantType("(s)"),
                Gio.DBusCallFlags.NONE, SHORT_TIMEOUT_MS, None)
        except GLib.Error:
            raise Failure("dotfiles.Error.NoBluez", "bluetoothd no está corriendo")
        return reply.unpack()[0]

    def find_device(self):
        try:
            reply = self.bus.call_sync(
                BLUEZ, "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects",
                None, GLib.VariantType("(a{oa{sa{sv}}})"),
                Gio.DBusCallFlags.NONE, SHORT_TIMEOUT_MS, None)
        except GLib.Error as error:
            raise Failure(error_name(error), error.message)

        for path, interfaces in reply.unpack()[0].items():
            device = interfaces.get(DEVICE)
            if device and str(device.get("Address", "")).upper() == self.address:
                return path, bool(device.get("Paired", False))

        raise Failure("org.bluez.Error.DoesNotExist", "el dispositivo ya no está a la vista")

    def register_agent(self):
        info = Gio.DBusNodeInfo.new_for_xml(AGENT_XML).interfaces[0]

        # GLib 2.84 cambió cómo los lenguajes como Python registran objetos
        # (la versión vieja manejaba mal la "invocación" que aquí se guarda
        # para contestar después). Se usa la nueva si existe.
        register = getattr(self.bus, "register_object_with_closures2", None) \
            or self.bus.register_object
        self.registration = register(AGENT_PATH, info, self.on_method_call, None, None)

        try:
            self.bus.call_sync(
                BLUEZ, "/org/bluez", "org.bluez.AgentManager1", "RegisterAgent",
                GLib.Variant("(os)", (AGENT_PATH, CAPABILITY)), None,
                Gio.DBusCallFlags.NONE, SHORT_TIMEOUT_MS, None)
        except GLib.Error as error:
            raise Failure(error_name(error), error.message)
        self.registered = True

    def set_trusted(self):
        try:
            self.bus.call_sync(
                BLUEZ, self.device_path, "org.freedesktop.DBus.Properties", "Set",
                GLib.Variant("(ssv)", (DEVICE, "Trusted", GLib.Variant("b", True))), None,
                Gio.DBusCallFlags.NONE, SHORT_TIMEOUT_MS, None)
        except GLib.Error:
            # No es grave: se empareja igual, solo que BlueZ preguntará más.
            pass

    def call_device(self, method, timeout, callback):
        self.bus.call(
            BLUEZ, self.device_path, DEVICE, method, None, None,
            Gio.DBusCallFlags.NONE, timeout, None, callback)

    # ── emparejar y conectar ──────────────────────────────────────

    def on_pair_finished(self, bus, result):
        try:
            bus.call_finish(result)
        except GLib.Error as error:
            name = error_name(error)
            # "Ya existe" = ya estaba emparejado: para la shell es un éxito.
            if name != "org.bluez.Error.AlreadyExists":
                self.fail(name, error.message)
                return
        self.on_paired()

    def on_paired(self):
        self.drop_waiting("org.bluez.Error.Canceled")
        emit("paired")
        self.call_device("Connect", CONNECT_TIMEOUT_MS, self.on_connect_finished)

    def on_connect_finished(self, bus, result):
        try:
            bus.call_finish(result)
            emit("connected")
        except GLib.Error as error:
            # Un teclado suele conectarse él solo justo después de emparejar,
            # y entonces BlueZ contesta "ya conectado" o "en curso". Si de
            # verdad no conecta, igual quedó emparejado: se avisa y ya.
            name = error_name(error)
            if name in ("org.bluez.Error.AlreadyConnected", "org.bluez.Error.InProgress"):
                emit("connected")
            else:
                emit("connect-failed", error=name, message=error.message)
        self.finish(0)

    def cancel(self):
        self.drop_waiting("org.bluez.Error.Canceled")
        if self.device_path:
            try:
                self.bus.call_sync(
                    BLUEZ, self.device_path, DEVICE, "CancelPairing", None, None,
                    Gio.DBusCallFlags.NONE, SHORT_TIMEOUT_MS, None)
            except GLib.Error:
                pass

    # ── el agente: lo que BlueZ nos pide ──────────────────────────

    def on_method_call(self, connection, sender, path, interface, method, parameters, invocation):
        # Solo BlueZ habla con el agente. La política del bus de sistema ya lo
        # impide, pero no cuesta nada comprobarlo.
        if sender != self.bluez:
            invocation.return_dbus_error("org.bluez.Error.Rejected", "solo BlueZ")
            return

        args = parameters.unpack()

        if method == "Release":
            invocation.return_value(None)
            return

        if method == "Cancel":
            # Por ejemplo, pasó un minuto sin que se escribiera el código.
            self.drop_waiting("org.bluez.Error.Canceled")
            emit("cancelled")
            invocation.return_value(None)
            return

        # Todo lo demás es sobre un dispositivo: solo atendemos el nuestro.
        if not args or args[0] != self.device_path:
            invocation.return_dbus_error("org.bluez.Error.Rejected", "no es el que se empareja")
            return

        if method == "DisplayPinCode":
            # El PIN clásico de los teclados: BlueZ inventa uno y hay que
            # escribirlo en el teclado. Se contesta ya; BlueZ avisa con Cancel
            # o con el fin de Pair() cuando deja de hacer falta.
            emit("pin", code=args[1])
            invocation.return_value(None)
        elif method == "DisplayPasskey":
            # Igual, pero BlueZ vuelve a llamar con cada dígito tecleado.
            emit("passkey", code="%06d" % args[1], entered=int(args[2]))
            invocation.return_value(None)
        elif method == "RequestConfirmation":
            self.wait("confirm", invocation)
            emit("confirm", code="%06d" % args[1])
        elif method == "RequestPinCode":
            self.wait("enter-pin", invocation)
            emit("enter-pin")
        elif method == "RequestPasskey":
            self.wait("enter-passkey", invocation)
            emit("enter-passkey")
        elif method in ("RequestAuthorization", "AuthorizeService"):
            # Lo pediste tú desde Ajustes: aceptar es la respuesta.
            invocation.return_value(None)
        else:
            invocation.return_dbus_error("org.bluez.Error.Rejected", "método desconocido")

    def wait(self, kind, invocation):
        self.drop_waiting("org.bluez.Error.Canceled")
        self.waiting = (kind, invocation)

    def drop_waiting(self, error):
        if self.waiting:
            _, invocation = self.waiting
            self.waiting = None
            invocation.return_dbus_error(error, "")

    def answer(self, command):
        action = command.get("action")

        if action == "cancel":
            self.cancel()
            return

        if not self.waiting or action not in ANSWERS[self.waiting[0]]:
            return

        kind, invocation = self.waiting
        self.waiting = None
        value = str(command.get("value", "")).strip()

        if action == "accept":
            invocation.return_value(None)
        elif action == "pin" and 1 <= len(value) <= 16:
            invocation.return_value(GLib.Variant("(s)", (value,)))
        elif action == "passkey" and value.isdigit() and int(value) <= 999999:
            invocation.return_value(GLib.Variant("(u)", (int(value),)))
        else:
            invocation.return_dbus_error("org.bluez.Error.Rejected", "rechazado")

    # ── stdin, señales y salida ───────────────────────────────────

    def on_stdin(self, fd, condition):
        data = os.read(fd, 4096) if condition & GLib.IOCondition.IN else b""
        if not data:
            # La shell se cerró: sin nadie que muestre el código, no tiene
            # sentido seguir esperando.
            self.cancel()
            self.finish(1)
            return False

        self.stdin_buffer += data
        while b"\n" in self.stdin_buffer:
            line, self.stdin_buffer = self.stdin_buffer.split(b"\n", 1)
            try:
                command = json.loads(line)
            except ValueError:
                continue
            if isinstance(command, dict):
                self.answer(command)
        return True

    def on_signal(self):
        self.cancel()
        self.finish(1)
        return GLib.SOURCE_REMOVE

    def fail(self, error, message):
        emit("failed", error=error, message=message)
        self.finish(1)

    def finish(self, code):
        if self.finished:
            return
        self.finished = True
        self.exit_code = code
        self.drop_waiting("org.bluez.Error.Canceled")

        if self.registered:
            try:
                self.bus.call_sync(
                    BLUEZ, "/org/bluez", "org.bluez.AgentManager1", "UnregisterAgent",
                    GLib.Variant("(o)", (AGENT_PATH,)), None,
                    Gio.DBusCallFlags.NONE, SHORT_TIMEOUT_MS, None)
            except GLib.Error:
                pass
            self.registered = False

        if self.registration:
            self.bus.unregister_object(self.registration)
            self.registration = 0

        if code == 0:
            emit("done")
        if self.loop.is_running():
            self.loop.quit()


def main():
    if len(sys.argv) != 2 or not ADDRESS.match(sys.argv[1]):
        emit("failed", error="dotfiles.Error.Usage", message="uso: pair-agent.py AA:BB:CC:DD:EE:FF")
        return 2
    return Pairing(sys.argv[1]).run()


if __name__ == "__main__":
    sys.exit(main())
