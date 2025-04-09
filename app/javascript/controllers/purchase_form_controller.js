import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lines", "template", "form", "transportistaInfo"]

  connect() {
    console.log("Purchase Form controller connected")
    
    // Initialize transportista select
    const transportistaSelect = this.element.querySelector('select[name*="transportista_id"]')
    if (transportistaSelect) {
      transportistaSelect.addEventListener('change', this.updateTransportistaInfo.bind(this))
    }
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
    this.addLine(event)
  }

  addLine(event) {
    event.preventDefault()
    
    // Get the template content
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    const newLine = document.createRange().createContextualFragment(content).firstElementChild
    
    // Add the new line to the form
    this.linesTarget.appendChild(newLine)
    
    // Initialize select2 for the new line
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
    }
  }
}
