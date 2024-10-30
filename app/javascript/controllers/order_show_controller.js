import { Controller } from "@hotwired/stimulus"
import { whatsappIcon } from "../icons"

export default class extends Controller {
  static targets = ["phoneInput"]
  static values = {
    orderId: String,
    invoiceUrl: String,
    xmlUrl: String,
    customerPhone: String
  }

  connect() {
    console.log("OrderShowController connected")
  }

  showWhatsAppModal(event) {
    const type = event.params.type
    const url = type === 'pdf' ? this.invoiceUrlValue : this.xmlUrlValue

    if (this.customerPhoneValue) {
      this.sendWhatsApp(this.customerPhoneValue, url, type)
    } else {
      this.showPhoneInputModal(url, type)
    }
  }

  showPhoneInputModal(url, type) {
    const customModal = document.querySelector('[data-controller="custom-modal"]')
    if (customModal) {
      const modalController = this.application.getControllerForElementAndIdentifier(customModal, 'custom-modal')

      const content = `
        <div class="space-y-4">
          <p class="text-sm text-gray-600">Ingrese el número de WhatsApp para enviar el ${type === 'pdf' ? 'comprobante' : 'XML'}</p>
          <div class="space-y-2">
            <input type="tel" class="w-full px-3 py-2 border rounded-md" 
              placeholder="Ingrese número de WhatsApp" 
              data-order-show-target="phoneInput">
          </div>
        </div>
      `

      modalController.openWithContent(
        `Enviar ${type === 'pdf' ? 'Comprobante' : 'XML'} por WhatsApp`,
        content,
        [
          {
            label: 'Enviar',
            classes: 'btn btn-primary',
            action: () => {
              const phone = this.phoneInputTarget.value
              if (phone) {
                this.sendWhatsApp(phone, url, type)
                modalController.close()
              } else {
                alert("Por favor, ingrese un número de WhatsApp válido")
              }
            }
          },
          {
            label: 'Cancelar',
            classes: 'btn btn-secondary',
            action: 'click->custom-modal#close'
          }
        ]
      )
    }
  }

  sendWhatsApp(phone, url, type) {
    phone = phone.replace(/\D/g, '')
    if (!phone.startsWith('51')) {
      phone = '51' + phone
    }
    const message = encodeURIComponent(
      `Adjuntamos ${type === 'pdf' ? 'el comprobante' : 'el XML del comprobante'} de pago por la Venta #${this.orderIdValue}: ${url}`
    )
    window.open(`https://wa.me/${phone}?text=${message}`, '_blank')
  }
}