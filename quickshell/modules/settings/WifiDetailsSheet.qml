// Los "Detalles…" de una red Wi-Fi: la hoja de detalles de conexión,
// alimentada por WifiControl. Todo lo que se ve está en
// ConnectionDetailsSheet; aquí solo se dice de quién son los datos.

import qs.domain.network

ConnectionDetailsSheet {
    control: WifiControl
    kind: "wifi"
}
