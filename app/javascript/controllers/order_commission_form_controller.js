import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "lines", "percentageInput", "amountInput", 
                   "orderTotal", "assignedTotal", "remainingTotal", "submitButton"]
  static values = { total: Number }

  connect() {
    this.updateTotals()
  }

  updateAmount(event) {
    const line = event.target.closest('[data-order-commission-form-target="line"]')
    const percentage = parseFloat(event.target.value) || 0
    const totalAmount = this.totalValue / 100 // Convert cents to currency
    const amount = (totalAmount * (percentage / 100)).toFixed(2)
    
    line.querySelector('[data-order-commission-form-target="amountInput"]').value = amount
    this.updateTotals()
  }

  updatePercentage(event) {
    const line = event.target.closest('[data-order-commission-form-target="line"]')
    const amount = parseFloat(event.target.value) || 0
    const totalAmount = this.totalValue / 100 // Convert cents to currency
    const percentage = ((amount / totalAmount) * 100).toFixed(2)
    
    line.querySelector('[data-order-commission-form-target="percentageInput"]').value = percentage
    this.updateTotals()
  }

  updateTotals() {
    const totalAssigned = this.calculateTotalAssigned()
    const totalAmount = this.totalValue / 100
    const remaining = totalAmount - totalAssigned

    this.assignedTotalTarget.textContent = `S/ ${totalAssigned.toFixed(2)}`
    this.remainingTotalTarget.textContent = `S/ ${remaining.toFixed(2)}`
    
    // Disable submit if total assigned exceeds order total
    this.submitButtonTarget.disabled = totalAssigned > totalAmount
    if (totalAssigned > totalAmount) {
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    } else {
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    }
  }

  calculateTotalAssigned() {
    return Array.from(this.amountInputTargets)
      .reduce((sum, input) => {
        const line = input.closest('[data-order-commission-form-target="line"]')
        if (line) {
          return sum + (parseFloat(input.value) || 0)
        }
        return sum
      }, 0)
  }

  addCommission(event) {
    event.preventDefault()
    const newLine = this.lineTargets[0].cloneNode(true)
    
    newLine.querySelectorAll(".ts-wrapper").forEach(wrapper => wrapper.remove())
    newLine.querySelectorAll("input, select").forEach(input => {
      input.value = ""
      input.classList.remove("tomselected", "ts-hidden-accessible")
      input.removeAttribute("id")
      input.style.display = ''
    })

    this.linesTarget.appendChild(newLine)
    this.updateTotals()
  }

  removeCommission(event) {
    event.preventDefault()
    if (this.lineTargets.length > 1) {
      const line = event.target.closest('[data-order-commission-form-target="line"]')
      line.remove()
      this.updateTotals()
    }
  }

  submitForm(event) {
    event.preventDefault()
    if (this.calculateTotalAssigned() <= this.totalValue / 100) {
      this.cleanupDeletedRows()
      this.updateIndices()
      event.target.submit()
    }
  }

  cleanupDeletedRows() {
    this.lineTargets.forEach(line => {
      const destroyInput = line.querySelector('input[name*="_destroy"]')
      if (destroyInput && destroyInput.value === "1") {
        line.remove()
      }
    })
  }

  updateIndices() {
    const allLines = this.linesTarget.querySelectorAll('.nested-fields')
    allLines.forEach((line, index) => {
      line.querySelectorAll('input[name], select[name]').forEach(input => {
        const name = input.getAttribute('name')
        if (name) {
          const newName = name.replace(/\[\d+\]/, `[${index}]`)
          input.setAttribute('name', newName)
        }
      })
    })
  }
}