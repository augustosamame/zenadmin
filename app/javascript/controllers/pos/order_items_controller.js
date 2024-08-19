import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['items', 'total']

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    this.maxDiscountPercentage = parseFloat(document.getElementById('max-price-discount-percentage').dataset.value);
    console.log("Max Discount Percentage:", this.maxDiscountPercentage);

    this.checkForDraftOrder()
    this.calculateTotal()
  }

  checkForDraftOrder() {
    const draftData = JSON.parse(sessionStorage.getItem('draftOrder') || '{}');

    // Check if there are any items already in the list
    const currentItemCount = this.itemsTarget.querySelectorAll('div.grid').length;
    const draftItemCount = draftData.order_items_attributes ? draftData.order_items_attributes.length : 0;

    // Show the draft button only if there are no items in the list and draft data is available with items
    if (currentItemCount === 0 && draftItemCount > 0) {
      this.showDraftButton();
    } else {
      this.hideDraftButton();
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
      itemElement.classList.add('grid', 'grid-cols-8', 'gap-2', 'mb-2', 'items-start', 'cursor-pointer')
      itemElement.setAttribute('data-item-name', product.name)
      itemElement.setAttribute('data-item-original-price', product.price);
      itemElement.setAttribute('data-action', 'click->pos--order-items#selectItem')

      itemElement.innerHTML = `
        <div class="col-span-5">
          <span class="block font-medium">${product.name}</span>
          <span class="block text-sm text-gray-500">${product.sku}</span>
        </div>
        <div class="col-span-1">
          <span data-item-quantity="${product.quantity}">${product.quantity}</span>
        </div>
        <div class="col-span-1">
          <span class="editable-price" contenteditable="false" data-action="blur->pos--order-items#updatePrice">S/ ${product.price.toFixed(2)}</span>
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

  selectItem(event) {
    // Clear any previously selected items
    this.itemsTarget.querySelectorAll('div.grid').forEach(item => {
      item.classList.remove('bg-blue-100')
      item.querySelector('.editable-price').setAttribute('contenteditable', 'false')
      item.querySelectorAll('.action-buttons').forEach(button => button.remove())
    })

    const selectedItem = event.currentTarget
    selectedItem.classList.add('bg-blue-100')

    // Make price editable
    const priceElement = selectedItem.querySelector('.editable-price')
    priceElement.setAttribute('contenteditable', 'true')
    priceElement.focus()

    // Add action buttons
    const actionButtonsHTML = `
      <div class="action-buttons flex justify-start space-x-2 col-span-1">
        <button type="button" class="quantity-up bg-gray-200 px-2 py-1 rounded">▲</button>
        <button type="button" class="quantity-down bg-gray-200 px-2 py-1 rounded">▼</button>
        <button type="button" class="remove-item bg-red-200 px-2 py-1 rounded">✖</button>
      </div>
    `
    selectedItem.insertAdjacentHTML('beforeend', actionButtonsHTML)

    // Attach event listeners for the action buttons
    selectedItem.querySelector('.quantity-up').addEventListener('click', this.incrementQuantity.bind(this))
    selectedItem.querySelector('.quantity-down').addEventListener('click', this.decrementQuantity.bind(this))
    selectedItem.querySelector('.remove-item').addEventListener('click', this.removeItem.bind(this))
  }

  updatePrice(event) {
    const priceElement = event.currentTarget;
    const itemElement = priceElement.closest('div.grid');
    const originalPrice = parseFloat(itemElement.dataset.itemOriginalPrice);
    console.log("Original Price:", originalPrice);
    let newPrice = parseFloat(priceElement.textContent.replace('S/ ', ''));
    console.log("New Price:", newPrice);

    // Calculate the maximum allowed discount price
    const maxDiscount = Math.ceil((originalPrice * (1 - this.maxDiscountPercentage / 100)) * 100) / 100;
    console.log("Max Discount:", maxDiscount);

    // If the new price is less than the maximum allowed discount price, reset it and show an alert
    if (newPrice < maxDiscount) {
      console.log("Price is less than max discount.", newPrice, maxDiscount);
      newPrice = maxDiscount;
      priceElement.textContent = `S/ ${newPrice.toFixed(2)}`;
      alert(`El precio no puede ser menor que S/ ${newPrice.toFixed(2)}, que es el máximo descuento permitido.`);
    }

    // Update the subtotal
    const quantity = parseInt(itemElement.querySelector('[data-item-quantity]').textContent);
    const subtotalElement = itemElement.querySelector('[data-item-subtotal]');
    subtotalElement.textContent = `S/ ${(newPrice * quantity).toFixed(2)}`;

    this.calculateTotal();
    this.saveDraft(); // Save the draft again with the updated price
  }

  incrementQuantity(event) {
    event.stopPropagation()
    const selectedItem = event.currentTarget.closest('div.grid')
    const quantityElement = selectedItem.querySelector('[data-item-quantity]')
    const price = parseFloat(selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''))
    let quantity = parseInt(quantityElement.textContent)
    quantity += 1
    quantityElement.textContent = quantity
    selectedItem.querySelector('[data-item-subtotal]').textContent = `S/ ${(quantity * price).toFixed(2)}`
    this.calculateTotal()
    this.saveDraft()
  }

  decrementQuantity(event) {
    event.stopPropagation()
    const selectedItem = event.currentTarget.closest('div.grid')
    const quantityElement = selectedItem.querySelector('[data-item-quantity]')
    const price = parseFloat(selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''))
    let quantity = parseInt(quantityElement.textContent)
    if (quantity > 1) {
      quantity -= 1
      quantityElement.textContent = quantity
      selectedItem.querySelector('[data-item-subtotal]').textContent = `S/ ${(quantity * price).toFixed(2)}`
      this.calculateTotal()
      this.saveDraft()
    }
  }

  removeItem(event) {
    event.stopPropagation()
    const selectedItem = event.currentTarget.closest('div.grid')
    selectedItem.remove()
    this.calculateTotal()
    this.saveDraft()
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
    this.checkForDraftOrder()
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
      const price = parseFloat(item.querySelector('.editable-price').textContent.replace('S/ ', ''))
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
      <a href="#" class="p-4 bg-yellow-400 rounded btn dark:bg-yellow-500 block w-full text-center" data-action="click->pos--order-items#loadDraft">Recuperar Borrador</a>
    `
  }
  hideDraftButton() {
    const draftButtonContainer = document.getElementById('draft-button-container');
    draftButtonContainer.innerHTML = ''; // Clear the button
  }
}