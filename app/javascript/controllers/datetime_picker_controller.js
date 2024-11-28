import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.initializeDatetimePickers()
  }

  initializeDatetimePickers() {
    this.inputTargets.forEach(input => {
      // Set min date to 30 days ago and max date to 30 days in future
      const thirtyDaysAgo = new Date()
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
      const thirtyDaysFromNow = new Date()
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30)

      input.setAttribute('min', this.formatDateTime(thirtyDaysAgo))
      input.setAttribute('max', this.formatDateTime(thirtyDaysFromNow))

      // Add event listener to enforce date range
      input.addEventListener('change', (e) => {
        const selectedDate = new Date(e.target.value)
        if (selectedDate < thirtyDaysAgo) {
          e.target.value = this.formatDateTime(thirtyDaysAgo)
        } else if (selectedDate > thirtyDaysFromNow) {
          e.target.value = this.formatDateTime(thirtyDaysFromNow)
        }
      })
    })
  }

  formatDateTime(date) {
    return date.toISOString().slice(0, 16) // Format: YYYY-MM-DDTHH:mm
  }

  // Helper method to format date for display
  formatDateForDisplay(date) {
    return date.toLocaleString('es-PE', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    })
  }
}
