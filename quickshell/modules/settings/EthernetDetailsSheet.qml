// Los "Detalles…" de un servicio de red por cable: la misma hoja que en
// Wi-Fi, alimentada por EthernetControl.

import qs.domain.network

ConnectionDetailsSheet {
    control: EthernetControl
    kind: "wired"
}
