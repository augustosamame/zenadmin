import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lines", "template", "form", "invoices", "invoiceTemplate", "invoiceCustomId", "customIdError"]

  connect() {
    console.log("Purchase Form controller connected")
    
    // Initialize transportista select
    const transportistaSelect = this.element.querySelector('select[name*="transportista_id"]')
    if (transportistaSelect) {
      transportistaSelect.addEventListener('change', this.updateTransportistaInfo.bind(this))
    }

    // Store a flag to indicate if we're working with a purchase order
    this.isPurchaseOrderBased = false
    
    // Add event listener for product selection
    this.element.addEventListener('change', this.handleProductSelection.bind(this))
  }

  handlePurchaseOrderSelection(event) {
    console.log("Purchase order selected:", event.target.value)
    const purchaseOrderId = event.target.value
    if (!purchaseOrderId) {
      console.log("No purchase order selected, clearing form")
      // Clear form if no purchase order is selected
      this.clearForm()
      this.isPurchaseOrderBased = false
      return
    }
    
    // Set flag to indicate we're working with a purchase order
    this.isPurchaseOrderBased = true
    
    console.log("Fetching purchase order details for ID:", purchaseOrderId)
    // Fetch purchase order details
    fetch(`/admin/purchases/get_purchase_order_details?purchase_order_id=${purchaseOrderId}`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        console.log("Purchase order details received:", data)
        this.prefillForm(data)
      })
      .catch(error => {
        console.error('Error fetching purchase order data:', error)
        alert('Error al cargar los datos de la orden de compra. Por favor, inténtelo de nuevo.')
      })
  }
  
  prefillForm(data) {
    if (!this.hasFormTarget) {
      console.error('Form target not found')
      return
    }
    
    console.log("Prefilling form with data:", data)
    
    // Set purchase_order_id in the hidden field
    const purchaseOrderIdField = this.formTarget.querySelector('input[name*="purchase_order_id"]')
    if (purchaseOrderIdField) {
      console.log("Setting purchase order ID in hidden field")
      purchaseOrderIdField.value = data.purchase_order_id || this.element.querySelector('#purchase_order_select').value
    } else {
      console.warn("Purchase order ID field not found")
    }
    
    // Set vendor
    const vendorSelect = this.formTarget.querySelector('select[name*="vendor_id"]')
    if (vendorSelect) {
      console.log("Setting vendor ID:", data.vendor_id)
      if (vendorSelect.tomselect) {
        vendorSelect.tomselect.setValue(data.vendor_id)
      } else {
        vendorSelect.value = data.vendor_id
      }
    } else {
      console.warn("Vendor select not found")
    }
    
    // Set transportista
    const transportistaSelect = this.formTarget.querySelector('select[name*="transportista_id"]')
    if (transportistaSelect) {
      console.log("Setting transportista ID:", data.transportista_id)
      if (transportistaSelect.tomselect) {
        transportistaSelect.tomselect.setValue(data.transportista_id)
      } else {
        transportistaSelect.value = data.transportista_id
      }
      // Trigger change event to update transportista info
      transportistaSelect.dispatchEvent(new Event('change'))
    } else {
      console.warn("Transportista select not found")
    }
    
    // Set notes
    const notesField = this.formTarget.querySelector('textarea[name*="notes"]')
    if (notesField) {
      console.log("Setting notes:", data.notes)
      notesField.value = data.notes || ''
    } else {
      console.warn("Notes field not found")
    }
    
    // Clear existing lines
    this.clearLines()
    
    // Add lines from purchase order
    if (data.lines && data.lines.length > 0) {
      console.log("Adding lines:", data.lines.length)
      data.lines.forEach(line => {
        this.addLineWithData(line)
      })
      
      // Update the first invoice amount after adding all lines
      this.updateFirstInvoiceAmount()
    } else {
      console.log("No lines to add, adding empty line")
      // If no lines were added, add an empty one
      this.addLine(new Event('click'))
    }
  }
  
  clearForm() {
    if (!this.hasFormTarget) {
      console.error('Form target not found')
      return
    }
    
    console.log("Clearing form")
    
    // Reset vendor
    const vendorSelect = this.formTarget.querySelector('select[name*="vendor_id"]')
    if (vendorSelect) {
      if (vendorSelect.tomselect) {
        vendorSelect.tomselect.clear()
      } else {
        vendorSelect.value = ''
      }
    }
    
    // Reset transportista
    const transportistaSelect = this.formTarget.querySelector('select[name*="transportista_id"]')
    if (transportistaSelect) {
      if (transportistaSelect.tomselect) {
        transportistaSelect.tomselect.clear()
      } else {
        transportistaSelect.value = ''
        transportistaSelect.dispatchEvent(new Event('change'))
      }
    }
    
    // Clear notes
    const notesField = this.formTarget.querySelector('textarea[name*="notes"]')
    if (notesField) {
      notesField.value = ''
    }
    
    // Clear existing lines and add an empty one
    this.clearLines()
    this.addLine(new Event('click'))
  }
  
  clearLines() {
    if (!this.hasLinesTarget) {
      console.error('Lines target not found')
      return
    }
    
    console.log("Clearing lines")
    
    // Remove all lines except the template
    const lines = this.linesTarget.querySelectorAll('.purchase-line')
    lines.forEach(line => {
      line.remove()
    })
  }

  updateTransportistaInfo(event) {
    const transportistaId = event.target.value
    if (!transportistaId) {
      document.getElementById('transportista-info').innerHTML = ''
      return
    }

    fetch(`/admin/transportistas/${transportistaId}.json`)
      .then(response => response.json())
      .then(data => {
        let infoHtml = '<div class="p-3 bg-gray-50 rounded border border-gray-200">'
        
        if (data.ruc_number) {
          // RUC type transportista
          infoHtml += `<p><strong>Razón Social:</strong> ${data.razon_social}</p>`
          infoHtml += `<p><strong>RUC:</strong> ${data.ruc_number}</p>`
        } else {
          // DNI type transportista
          infoHtml += `<p><strong>Nombre:</strong> ${data.first_name} ${data.last_name}</p>`
          infoHtml += `<p><strong>DNI:</strong> ${data.dni_number}</p>`
          infoHtml += `<p><strong>Licencia:</strong> ${data.license_number}</p>`
        }
        
        infoHtml += '</div>'
        document.getElementById('transportista-info').innerHTML = infoHtml
      })
      .catch(error => {
        console.error('Error fetching transportista data:', error)
        document.getElementById('transportista-info').innerHTML = '<p class="text-red-500">Error al cargar información del transportista</p>'
      })
  }

  handleProductSelection(event) {
    if (!event.target.matches('select[name*="product_id"]')) {
      return
    }
    
    const productId = event.target.value
    if (!productId) {
      return
    }
    
    const line = event.target.closest(".purchase-line")
    const quantityField = line.querySelector("input[name*='quantity']")
    const priceField = line.querySelector("input[name*='unit_price']")
    
    // Set quantity to 1 by default
    if (quantityField && (!quantityField.value || quantityField.value === '0')) {
      quantityField.value = 1
    }

    // If we're working with a purchase order, don't fetch product prices
    if (this.isPurchaseOrderBased) {
      console.log("Working with purchase order - skipping product price fetch")
      // If the price field is empty, we still need to update the line total
      if (priceField && !priceField.value) {
        priceField.value = 0
      }
      this.updateLineTotal({ target: priceField })
      return
    }

    // Only fetch product price if we're not working with a purchase order
    fetch(`/admin/purchases/get_product_details?product_id=${productId}`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        console.log("Product details received:", data)
        if (priceField) {
          priceField.value = data.price
          // Update the line total
          this.updateLineTotal({ target: priceField })
        }
      })
      .catch(error => {
        console.error('Error fetching product data:', error)
      })
  }

  add(event) {
    this.addLine(event)
  }

  addLine(event) {
    event.preventDefault()
    
    if (!this.hasTemplateTarget || !this.hasLinesTarget) {
      console.error('Template or lines target not found')
      return
    }
    
    // Get the template content
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    const newLine = document.createRange().createContextualFragment(content).firstElementChild
    
    // Add the new line to the form
    this.linesTarget.appendChild(newLine)
    
    // Initialize select for the new line
    const selects = newLine.querySelectorAll('[data-controller="select"]')
    selects.forEach(select => {
      const application = this.application
      application.getControllerForElementAndIdentifier(select, 'select')
    })
    
    // Update the line total for the new line
    const quantityInput = newLine.querySelector('input[name*="quantity"]')
    if (quantityInput) {
      this.updateLineTotal({ target: quantityInput })
    }
  }
  
  addLineWithData(lineData) {
    if (!this.hasTemplateTarget || !this.hasLinesTarget) {
      console.error('Template or lines target not found')
      return
    }
    
    // Get the template content
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    const newLine = document.createRange().createContextualFragment(content).firstElementChild
    
    // Add the new line to the form
    this.linesTarget.appendChild(newLine)
    
    // Initialize select for the new line
    const selects = newLine.querySelectorAll('[data-controller="select"]')
    selects.forEach(select => {
      const application = this.application
      application.getControllerForElementAndIdentifier(select, 'select')
    })
    
    // Set product after a small delay to ensure TomSelect is initialized
    setTimeout(() => {
      const productSelect = newLine.querySelector('select[name*="product_id"]')
      if (productSelect) {
        console.log("Setting product ID:", lineData.product_id)
        if (productSelect.tomselect) {
          productSelect.tomselect.setValue(lineData.product_id)
        } else {
          productSelect.value = lineData.product_id
        }
      }
      
      // Set warehouse if available
      const warehouseSelect = newLine.querySelector('select[name*="warehouse_id"]')
      if (warehouseSelect && lineData.warehouse_id) {
        console.log("Setting warehouse ID:", lineData.warehouse_id)
        if (warehouseSelect.tomselect) {
          warehouseSelect.tomselect.setValue(lineData.warehouse_id)
        } else {
          warehouseSelect.value = lineData.warehouse_id
        }
      }
      
      // Set quantity
      const quantityInput = newLine.querySelector('input[name*="quantity"]')
      if (quantityInput) {
        quantityInput.value = lineData.quantity
      }
      
      // Set unit price - use purchase_order_line_price if available, otherwise fallback to unit_price
      const priceInput = newLine.querySelector('input[name*="unit_price"]')
      if (priceInput) {
        // Prioritize the purchase order price if available
        if (lineData.purchase_order_line_price !== undefined) {
          console.log("Using purchase order line price:", lineData.purchase_order_line_price)
          priceInput.value = lineData.purchase_order_line_price
        } else if (lineData.unit_price !== undefined) {
          console.log("Using unit price from data:", lineData.unit_price)
          priceInput.value = lineData.unit_price
        }
      }
      
      // Update the line total
      if (quantityInput) {
        this.updateLineTotal({ target: quantityInput })
      }
    }, 200) // Increased timeout to ensure TomSelect is fully initialized
  }

  remove(event) {
    event.preventDefault()
    
    const line = event.target.closest(".purchase-line")
    
    // If there's a hidden _destroy field, set it to 1 (mark for destruction)
    const destroyField = line.querySelector("input[name*='_destroy']")
    if (destroyField) {
      destroyField.value = "1"
      line.style.display = "none"
    } else {
      // Otherwise just remove the line from the DOM
      line.remove()
    }
    
    // Update the first invoice amount after removing a line
    this.updateFirstInvoiceAmount()
  }

  removeLine(event) {
    this.remove(event)
  }

  updateLineTotal(event) {
    const line = event.target.closest(".purchase-line")
    const quantityField = line.querySelector("input[name*='quantity']")
    const priceField = line.querySelector("input[name*='unit_price']")
    const totalElement = line.querySelector(".line-total")
    
    if (quantityField && priceField && totalElement) {
      const quantity = parseFloat(quantityField.value) || 0
      const price = parseFloat(priceField.value) || 0
      const total = quantity * price
      
      // Format the total as currency
      totalElement.textContent = new Intl.NumberFormat('es-PE', { 
        style: 'currency', 
        currency: 'PEN' 
      }).format(total)
      
      // Update the first invoice amount to match the total of all lines
      this.updateFirstInvoiceAmount()
    }
  }

  updateFirstInvoiceAmount() {
    // Calculate the total of all product lines
    let total = 0
    const lines = this.element.querySelectorAll(".purchase-line")
    
    lines.forEach(line => {
      // Skip lines marked for destruction
      const destroyField = line.querySelector("input[name*='_destroy']")
      if (destroyField && destroyField.value === "1") {
        return
      }
      
      const quantityField = line.querySelector("input[name*='quantity']")
      const priceField = line.querySelector("input[name*='unit_price']")
      
      if (quantityField && priceField) {
        const quantity = parseFloat(quantityField.value) || 0
        const price = parseFloat(priceField.value) || 0
        total += quantity * price
      }
    })
    
    // Update the amount field of the first invoice
    if (this.hasInvoicesTarget) {
      const firstInvoice = this.invoicesTarget.querySelector(".purchase-invoice-fields")
      if (firstInvoice) {
        // Skip if the invoice is marked for destruction
        const destroyField = firstInvoice.querySelector("input.destroy-flag")
        if (destroyField && destroyField.value === "1") {
          return
        }
        
        const amountField = firstInvoice.querySelector("input[name*='amount']")
        if (amountField) {
          amountField.value = total.toFixed(2)
        }
      }
    }
  }

  addInvoice(event) {
    event.preventDefault()
    
    if (!this.hasInvoiceTemplateTarget || !this.hasInvoicesTarget) {
      console.error('Invoice template or invoices target not found')
      return
    }
    
    // Get the template content
    const content = this.invoiceTemplateTarget.innerHTML.replace(/NEW_INVOICE_RECORD/g, new Date().getTime())
    const newInvoice = document.createRange().createContextualFragment(content).firstElementChild
    
    // Add the new invoice to the form
    this.invoicesTarget.appendChild(newInvoice)
    
    // Initialize select for the new invoice
    const selects = newInvoice.querySelectorAll('[data-controller="select"]')
    selects.forEach(select => {
      const application = this.application
      application.getControllerForElementAndIdentifier(select, 'select')
    })
  }
  
  removeInvoice(event) {
    event.preventDefault()
    
    const invoice = event.target.closest(".purchase-invoice-fields")
    
    // If there's a hidden _destroy field, set it to 1 (mark for destruction)
    const destroyField = invoice.querySelector("input.destroy-flag")
    if (destroyField) {
      destroyField.value = "1"
      invoice.style.display = "none"
    } else {
      // Otherwise just remove the invoice from the DOM
      invoice.remove()
    }
  }
  
  updateInvoiceAmount(event) {
    // This function could be used to handle currency formatting or validation
    const amountField = event.target
    const value = amountField.value
    
    // Ensure only numbers and decimal point are entered
    const cleanValue = value.replace(/[^0-9.]/g, '')
    if (cleanValue !== value) {
      amountField.value = cleanValue
    }
  }
  
  validateInvoiceCustomId(event) {
    const customIdField = event.target
    const customId = customIdField.value.trim()
    
    if (!customId) {
      return // Skip validation for empty values
    }
    
    // Find the error message element for this specific field
    const errorElement = customIdField.closest('.purchase-invoice-fields').querySelector('[data-purchase-form-target="customIdError"]')
    
    // Check if the custom ID already exists
    fetch(`/admin/purchases/check_invoice_custom_id?custom_id=${encodeURIComponent(customId)}`)
      .then(response => response.json())
      .then(data => {
        if (data.exists) {
          // Show error message
          errorElement.classList.remove('hidden')
          customIdField.classList.add('border-red-500')
        } else {
          // Hide error message
          errorElement.classList.add('hidden')
          customIdField.classList.remove('border-red-500')
        }
      })
      .catch(error => {
        console.error('Error checking custom ID:', error)
      })
  }
}
