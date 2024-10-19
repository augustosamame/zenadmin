// app/javascript/controllers/stock_transfer_receive_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "input", "submitButton"]

  connect() {
    this.checkCompleteness()
  }

  matchQuantity(event) {
    const row = event.target.closest("[data-stock-transfer-receive-target='row']")
    const input = row.querySelector("[data-stock-transfer-receive-target='input']")
    const transferredQuantity = parseInt(row.children[1].textContent)
    input.value = transferredQuantity
    this.checkCompleteness()
  }

  checkCompleteness() {
    const allFilled = this.inputTargets.every(input => input.value !== "")
    this.submitButtonTarget.disabled = !allFilled
  }

  submitForm(event) {
    if (!this.inputTargets.every(input => input.value !== "")) {
      event.preventDefault()
      alert("Please fill in all received quantities before submitting.")
    }
  }
}