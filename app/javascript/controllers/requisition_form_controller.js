import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "lines", "form", "template", "debugCommit", "plannedQuantity?", "manualQuantity?"]

  connect() {
    console.log("Requisition form controller connected")
    this.initializeProductSelects()
  }

  logCommit(event) {
    console.log("Submit button clicked:", event.target.value)
    if (this.hasDebugCommitTarget) {
      this.debugCommitTarget.value = event.target.value
    }
  }

  initializeProductSelects() {
    this.element.querySelectorAll('select[data-controller="select"]').forEach(select => {
      select.addEventListener('change', (event) => this.updateStockInfo(event))
    })
  }

  updateStockInfo(event) {
    const select = event.target
    const productId = select.value
    const lineItem = select.closest('.nested-fields')
    const stockField = lineItem.querySelector('input[name*="[current_stock]"]')

    if (productId) {
      fetch(`/admin/products/${productId}/stock`)
        .then(response => response.json())
        .then(data => {
          stockField.value = data.stock
        })
        .catch(error => console.error('Error fetching stock:', error))
    } else {
      stockField.value = ''
    }
  }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    const newLine = document.createRange().createContextualFragment(content).firstElementChild

    newLine.querySelectorAll(".ts-wrapper").forEach(wrapper => wrapper.remove())
    newLine.querySelectorAll("input, select").forEach(input => {
      input.value = ""
      input.classList.remove("tomselected", "ts-hidden-accessible")
      input.removeAttribute("id")
      input.style.display = ''
    })

    this.linesTarget.appendChild(newLine)

    // Initialize event listeners for the new line
    const newSelect = newLine.querySelector('select[data-controller="select"]')
    if (newSelect) {
      newSelect.addEventListener('change', (event) => this.updateStockInfo(event))
    }
  }

  remove(event) {
    event.preventDefault()

    // Find the closest line item to remove
    const line = event.target.closest(".nested-fields")

    // Mark the hidden field for _destroy if it exists or remove the element directly
    const destroyInput = line.querySelector('input[name*="_destroy"]')
    if (destroyInput) {
      destroyInput.value = 1
      line.style.display = "none"
    } else {
      line.remove()
    }
  }

  submitForm(event) {
    event.preventDefault()
    console.log("Form submission intercepted")

    // Get the submit button that was clicked
    const submitButton = event.submitter
    console.log("Submit button clicked:", submitButton?.value)

    // Update indices before submitting
    this.updateIndices()

    // Create or update the commit input
    let commitInput = this.formTarget.querySelector('input[name="commit"]')
    if (!commitInput) {
      commitInput = document.createElement('input')
      commitInput.type = 'hidden'
      commitInput.name = 'commit'
      this.formTarget.appendChild(commitInput)
    }

    // Set the commit value from the button that was clicked
    commitInput.value = submitButton?.value || ''
    console.log("Setting commit value to:", commitInput.value)

    // Now submit the form
    this.formTarget.submit()
  }

  updateIndices() {
    console.log("Updating indices...")
    const allLines = this.linesTarget.querySelectorAll('.nested-fields')

    allLines.forEach((line, index) => {
      line.querySelectorAll('input[name], select[name]').forEach(input => {
        let name = input.getAttribute('name')
        if (name) {
          const newName = name.replace(/\[requisition_lines_attributes\]\[\d*\]/, `[requisition_lines_attributes][${index}]`)
          input.setAttribute('name', newName)
          console.log(`Updated name: ${newName}`)
        }
      })
    })
  }

  copyManualQuantity(event) {
    event.preventDefault()
    const line = event.target.closest('.nested-fields')
    if (!line) return

    const manualQuantityInput = line.querySelector('input[name*="[manual_quantity]"]')
    const plannedQuantityInput = line.querySelector('input[name*="[planned_quantity]"]')

    if (manualQuantityInput && plannedQuantityInput) {
      plannedQuantityInput.value = manualQuantityInput.value
      plannedQuantityInput.classList.add('bg-green-50')
      setTimeout(() => {
        plannedQuantityInput.classList.remove('bg-green-50')
      }, 500)
    }
  }

  copyAutomaticQuantity(event) {
    event.preventDefault()
    const line = event.target.closest('.nested-fields')
    if (!line) return

    const automaticQuantityInput = line.querySelector('input[name*="[automatic_quantity]"]')
    const manualQuantityInput = line.querySelector('input[name*="[manual_quantity]"]')

    if (automaticQuantityInput && manualQuantityInput) {
      manualQuantityInput.value = automaticQuantityInput.value
      manualQuantityInput.classList.add('bg-green-50')
      setTimeout(() => {
        manualQuantityInput.classList.remove('bg-green-50')
      }, 500)
    }
  }
}