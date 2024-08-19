import { Controller } from '@hotwired/stimulus'
import axios from 'axios'

export default class extends Controller {
  static targets = ['items', 'total']

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    this.checkForDraftOrder()
    this.calculateTotal()
  }

  checkForDraftOrder() {
    const draftData = JSON.parse(sessionStorage.getItem('draftOrder') || '{}')
    if (draftData && draftData.order_items_attributes && draftData.order_items_attributes.length > 0) {
      this.showDraftButton()
    }
  }

  addItem(product) {
    const existingItem = this.itemsTarget.querySelector(`[data-item-name="${product.name}"]`)

    if (existingItem) {
      const quantityElement = existingItem.querySelector('[data-item-quantity]')
      const subtotalElement = existingItem.querySelector('[data-item-subtotal]')
      const newQuantity = parseInt(quantityElement.textContent) + product.quantity
      quantityElement.textContent = newQuantity
      const newSubtotal = (newQuantity * product.price).toFixed(2)
      subtotalElement.textContent = `S/ ${newSubtotal}`
    } else {
      const itemElement = document.createElement('div')
      itemElement.classList.add('grid', 'grid-cols-8', 'gap-2', 'mb-2', 'items-start')
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
    this.saveDraft() // Automatically save the draft whenever an item is added
  }

  calculateTotal() {
    let total = 0
    this.itemsTarget.querySelectorAll('div.grid').forEach(item => {
      const subtotal = parseFloat(item.querySelector('[data-item-subtotal]').textContent.replace('S/ ', ''))
      total += subtotal
    })
    this.totalTarget.textContent = `S/ ${total.toFixed(2)}`
  }

  saveDraft() {
    const orderData = this.collectOrderData()
    sessionStorage.setItem('draftOrder', JSON.stringify(orderData))
  }

  completeOrder() {
    const orderData = this.collectOrderData()
    this.sendOrderData(orderData)
  }

  loadDraft(event) {
    event.preventDefault()

    const draftData = JSON.parse(sessionStorage.getItem('draftOrder') || '{}')

    if (draftData.order_items_attributes) {
      this.clearItems()
      draftData.order_items_attributes.forEach(item => {
        this.addItem(item)
      })

      this.totalTarget.textContent = `S/ ${draftData.total_price.toFixed(2)}`
    } else {
      alert('No draft data found.')
    }
  }

  clearItems() {
    this.itemsTarget.innerHTML = ''
    this.totalTarget.textContent = 'S/ 0.00'
  }

  collectOrderData() {
    const orderItems = []
    this.itemsTarget.querySelectorAll('div.grid').forEach(item => {
      const name = item.querySelector('div.col-span-5 span.font-medium').textContent.trim()
      const sku = item.querySelector('div.col-span-5 span.text-sm').textContent.trim()
      const quantity = parseInt(item.querySelector('[data-item-quantity]').textContent.trim())
      const price = parseFloat(item.querySelector('div.col-span-1:nth-child(3) span').textContent.replace('S/ ', ''))
      const subtotal = parseFloat(item.querySelector('[data-item-subtotal]').textContent.replace('S/ ', ''))

      orderItems.push({ name, sku, quantity, price, subtotal })
    })

    return {
      total_price: parseFloat(this.totalTarget.textContent.replace('S/ ', '')),
      order_items_attributes: orderItems
    }
  }

  sendOrderData(orderData) {
    axios.post('/admin/orders', { order: orderData }, {
      headers: {
        'X-CSRF-Token': this.csrfToken
      }
    })
      .then(response => {
        console.log('Order completed:', response.data)
        alert('Order completed successfully.')
        sessionStorage.removeItem('draftOrder') // Clear the draft after saving the order
        window.location.href = `/admin/orders/${response.data.id}`
      })
      .catch(error => {
        console.error('Error completing order:', error)
        alert('Error completing order.')
      })
  }

  showDraftButton() {
    const draftButtonContainer = document.getElementById('draft-button-container')
    draftButtonContainer.innerHTML = `
      <a href="#" class="p-4 bg-yellow-400 rounded btn dark:bg-yellow-500 block w-full text-center" data-action="click->order-items#loadDraft">Recuperar Borrador</a>
    `
  }
}