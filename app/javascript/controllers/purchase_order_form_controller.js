import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lines", "template", "form", "transportistaInfo"]

  connect() {
    console.log("Purchase order form controller connected")
    this.initializeProductSelects()
    
    // Initialize existing lines
    this.linesTarget.querySelectorAll('.purchase-order-line').forEach(line => {
      this.initializeLineTotal(line)
    })

    // Initialize transportista select
    const transportistaSelect = this.element.querySelector('select[name*="transportista_id"]')
    if (transportistaSelect) {
      transportistaSelect.addEventListener('change', this.updateTransportistaInfo.bind(this))
    }
  }

  initializeProductSelects() {
    this.element.querySelectorAll('select[data-controller="select"]').forEach(select => {
      select.addEventListener('change', (event) => this.updateLineTotal(event))
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

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    const newLine = document.createRange().createContextualFragment(content).firstElementChild

    // Clean up TomSelect elements in the new line
    newLine.querySelectorAll(".ts-wrapper").forEach(wrapper => wrapper.remove())
    newLine.querySelectorAll("input, select").forEach(input => {
      if (input.name.includes("quantity")) {
        input.value = "1"
      } else if (input.name.includes("unit_price")) {
        input.value = "0.00"
      } else {
        input.value = ""
      }
      input.classList.remove("tomselected", "ts-hidden-accessible")
      input.removeAttribute("id")
      input.style.display = ''
    })

    this.linesTarget.appendChild(newLine)

    // Initialize event listeners for the new line
    const newSelect = newLine.querySelector('select[data-controller="select"]')
    if (newSelect) {
      newSelect.addEventListener('change', (event) => this.updateLineTotal(event))
    }
    
    // Initialize the line total
    this.initializeLineTotal(newLine)
  }

  remove(event) {
    event.preventDefault()

    // Find the closest line item to remove
    const line = event.target.closest(".purchase-order-line")

    // Mark the hidden field for _destroy if it exists or remove the element directly
    const destroyInput = line.querySelector('input[name*="_destroy"]')
    if (destroyInput) {
      destroyInput.value = 1
      line.style.display = "none"
    } else {
      line.remove()
    }
  }

  updateLineTotal(event) {
    // Find the closest line item
    const line = event.target.closest(".purchase-order-line")
    if (!line) {
      console.warn("Could not find purchase-order-line element for updateLineTotal", {
        eventTarget: event.target,
        eventTargetId: event.target.id,
        eventTargetName: event.target.name,
        eventTargetClass: event.target.className
      })
      return
    }

    // Get quantity and unit price inputs
    const quantityInput = line.querySelector('input[name*="quantity"]')
    const unitPriceInput = line.querySelector('input[name*="unit_price"]')
    const totalElement = line.querySelector('.line-total')

    if (quantityInput && unitPriceInput && totalElement) {
      const quantity = parseFloat(quantityInput.value) || 0
      const unitPrice = parseFloat(unitPriceInput.value) || 0
      const total = quantity * unitPrice

      // Format the total as currency
      const formatter = new Intl.NumberFormat('es-PE', {
        style: 'currency',
        currency: 'PEN',
        minimumFractionDigits: 2
      })

      totalElement.textContent = formatter.format(total)
    }
  }

  initializeLineTotal(line) {
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
    }
  }
}
