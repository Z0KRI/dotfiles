// CASOS DE USO: acciones sobre la sesión y el equipo.
// Hoy solo delegan. Aquí vivirán las reglas cuando lleguen
// (por ejemplo: pedir confirmación antes de apagar).

pragma Singleton

import Quickshell
import qs.data.session

Singleton {
    id: root

    readonly property string userName: SessionRepository.userName

    function forceQuit(): void { SessionRepository.forceQuit(); }
    function suspend(): void { SessionRepository.suspend(); }
    function reboot(): void { SessionRepository.reboot(); }
    function powerOff(): void { SessionRepository.powerOff(); }
    function lock(): void { SessionRepository.lock(); }
    function logout(): void { SessionRepository.logout(); }
}