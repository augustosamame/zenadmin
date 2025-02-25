import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["orderTotal", "assignedTotal", "remainingTotal", "amountInput", "lines", "submitButton"]

  connect() {
    this.orderTotalCents = parseInt(this.element.dataset.paymentEditorTotalValue) || 0
    this.orderTotal = this.orderTotalCents / 100
    this.updateTotals()
  }

  addPayment(event) {
    event.preventDefault()
    const template = document.getElementById("payment-template")
    if (!template) return

    const clone = template.content.cloneNode(true)
    const newId = new Date().getTime()
    
    // Update all IDs and names in the cloned template
    clone.querySelectorAll("[id]").forEach(el => {
      el.id = el.id.replace("NEW_RECORD", newId)
    })
    clone.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace("NEW_RECORD", newId)
    })
    
    this.linesTarget.appendChild(clone)
    
    // Initialize any Stimulus controllers in the new content
    this.application.controllers.forEach(controller => {
      if (controller.context.scope.element.contains(this.linesTarget)) {
        controller.connect()
      }
    })
  }

  removePayment(event) {
    const line = event.target.closest(".nested-fields")
    const destroyField = line.querySelector("input[name*='_destroy']")
    
    if (destroyField) {
      destroyField.value = "1"
      line.style.display = "none"
    } else {
      line.remove()
    }
    
    this.updateTotals()
  }

  updateTotals() {
    const assignedTotal = this.calculateAssignedTotal()
    const remainingTotal = this.orderTotal - assignedTotal
    
    this.assignedTotalTarget.textContent = this.formatCurrency(assignedTotal)
    this.remainingTotalTarget.textContent = this.formatCurrency(remainingTotal)
    
    // Enable/disable submit button based on total match
    const isValid = Math.abs(remainingTotal) < 0.01
    this.submitButtonTarget.disabled = !isValid
  }

  calculateAssignedTotal() {
    return this.amountInputTargets.reduce((sum, input) => {
      const line = input.closest(".nested-fields")
      if (line && line.style.display !== "none") {
        return sum + (parseFloat(input.value) || 0)
      }
      return sum
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
}