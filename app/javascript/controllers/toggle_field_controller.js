import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // Check initial state of checkbox
    const checkbox = this.element.querySelector('input[type="checkbox"]')
    if (checkbox && checkbox.checked) {
      this.contentTarget.classList.remove("hidden")
    }
  }

  toggle(event) {
    if (event.target.checked) {
      this.contentTarget.classList.remove("hidden")
    } else {
      this.contentTarget.classList.add("hidden")
      // Clear the input field when hiding
      const inputField = this.contentTarget.querySelector('input[type="text"]')
      if (inputField) {
        inputField.value = ""
      }
    }
  }
}
