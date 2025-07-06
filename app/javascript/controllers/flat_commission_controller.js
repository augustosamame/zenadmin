import { Controller } from "@hotwired/stimulus"

// Manages the flat commission fields in the product form
export default class extends Controller {
  static targets = ["checkbox", "percentageField"]

  connect() {
    // Initialize the state of the percentage field when the controller connects
    this.togglePercentageField()
  }

  togglePercentageField() {
    if (this.hasCheckboxTarget && this.hasPercentageFieldTarget) {
      const isChecked = this.checkboxTarget.checked
      
      // Enable/disable the percentage field based on checkbox state
      this.percentageFieldTarget.disabled = !isChecked
      
      // Clear the percentage field if checkbox is unchecked
      if (!isChecked) {
        this.percentageFieldTarget.value = ""
      }
    }
  }
}
