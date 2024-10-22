// app/javascript/controllers/report_date_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["date", "reportDate"]

  connect() {
    this.updateReportDates()
  }

  updateReportDates() {
    const selectedDate = this.dateTarget.value
    this.reportDateTargets.forEach(field => {
      field.value = selectedDate
    })
  }
}