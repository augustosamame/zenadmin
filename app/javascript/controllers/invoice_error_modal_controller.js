import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]
  static values = {
    orderId: Number
  }

  connect() {
    console.log("Order ID:", this.orderIdValue) // For debugging
    this.loaderController = this.application.getControllerForElementAndIdentifier(
      document.getElementById('global-loader'),
      'loader'
    )
  }

  open() {
    this.modalTarget.classList.remove("hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")
  }

  async resendInvoice(event) {
    event.preventDefault()

    if (this.loaderController) {
      this.loaderController.show()
    } else {
      console.error('Loader controller not found')
    }

    try {
      const response = await fetch(`/admin/orders/${this.orderIdValue}/retry_invoice`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ order_id: this.orderIdValue })
      })

      if (response.ok) {
        const data = await response.json()
        if (data.success) {
          // Close the modal
          this.close()
          // Refresh the page
          window.location.reload()
        } else {
          console.error('Failed to resend invoice')
        }
      } else {
        console.error('Failed to resend invoice')
      }
    } catch (error) {
      console.error('Error:', error)
    } finally {
      if (this.loaderController) this.loaderController.hide()
    }
  }
}