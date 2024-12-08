import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    orderId: String
  }

  handleSubmit(event) {
    event.preventDefault()
    const form = event.target

    fetch(form.action, {
      method: form.method,
      body: new FormData(form),
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then(response => {
        if (response.status === 422) {
          return response.text().then(html => {
            this.element.innerHTML = html
          })
        } else if (response.ok) {
          window.location.href = response.url
        }
      })
  }

  openModal(event) {
    event.preventDefault()

    const customModal = document.querySelector('[data-controller="custom-modal"]')
    if (customModal) {
      const modalController = this.application.getControllerForElementAndIdentifier(customModal, 'custom-modal')

      fetch(`/admin/orders/${this.orderIdValue}/external_invoices/new`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
        .then(response => response.text())
        .then(html => {
          modalController.openWithContent(
            "Agregar Comprobante",
            html,
            [
              {
                label: 'Cancelar',
                classes: 'btn btn-secondary',
                action: 'click->custom-modal#close'
              }
            ]
          )
        })
    }
  }
}