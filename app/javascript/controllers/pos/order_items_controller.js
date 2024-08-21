// app/javascript/controllers/order_items_controller.js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['items', 'total'];

  connect() {
    console.log('Connected to OrderItemsController!', this.element);
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    this.maxDiscountPercentage = parseFloat(document.getElementById('max-price-discount-percentage').dataset.value);
    this.calculateTotal();
  }

  addItem(product) {
    const existingItem = this.itemsTarget.querySelector(`[data-item-sku="${product.sku}"]`);

    if (existingItem) {
      this.updateExistingItem(existingItem, product);
    } else {
      this.addNewItem(product);
    }

    // hide load draft button
    const buttonsElement = document.querySelector('[data-controller="pos--buttons"]');
    const buttonsController = this.application.getControllerForElementAndIdentifier(buttonsElement, 'pos--buttons');
    if (buttonsController) {
      buttonsController.hideDraftButton();
    }

    this.calculateTotal();
    this.saveDraft();
  }

  selectItem(event) {
    // Clear any previously selected items
    this.itemsTarget.querySelectorAll('div.flex').forEach(item => {
      item.classList.remove('bg-blue-100');
      item.querySelector('.editable-price').setAttribute('contenteditable', 'false');
      item.querySelectorAll('.action-buttons').forEach(button => button.remove());
    });

    const selectedItem = event.currentTarget;
    selectedItem.classList.add('bg-blue-100');

    // Make price editable
    const priceElement = selectedItem.querySelector('.editable-price');
    priceElement.setAttribute('contenteditable', 'true');
    priceElement.focus();

    // Add action buttons
    const actionButtonsHTML = `
      <div class="action-buttons flex justify-start space-x-2 col-span-1">
        <button type="button" class="quantity-up bg-gray-200 px-2 py-1 rounded">▲</button>
        <button type="button" class="quantity-down bg-gray-200 px-2 py-1 rounded">▼</button>
        <button type="button" class="remove-item bg-red-200 px-2 py-1 rounded">✖</button>
      </div>
    `;
    selectedItem.insertAdjacentHTML('beforeend', actionButtonsHTML);

    // Attach event listeners for the action buttons
    this.addActionButtonsEventListeners(selectedItem);
  }

  updatePrice(event) {
    const priceElement = event.currentTarget;
    const itemElement = priceElement.closest('div.flex');
    const originalPrice = parseFloat(itemElement.dataset.itemOriginalPrice);
    let newPrice = parseFloat(priceElement.textContent.replace('S/ ', ''));

    // Ensure price doesn't go below allowed discount
    const maxDiscount = Math.ceil((originalPrice * (1 - this.maxDiscountPercentage / 100)) * 100) / 100;
    if (newPrice < maxDiscount) {
      newPrice = maxDiscount;
      priceElement.textContent = `S/ ${newPrice.toFixed(2)}`;
      alert(`El precio no puede ser menor que S/ ${newPrice.toFixed(2)}, que es el máximo descuento permitido.`);
    }

    // Update the subtotal
    const quantity = parseInt(itemElement.querySelector('[data-item-quantity]').textContent);
    const subtotalElement = itemElement.querySelector('[data-item-subtotal]');
    subtotalElement.textContent = `S/ ${(newPrice * quantity).toFixed(2)}`;

    this.calculateTotal();
    this.saveDraft();
  }

  incrementQuantity(event) {
    event.stopPropagation();
    const selectedItem = event.currentTarget.closest('div.flex');
    const quantityElement = selectedItem.querySelector('[data-item-quantity]');
    const price = parseFloat(selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''));
    let quantity = parseInt(quantityElement.textContent);
    quantity += 1;
    quantityElement.textContent = quantity;
    selectedItem.querySelector('[data-item-subtotal]').textContent = `S/ ${(quantity * price).toFixed(2)}`;
    this.calculateTotal();
    this.saveDraft();
  }

  decrementQuantity(event) {
    event.stopPropagation();
    const selectedItem = event.currentTarget.closest('div.flex');
    const quantityElement = selectedItem.querySelector('[data-item-quantity]');
    const price = parseFloat(selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''));
    let quantity = parseInt(quantityElement.textContent);
    if (quantity > 1) {
      quantity -= 1;
      quantityElement.textContent = quantity;
      selectedItem.querySelector('[data-item-subtotal]').textContent = `S/ ${(quantity * price).toFixed(2)}`;
      this.calculateTotal();
      this.saveDraft();
    }
  }

  removeItem(event) {
    event.stopPropagation();
    const selectedItem = event.currentTarget.closest('div.flex');
    selectedItem.remove();
    this.calculateTotal();
    this.saveDraft();
  }

  calculateTotal() {
    let total = 0;
    this.itemsTarget.querySelectorAll('div.flex').forEach(item => {
      const subtotal = parseFloat(item.querySelector('[data-item-subtotal]').textContent.replace('S/ ', ''));
      total += subtotal;
    });
    this.totalTarget.textContent = `S/ ${total.toFixed(2)}`;
  }

  saveDraft() {
    console.log('Saving draft...');
    const orderData = this.collectOrderData();
    console.log('Draft Order Data:', orderData);
    sessionStorage.setItem('draftOrder', JSON.stringify(orderData));
  }

  collectOrderData() {
    const orderItems = [];
    this.itemsTarget.querySelectorAll('div.flex').forEach(item => {
      const name = item.querySelector('div[style*="flex-basis: 55%"] span.font-medium').textContent.trim();
      const sku = item.querySelector('div[style*="flex-basis: 55%"] span.text-sm').textContent.trim();
      const quantity = parseInt(item.querySelector('[data-item-quantity]').textContent.trim());
      const price = parseFloat(item.querySelector('.editable-price').textContent.replace('S/ ', ''));
      const subtotal = parseFloat(item.querySelector('[data-item-subtotal]').textContent.replace('S/ ', ''));

      orderItems.push({ name, sku, quantity, price, subtotal });
    });

    return {
      total_price: parseFloat(this.totalTarget.textContent.replace('S/ ', '')),
      order_items_attributes: orderItems
    };
  }

  // Additional helper methods for item updates
  updateExistingItem(existingItem, product) {
    const quantityElement = existingItem.querySelector('[data-item-quantity]');
    const subtotalElement = existingItem.querySelector('[data-item-subtotal]');
    const newQuantity = parseInt(quantityElement.textContent) + product.quantity;
    quantityElement.textContent = newQuantity;
    const newSubtotal = (newQuantity * product.price).toFixed(2);
    subtotalElement.textContent = `S/ ${newSubtotal}`;
  }

  addNewItem(product) {
    const itemElement = document.createElement('div');
    itemElement.classList.add('flex', 'gap-2', 'mb-2', 'items-start', 'cursor-pointer');
    itemElement.setAttribute('data-item-name', product.name);
    itemElement.setAttribute('data-item-sku', product.sku);
    itemElement.setAttribute('data-item-original-price', product.price);
    itemElement.setAttribute('data-action', 'click->order-items#selectItem');

    itemElement.innerHTML = `
      <div class="flex-grow" style="flex-basis: 55%;">
        <span class="block font-medium">${product.name}</span>
        <span class="block text-sm text-gray-500">${product.sku}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span data-item-quantity="${product.quantity}">${product.quantity}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span class="editable-price" contenteditable="false" data-action="blur->order-items#updatePrice">S/ ${product.price.toFixed(2)}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span data-item-subtotal>S/ ${(product.quantity * product.price).toFixed(2)}</span>
      </div>
    `;

    this.itemsTarget.appendChild(itemElement);
  }

  addDraftItem(item) { // This method is called from the Pos__ButtonsController when restoring a draft order
    this.addNewItem(item);
    this.calculateTotal();
  }

  addActionButtonsEventListeners(selectedItem) {
    selectedItem.querySelector('.quantity-up').addEventListener('click', this.incrementQuantity.bind(this));
    selectedItem.querySelector('.quantity-down').addEventListener('click', this.decrementQuantity.bind(this));
    selectedItem.querySelector('.remove-item').addEventListener('click', this.removeItem.bind(this));
  }
}
