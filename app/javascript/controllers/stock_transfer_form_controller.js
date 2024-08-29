// app/javascript/controllers/stock_transfer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "lines", "form"]

  connect() {
    console.log("Stock transfer controller connected")
  }

  addProduct(event) {
    event.preventDefault()

    // Clone a template for a new line
    const newLine = this.lineTarget.cloneNode(true)

    // Clean up Tom Select-specific elements and attributes in the cloned template
    newLine.querySelectorAll(".ts-wrapper").forEach(wrapper => wrapper.remove());  // Remove Tom Select wrappers
    newLine.querySelectorAll("input, select").forEach(input => {
      input.value = ""
      input.classList.remove("tomselected", "ts-hidden-accessible")
      input.removeAttribute("id")
      input.style.display = ''; // Ensure the original select is visible
    })

    // Append new line to the container using the target reference
    this.linesTarget.appendChild(newLine)

    // Initialize Tom Select only for the new row's select element
    // this.initializeTomSelect(newLine.querySelector('select[data-controller="select"]'))
  }

  removeProduct(event) {
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
    event.preventDefault(); // Prevent the default form submission

    console.log("Form submission intercepted, updating indices so that nested rows with tomselect dropdowns have correct indices...");

    // Update all indices before submitting the form
    this.updateIndices();

    // Now submit the form programmatically
    this.formTarget.submit();
  }

  updateIndices() {
    console.log("Updating indices...");
    const allLines = this.linesTarget.querySelectorAll('.nested-fields');

    allLines.forEach((line, index) => {
      // Find the select element and extract the integer index from its ID
      const select = line.querySelector('select[id^="tomselect-"]');
      if (select) {
        const match = select.id.match(/tomselect-(\d+)/);
        if (match) {
          const extractedIndex = parseInt(match[1], 10) - 1; // Extracted index from ID minus 1

          // Update the name attributes for all inputs/selects in this line
          line.querySelectorAll('input[name], select[name]').forEach(input => {
            let name = input.getAttribute('name');
            if (name) {
              const newName = name.replace(/\[\d*\]/, `[${extractedIndex}]`); // Replace with extracted index
              input.setAttribute('name', newName);
              console.log(`Updated name: ${newName}`);
            }
          });
        }
      }
    });
  }

}