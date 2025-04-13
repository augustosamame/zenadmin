import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "cashierSelect", "cashierError"]

  connect() {
    console.log("Purchase Payment Form controller connected")
    
    // Add submit event listener to the form
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', this.validateForm.bind(this))
    }
  }
  
  validateForm(event) {
    // Reset any previous error messages
    if (this.hasCashierErrorTarget) {
      this.cashierErrorTarget.classList.add('hidden')
    }
    
    // Check if cashier is selected
    if (this.hasCashierSelectTarget) {
      const cashierSelect = this.cashierSelectTarget
      if (!cashierSelect.value) {
        event.preventDefault()
        
        // Show error message
        if (this.hasCashierErrorTarget) {
          this.cashierErrorTarget.classList.remove('hidden')
        }
        
        // Highlight the select field
        cashierSelect.classList.add('border-red-500')
        cashierSelect.focus()
        
        return false
      } else {
        // Remove any error styling
        cashierSelect.classList.remove('border-red-500')
      }
    }
    
    return true
  }
}
