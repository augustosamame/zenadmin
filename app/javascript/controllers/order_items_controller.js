import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "price", "lineTotal", "orderTotal"]

  calculateTotal() {
    let total = 0

    this.quantityTargets.forEach((quantityField, index) => {
      const quantity = parseInt(quantityField.value) || 0
      const price = parseFloat(this.priceTargets[index].value) || 0
      const lineTotal = quantity * price

      this.lineTotalTargets[index].textContent = this.formatCurrency(lineTotal)
      total += lineTotal
    })

    this.orderTotalTarget.textContent = this.formatCurrency(total)
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('es-PE', {
      style: 'currency',
      currency: 'PEN',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount)
  }
}