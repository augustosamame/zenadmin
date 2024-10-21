import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "lines", "form", "template"]

  connect() {
    console.log("Requisition form controller connected")
  }

  add(event) {
    event.preventDefault()

    // Use the template to create a new line
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    const newLine = document.createRange().createContextualFragment(content).firstElementChild

    // Clean up Tom Select-specific elements and attributes in the new line
    newLine.querySelectorAll(".ts-wrapper").forEach(wrapper => wrapper.remove())
    newLine.querySelectorAll("input, select").forEach(input => {
      input.value = ""
      input.classList.remove("tomselected", "ts-hidden-accessible")
      input.removeAttribute("id")
      input.style.display = '' // Ensure the original select is visible
    })

    // Append new line to the container
    this.linesTarget.appendChild(newLine)

    // Initialize Tom Select for the new row's select element if needed
    // this.initializeTomSelect(newLine.querySelector('select[data-controller="select"]'))
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

    console.log("Form submission intercepted, updating indices...")

    // Update all indices before submitting the form
    this.updateIndices()

    // Now submit the form programmatically
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
}