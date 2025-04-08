import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lineItems"]

  connect() {
    console.log("Purchase Form controller connected")
  }

  addLine(event) {
    event.preventDefault()
    
    // Get the template content
    const template = document.getElementById("purchase-line-template")
    const content = template.content.cloneNode(true)
    
    // Replace the placeholder index with a unique one
    const newIndex = new Date().getTime()
    const html = content.innerHTML.replace(/NEW_RECORD/g, newIndex)
    
    // Create a temporary container
    const temp = document.createElement('tbody')
    temp.innerHTML = html
    
    // Append the new line
    this.lineItemsTarget.appendChild(temp.firstElementChild)
  }

  removeLine(event) {
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
