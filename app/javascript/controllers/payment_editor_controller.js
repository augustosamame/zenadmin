import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amount", "paymentsTotal", "totalError", "submitButton"]

  connect() {
    this.orderTotal = parseFloat(document.querySelector('[data-order-total]').dataset.orderTotal)
    this.validateTotal()
  }

  validateTotal() {
    const total = this.calculateTotal()
    this.paymentsTotalTarget.textContent = this.formatCurrency(total)

    const difference = Math.abs(total - this.orderTotal)
    const isValid = difference < 0.01 // Allow for small rounding differences

    this.totalErrorTarget.classList.toggle('hidden', isValid)
    this.submitButtonTarget.disabled = !isValid

    if (!isValid) {
      this.totalErrorTarget.textContent = `El total de los pagos debe ser igual al total de la venta (${this.formatCurrency(this.orderTotal)})`
    }
  }

  validateBeforeSubmit(event) {
    if (!this.isValid()) {
      event.preventDefault()
    }
  }

  calculateTotal() {
    return this.amountTargets.reduce((sum, input) => {
      return sum + (parseFloat(input.value) || 0)
    }, 0)
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('es-PE', {
      style: 'currency',
      currency: 'PEN',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount)
  }

  isValid() {
    const total = this.calculateTotal()
    return Math.abs(total - this.orderTotal) < 0.01
  }
}