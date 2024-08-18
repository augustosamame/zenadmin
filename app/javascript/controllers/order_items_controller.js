import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['items', 'total']

  connect() {
    this.calculateTotal()
  }

  addItem(product) {
    // Check if the item already exists
    const existingItem = this.itemsTarget.querySelector(`[data-item-name="${product.name}"]`)

    if (existingItem) {
      // Update the quantity and total price if the item already exists
      const quantityElement = existingItem.querySelector('[data-item-quantity]')
      const priceElement = existingItem.querySelector('[data-item-price]')
      const subtotalElement = existingItem.querySelector('[data-item-subtotal]')

      const newQuantity = parseInt(quantityElement.textContent) + product.quantity
      quantityElement.textContent = newQuantity

      const newSubtotal = (newQuantity * product.price).toFixed(2)
      subtotalElement.textContent = `S/ ${newSubtotal}`
    } else {
      // Create a new item row if it doesn't exist
      const itemElement = document.createElement('div')
      itemElement.classList.add('grid', 'grid-cols-8', 'gap-2', 'mb-2', 'items-start')

      // Create the columns
      itemElement.setAttribute('data-item-name', product.name)
      itemElement.innerHTML = `
        <div class="col-span-5">
          <span class="block font-medium">${product.name}</span>
          <span class="block text-sm text-gray-500">${product.sku}</span>
        </div>
        <div class="col-span-1">
          <span data-item-quantity="${product.quantity}">${product.quantity}</span>
        </div>
        <div class="col-span-1">
          <span>S/ ${product.price.toFixed(2)}</span>
        </div>
        <div class="col-span-1">
          <span data-item-subtotal>S/ ${(product.quantity * product.price).toFixed(2)}</span>
        </div>
      `

      this.itemsTarget.appendChild(itemElement)
    }

    this.calculateTotal()
  }

  calculateTotal() {
    let total = 0
    this.itemsTarget.querySelectorAll('div.grid').forEach(item => {
      const subtotal = parseFloat(item.querySelector('[data-item-subtotal]').textContent.replace('S/ ', ''))
      total += subtotal
    })
    this.totalTarget.textContent = `S/ ${total.toFixed(2)}`
  }
}