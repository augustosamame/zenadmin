import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.initializeDatetimePicker()
  }

  initializeDatetimePicker() {
    this.inputTargets.forEach(input => {
      // Set max date to current date and time
      const now = new Date()
      input.setAttribute('max', this.formatDateTime(now))
      
      // Add event listener to enforce max date
      input.addEventListener('change', (e) => {
        const selectedDate = new Date(e.target.value)
        if (selectedDate > now) {
          e.target.value = this.formatDateTime(now)
        }
      })
    })
  }

  formatDateTime(date) {
    return date.toISOString().slice(0, 16) // Format: YYYY-MM-DDTHH:mm
  }
}
