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
    console.log('Add button clicked!')
    event.preventDefault()
    
    if (!this.hasTemplateTarget || !this.hasLinesTarget) {
      console.error('Template or lines target not found')
      return
    }
    
    try {
      // Generate a unique timestamp for the new record
      const timestamp = new Date().getTime()
      
      // Get the template content and replace NEW_RECORD with the timestamp
      const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, timestamp)
      
      // Insert the new line HTML directly into the lines container
      this.linesTarget.insertAdjacentHTML('beforeend', content)
      
      // Get the newly added line (it will be the last child)
      const newLine = this.linesTarget.lastElementChild
      
      console.log('New line added:', newLine)
      
      // Initialize select elements in the new line
      const selects = newLine.querySelectorAll('select[data-controller="select"]')
      if (selects.length > 0) {
        selects.forEach(select => {
          // Initialize the select with TomSelect
          if (this.application) {
            this.application.getControllerForElementAndIdentifier(select, 'select')
          }
          
          // Add event listener for stock updates
          select.addEventListener('change', (e) => this.updateStockInfo(e))
        })
      }
      
      // Set default values for quantity fields
      const quantityInputs = newLine.querySelectorAll('input[name*="quantity"]')
      quantityInputs.forEach(input => {
        input.value = "0"
      })
      
    } catch (error) {
      console.error('Error adding new line:', error)
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