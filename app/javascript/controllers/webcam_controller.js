import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video", "canvas", "captureButton", "photoInput", "message", "submitButton", "userIdInput"];
  static values = { adminOrSupervisor: Boolean }

  connect() {
    try {
      console.log("Webcam controller connected");
      this.requestCameraAccess();
      if (this.adminOrSupervisorValue) {
        this.enableSubmitButton();
      } else {
        this.disableSubmitButton();
      }
    } catch (error) {
      console.error("Error in connect method:", error);
    }
    this.attempts = 0; // Initialize attempts count
  }

  enableSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false;
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed');
    }
  }

  disableSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true;
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed');
    }
  }

  requestCameraAccess() {
    console.log("Requesting camera access");
    navigator.mediaDevices.getUserMedia({ video: true })
      .then(stream => {
        console.log("Camera access granted");
        this.videoTarget.srcObject = stream;
        this.showMessage("Cámara activada. Capture su foto.");
      })
      .catch(err => {
        console.error("Error accessing webcam:", err);
        if (err.name === 'NotAllowedError') {
          this.showMessage("Permiso denegado. Por favor, active la cámara y vuelva a intentarlo.");
        } else {
          this.showMessage("Error al acceder a la cámara. Por favor, asegúrese de que su cámara esté conectada y vuelva a intentarlo.");
        }
      });
  }

  capture() {
    // Draw video frame to canvas
    const context = this.canvasTarget.getContext('2d');
    this.canvasTarget.width = this.videoTarget.videoWidth;
    this.canvasTarget.height = this.videoTarget.videoHeight;
    context.drawImage(this.videoTarget, 0, 0, this.canvasTarget.width, this.canvasTarget.height);

    // Convert the canvas image to base64
    const imageData = this.canvasTarget.toDataURL('image/jpeg');
    this.photoInputTarget.value = imageData;

    if (this.hasUserIdInputTarget) {
      this.compareFace(imageData);
    } else {
      this.showMessage("Foto capturada correctamente.");
      this.enableSubmitButton();
    }

  }

  compareFace(imageData) {
    this.showMessage("Comparando rostro...");
    const userId = this.userIdInputTarget.value;

    if (!userId) {
      this.showMessage("Error: No se ha seleccionado un usuario.");
      return;
    }

    fetch('/admin/user_attendance_logs/compare_face', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        user_attendance_log: {
          user_id: userId,
          captured_photo: imageData
        }
      })
    })
      .then(response => response.json())
      .then(data => {
        if (data.match) {
          this.showMessage("Rostro reconocido. Puede realizar el check-in.");
          this.enableSubmitButton();
          this.element.dispatchEvent(new CustomEvent('faceRecognized', { bubbles: true }));
        } else {
          const errorMessage = data.error || "Rostro no reconocido. Por favor, intente de nuevo.";
          this.showMessage(errorMessage);
          if (this.adminOrSupervisorValue) {
            this.disableSubmitButton();
          }
          this.element.dispatchEvent(new CustomEvent('faceNotRecognized', { bubbles: true, detail: { error: errorMessage } }));
        }
      })
      .catch(error => {
        console.error('Error:', error);
        this.showMessage("Error en la comparación facial. Por favor, intente de nuevo.");
        if (this.adminOrSupervisorValue) {
          this.disableSubmitButton();
        }
        this.element.dispatchEvent(new CustomEvent('faceRecognitionError', { bubbles: true }));
      });
  }

  sendForRecognition(imageData) {
    fetch('/admin/face_recognition', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ image: imageData })
    })
      .then(response => response.json())
      .then(data => {
        if (data.match) {
          this.showMessage("Face recognized. Check-in successful!");
        } else {
          this.retryOrFail();
        }
      })
      .catch(error => {
        console.error('Error:', error);
        this.retryOrFail();
      });
  }

  retryOrFail() {
    this.attempts++;

    if (this.attempts < 3) {
      // Retry after a small delay (e.g., 1 second)
      setTimeout(() => {
        this.showMessage(`Retrying (${this.attempts}/3)...`);
        this.capture(); // Retry face capture and recognition
      }, 1000);
    } else {
      this.showMessage("Face not recognized after 3 tries. Please try again.");
    }
  }

  showMessage(message) {
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = message;
    } else {
      console.warn("Message target not found");
    }
  }
}