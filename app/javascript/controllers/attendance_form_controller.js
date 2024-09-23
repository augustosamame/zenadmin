import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkoutField", "checkinField"]

  connect() {
    // Set initial value from the server if it exists
    const initialValue = this.checkinFieldTarget.dataset.initialValue
    if (initialValue) {
      this.checkinFieldTarget.value = initialValue
    }

    // Check if we're on the edit page
    const isEditPage = this.element.closest('[data-attendance-form-edit]')
    
    if (!isEditPage) {
      // Only check attendance status if both location and user are selected
      const locationId = this.element.querySelector('#user_attendance_log_location_id').value
      const userId = this.element.querySelector('#user_attendance_log_user_id').value
      if (locationId && userId) {
        this.checkAttendanceStatus()
      }
    }
  }

  checkAttendanceStatus() {
    const locationId = this.element.querySelector('#user_attendance_log_location_id').value
    const userId = this.element.querySelector('#user_attendance_log_user_id').value

    if (locationId && userId) {
      fetch(`/admin/user_attendance_logs/check_attendance_status?location_id=${locationId}&user_id=${userId}`)
        .then(response => response.json())
        .then(data => {
          if (data.has_open_attendance) {
            this.checkoutFieldTarget.classList.remove('hidden')
            this.checkinFieldTarget.value = data.checkin_time
            this.checkinFieldTarget.readOnly = true
          } else {
            this.checkoutFieldTarget.classList.add('hidden')
            // Don't reset the check-in field if there's no open attendance
            this.checkinFieldTarget.readOnly = false
          }
        })
    } else {
      this.checkoutFieldTarget.classList.add('hidden')
      // Don't reset the check-in field if location or user is not selected
      this.checkinFieldTarget.readOnly = false
    }
  }
}