import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["datePicker", "hiddenDate"]

  connect() {
    console.log("Report date controller connected")

    // Try to get date from session storage first
    const savedDate = sessionStorage.getItem('selectedReportDate')
    if (savedDate) {
      console.log("Found saved date:", savedDate)
      this.datePickerTarget.value = savedDate
    }

    // Initialize all hidden date fields
    this.updateHiddenDates()
    console.log("Initial date set to:", this.datePickerTarget.value)
  }

  dateChanged(event) {
    const newDate = event.target.value
    console.log("Date changed to:", newDate)

    // Save to session storage
    sessionStorage.setItem('selectedReportDate', newDate)
    console.log("Date saved to session storage")

    this.updateHiddenDates()
  }

  updateHiddenDates() {
    const selectedDate = this.datePickerTarget.value
    console.log("Updating hidden dates to:", selectedDate)

    this.hiddenDateTargets.forEach((hiddenField, index) => {
      const oldValue = hiddenField.value
      hiddenField.value = selectedDate
      console.log(`Hidden field ${index} updated from ${oldValue} to ${selectedDate}`)
    })
  }
}