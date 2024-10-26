import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "items", "form"]

  connect() {
    console.log("Product Pack Form controller connected")
  }

  addItem(event) {
    event.preventDefault()

    // Clone a template for a new line
    const newItem = this.itemTarget.cloneNode(true)

    // Clean up Tom Select-specific elements and attributes in the cloned template
    newItem.querySelectorAll(".ts-wrapper").forEach(wrapper => wrapper.remove());  // Remove Tom Select wrappers
    newItem.querySelectorAll("input, select").forEach(input => {
      if (input.name.includes('[quantity]')) {
        input.value = "1"  // Set default quantity to 1
      } else {
        input.value = ""
      }
      input.classList.remove("tomselected", "ts-hidden-accessible")
      input.removeAttribute("id")
      input.style.display = ''; // Ensure the original select is visible
    })

    // Append new item to the container using the target reference
    this.itemsTarget.appendChild(newItem)

    // The Tom Select will be reinitialized automatically by the select controller
  }

  removeItem(event) {
    event.preventDefault()

    const items = this.itemsTarget.querySelectorAll('.nested-fields')
    if (items.length > 1) {
      // Find the closest item to remove
      const item = event.target.closest(".nested-fields")

      // Mark the hidden field for _destroy if it exists or remove the element directly
      const destroyInput = item.querySelector('input[name*="_destroy"]')
      if (destroyInput) {
        destroyInput.value = 1
        item.style.display = "none"
      } else {
        item.remove()
      }
    } else {
      console.log("You must have at least one item in the pack.")
    }
  }

  submitForm(event) {
    event.preventDefault(); // Prevent the default form submission

    console.log("Form submission intercepted, updating indices...");

    // Update all indices before submitting the form
    this.updateIndices();

    // Now submit the form programmatically
    this.formTarget.submit();
  }

  updateIndices() {
    console.log("Updating indices...");
    const allItems = this.itemsTarget.querySelectorAll('.nested-fields');

    allItems.forEach((item, index) => {
      // Find the select element and extract the integer index from its ID
      const select = item.querySelector('select[id^="tomselect-"]');
      if (select) {
        const match = select.id.match(/tomselect-(\d+)/);
        if (match) {
          const extractedIndex = parseInt(match[1], 10) - 1; // Extracted index from ID minus 1

          // Update the name attributes for all inputs/selects in this item
          item.querySelectorAll('input[name], select[name]').forEach(input => {
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