// app/javascript/controllers/stock_transfer_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form",
    "lines",
    "warehouseDestination",
    "customerDestination",
    "warehouseOrigin",
    "vendorOrigin",
    "selectedCustomerName",
    "customerUserId",
    "vendorId",
    "guiaFields"
  ]

  connect() {
    console.log("Stock transfer form controller connected")
    // Initialize guia fields visibility on page load
    if (this.hasGuiaFieldsTarget) {
      const createGuiaCheckbox = document.querySelector('input[name="stock_transfer[create_guia]"]')
      if (createGuiaCheckbox && createGuiaCheckbox.checked) {
        this.guiaFieldsTarget.classList.remove('hidden')
      }
    }

    // Listen for customer selection events
    this.element.addEventListener('customer-selected', this.handleCustomerSelected.bind(this))
    
    // Initialize TomSelect for vendor dropdown if it exists
    this.initializeVendorSelect()
  }

  initializeVendorSelect() {
    // The vendor dropdown already has the select controller applied via data attributes
    // so we don't need to do anything here, as the select controller will initialize TomSelect
    console.log("Vendor select should be initialized by the select controller")
  }

  toggleGuiaFields(event) {
    if (this.hasGuiaFieldsTarget) {
      if (event.target.checked) {
        this.guiaFieldsTarget.classList.remove('hidden')
      } else {
        this.guiaFieldsTarget.classList.add('hidden')
      }
    }
  }

  toggleDestinationType(event) {
    const isCustomerTransfer = event.target.checked
    
    if (isCustomerTransfer) {
      this.warehouseDestinationTarget.classList.add("hidden")
      this.customerDestinationTarget.classList.remove("hidden")
    } else {
      this.warehouseDestinationTarget.classList.remove("hidden")
      this.customerDestinationTarget.classList.add("hidden")
    }
  }

  toggleOriginType(event) {
    const isVendorTransfer = event.target.checked
    
    if (isVendorTransfer) {
      this.warehouseOriginTarget.classList.add("hidden")
      this.vendorOriginTarget.classList.remove("hidden")
      
      // Clear the origin warehouse selection when switching to vendor
      const originWarehouseSelect = this.warehouseOriginTarget.querySelector('select')
      if (originWarehouseSelect) {
        originWarehouseSelect.value = ""
      }
    } else {
      this.warehouseOriginTarget.classList.remove("hidden")
      this.vendorOriginTarget.classList.add("hidden")
      
      // Clear the vendor selection when switching to warehouse
      if (this.hasVendorIdTarget) {
        // If it's a TomSelect, we need to clear it differently
        const vendorSelect = this.vendorIdTarget
        if (vendorSelect.tomSelect) {
          vendorSelect.tomSelect.clear()
        } else {
          vendorSelect.value = ""
        }
      }
    }
  }

  handleCustomerSelected(event) {
    console.log('Customer selected event received', event.detail)
    if (this.hasCustomerUserIdTarget && event.detail.userId) {
      this.customerUserIdTarget.value = event.detail.userId
    }
  }

  toggleAdjustmentType(event) {
    console.log("Toggling adjustment type field...");
    event.preventDefault();
    const adjustmentTypeField = document.getElementById("adjustment-type-field");
    adjustmentTypeField.classList.toggle("hidden");
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

    const lines = this.linesTarget.querySelectorAll('.nested-fields')
    if (lines.length > 1) {

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
    } else {
      console.log("No se puede eliminar el único producto de la transferencia.")
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