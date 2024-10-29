import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "tagSelect", "selectedProducts", "submitButton", "selectedCount"]

  connect() {
    this.updateSelectedCount(0)
    this.selectedIds = new Set()
  }

  toggleAll(event) {
    const checkboxes = document.querySelectorAll('.select-item')
    checkboxes.forEach(checkbox => {
      checkbox.checked = event.target.checked
      if (event.target.checked) {
        this.selectedIds.add(checkbox.value)
      } else {
        this.selectedIds.delete(checkbox.value)
      }
    })
    this.updateForm()
  }

  toggleOne(event) {
    if (event.target.checked) {
      this.selectedIds.add(event.target.value)
    } else {
      this.selectedIds.delete(event.target.value)
    }
    this.updateForm()
  }

  updateForm() {
    this.selectedProductsTarget.value = Array.from(this.selectedIds).join(',')
    this.updateSelectedCount(this.selectedIds.size)
    this.toggleSubmitButton(this.selectedIds.size > 0)
  }

  updateSelectedCount(count) {
    this.selectedCountTarget.textContent = count
  }

  toggleSubmitButton(enable) {
    this.submitButtonTarget.disabled = !enable
  }

  handleSubmit(event) {
    event.preventDefault()

    if (!this.selectedProductsTarget.value || !this.tagSelectTarget.value) {
      alert('Por favor selecciona productos y etiquetas')
      return
    }

    // Check if any tags are selected
    const selectedTags = Array.from(this.tagSelectTarget.selectedOptions)
    if (selectedTags.length === 0) {
      alert('Por favor selecciona al menos una etiqueta')
      return
    }

    this.formTarget.submit()
  }
}