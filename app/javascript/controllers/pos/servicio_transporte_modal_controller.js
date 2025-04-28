import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "container", "content", "descripcion", "transportista", "direccionOrigen", "ubigeoOrigen",
    "direccionDestino", "ubigeoDestino", "valorServicio", "valorCargaEfectiva", "valorCargaUtil",
    "restarDetraccion", "guiaRemision", "guiaTransportista", "detraccionUseValorReferencial"
  ];

  connect() {
    console.log("ServicioTransporteModalController connected");
  }

  open() {
    console.log("Opening servicio transporte modal");
    this.containerTarget.classList.remove('hidden');
    this.contentTarget.classList.remove('hidden');
  }

  close() {
    this.containerTarget.classList.add('hidden');
    this.contentTarget.classList.add('hidden');
  }

  save() {
    const data = {
      descripcion: this.descripcionTarget.value,
      transportista_id: this.transportistaTarget.value,
      direccion_origen: this.direccionOrigenTarget.value,
      ubigeo_origen: this.ubigeoOrigenTarget.value,
      direccion_destino: this.direccionDestinoTarget.value,
      ubigeo_destino: this.ubigeoDestinoTarget.value,
      valor_servicio: this.valorServicioTarget.value,
      valor_carga_efectiva: this.valorCargaEfectivaTarget.value,
      valor_carga_util: this.valorCargaUtilTarget.value,
      detraccion_use_valor_referencial: this.detraccionUseValorReferencialTarget.checked,
      restar_detraccion: this.restarDetraccionTarget.checked,
      guia_remision: this.guiaRemisionTarget.value,
      guia_transportista: this.guiaTransportistaTarget.value
    };
    // Save to order-items container as data attribute
    const orderItems = document.querySelector('[data-controller="pos--order-items"]');
    if (orderItems) {
      orderItems.dataset.servicioTransporte = JSON.stringify(data);
    }
    // Change button color if form has any value
    const btn = document.querySelector('#transport-service-last-button-container button');
    if (btn) {
      const hasValue = Object.values(data).some(v => v && (typeof v === 'boolean' ? v : String(v).trim() !== ''));
      if (hasValue) {
        btn.classList.add('bg-primary-500', 'text-white');
        btn.classList.remove('bg-white');
      } else {
        btn.classList.remove('bg-primary-500', 'text-white');
        btn.classList.add('bg-white');
      }
    }
    this.close();
  }
}
