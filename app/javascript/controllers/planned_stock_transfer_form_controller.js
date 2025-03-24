import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["linesContainer", "lineTemplate"]

  connect() {
    // If there are no lines, add one by default
    if (this.linesContainerTarget.querySelectorAll('.line-item').length === 0) {
      this.addLine()
    }
  }

  addLine(event) {
    // Get the template content
    const template = this.lineTemplateTarget.innerHTML
    
    // Generate a unique index for the new line
    const timestamp = new Date().getTime()
    const newTemplate = template.replace(/NEW_RECORD/g, timestamp)
    
    // Insert the new line before the "Add Product" button
    this.linesContainerTarget.insertAdjacentHTML('beforeend', newTemplate)
  }

  removeLine(event) {
    const lineItem = event.target.closest('.line-item')
    
    // If there's a destroy field, mark it for destruction instead of removing from DOM
    const destroyField = lineItem.querySelector('.destroy-field')
    if (destroyField && destroyField.name.includes('[id]')) {
      destroyField.value = '1'
      lineItem.style.display = 'none'
    } else {
      // Otherwise, just remove the line from the DOM
      lineItem.remove()
    }
    
    // Ensure there's always at least one line
    if (this.linesContainerTarget.querySelectorAll('.line-item:not([style*="display: none"])').length === 0) {
      this.addLine()
    }
  }
}
