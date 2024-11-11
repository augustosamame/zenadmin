import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "minStock", "maxStock", "multipliers", "multiplierFields", "form", "periodSelect", "multiplierInput"]

  connect() {
    console.log("MinMaxStockController connected")
  }

  addPeriodMultiplier(event) {
    event.preventDefault()
    const button = event.currentTarget
    const multipliersContainer = button.nextElementSibling
    const template = multipliersContainer.querySelector('[data-min-max-stock-target="multiplierFields"]').cloneNode(true)

    // Update the name attributes to include the correct product index
    const row = button.closest('[data-product-id]')
    const productId = row.dataset.productId
    const productIndex = Array.from(row.parentElement.children).indexOf(row)

    template.querySelectorAll('select, input').forEach(element => {
      const name = element.getAttribute('name')
      if (name) {
        element.setAttribute('name', name.replace('[]', `[${productIndex}]`))
      }
    })

    multipliersContainer.classList.remove('hidden')
    multipliersContainer.appendChild(template)
  }

  removePeriodMultiplier(event) {
    event.preventDefault()
    const fields = event.currentTarget.closest('[data-min-max-stock-target="multiplierFields"]')
    const container = fields.parentElement

    fields.remove()

    if (container.children.length === 1) {
      container.classList.add('hidden')
    }
  }

  submitForm(event) {
    event.preventDefault()

    // Validate min/max values
    let isValid = true
    this.rowTargets.forEach(row => {
      const minStock = parseInt(row.querySelector('[data-min-max-stock-target="minStock"]').value)
      const maxStock = parseInt(row.querySelector('[data-min-max-stock-target="maxStock"]').value)

      if (minStock > maxStock) {
        alert("El stock mínimo no puede ser mayor al stock máximo")
        isValid = false
        return
      }

      // Validate period multipliers
      const multipliers = row.querySelectorAll('[data-min-max-stock-target="multiplierFields"]')
      multipliers.forEach(multiplier => {
        const period = multiplier.querySelector('[data-min-max-stock-target="periodSelect"]').value
        const value = multiplier.querySelector('[data-min-max-stock-target="multiplierInput"]').value

        if ((period && !value) || (!period && value)) {
          alert("Los multiplicadores deben tener tanto periodo como valor")
          isValid = false
          return
        }
      })
    })

    if (isValid) {
      this.formTarget.submit()
    }
  }
}