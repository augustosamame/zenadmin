import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkoutField", "checkinField"]
  static values = { adminOrSupervisor: Boolean }

  connect() {
    // Set initial value from the server if it exists
    const initialValue = this.checkinFieldTarget.dataset.initialValue
    if (initialValue) {
      this.checkinFieldTarget.value = initialValue
    }

    this.faceRecognized = false;
    this.element.addEventListener('faceRecognized', this.onFaceRecognized.bind(this));
    this.element.addEventListener('faceNotRecognized', this.onFaceNotRecognized.bind(this));
    this.element.addEventListener('faceRecognitionError', this.onFaceRecognitionError.bind(this));

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

  onFaceRecognized() {
    console.log("Face recognized");
    this.faceRecognized = true;
  }

  onFaceNotRecognized() {
    console.log("Face not recognized");
    this.faceRecognized = false;
  }

  onFaceRecognitionError() {
    console.log("Face recognition error");
    this.faceRecognized = false;
  }

  submitForm(event) {
    console.log("Admin or supervisor value:", this.adminOrSupervisorValue);
    if (!this.faceRecognized && !this.adminOrSupervisorValue) {
      event.preventDefault();
      alert("Por favor, capture y verifique su rostro antes de hacer check-in.");
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

  submitWithFaceComparison(event) {
    event.preventDefault();
    const form = this.element;
    const formData = new FormData(form);

    fetch('/admin/user_attendance_logs/compare_face', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(response => response.json())
      .then(data => {
        if (data.match) {
          form.submit();
        } else {
          alert("La cara no coincide. Por favor, intente de nuevo.");
        }
      })
      .catch(error => {
        console.error('Error:', error);
        alert("Ocurrió un error durante la comparación facial. Por favor, intente de nuevo.");
    });
  }
}
