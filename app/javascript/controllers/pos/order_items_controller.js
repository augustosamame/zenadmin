// app/javascript/controllers/order_items_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['items', 'total'];

  connect() {
    console.log('Connected to OrderItemsController!', this.element);
    // setup listeners for calls from other controllers
    this.element.addEventListener('clear-order', this.clearOrder.bind(this));

    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    this.maxDiscountPercentage = parseFloat(document.getElementById('max-price-discount-percentage').dataset.value);
    this.selectedItem = null;
    this.currentMode = 'quantity'; // Default mode is to update quantity
    const quantityButton = document.getElementById('quantity-mode-button');
    if (quantityButton) {
      quantityButton.classList.add('bg-blue-100');
      quantityButton.style.backgroundColor = '#bfdbfe'; // Ensure initial background color
    }
    this.isReplacingQuantity = false;
    this.priceJustSelected = true;
    this.calculateTotal();
  }

  addItem(product) {
    const existingItem = this.itemsTarget.querySelector(`[data-item-sku="${product.sku}"]`);

    if (existingItem) {
      this.updateExistingItem(existingItem, product);
    } else {
      this.addNewItem(product);
      this.selectItem({ currentTarget: this.itemsTarget.lastChild });
      this.currentMode = 'quantity'; // Default to quantity mode
    }

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
    });

    this.selectedItem = event.currentTarget;
    this.selectedItem.classList.add('bg-blue-100');

    // Mark the first keypress
    this.isFirstKeyPress = true;
  }

  updateQuantity(value) {
    if (!this.selectedItem) return;

    const quantityElement = this.selectedItem.querySelector('[data-item-quantity]');
    let currentQuantity = quantityElement.textContent.trim();

    // If the current quantity is '1' (default) and it's the first keypress, replace it with the new digit
    if (currentQuantity === '1' && this.isFirstKeyPress) {
      currentQuantity = value;
      this.isFirstKeyPress = false; // Reset after the first keypress
    } else {
      // Append the new digit to the current quantity
      currentQuantity += value;
    }

    // Ensure no leading zeros are present (except when the result is 0)
    currentQuantity = parseInt(currentQuantity, 10).toString();

    quantityElement.textContent = currentQuantity;

    // Update subtotal
    const price = parseFloat(this.selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''));
    const subtotalElement = this.selectedItem.querySelector('[data-item-subtotal]');
    subtotalElement.textContent = `S/ ${(parseInt(currentQuantity) * price).toFixed(2)}`;

    this.calculateTotal();
    this.saveDraft();
  }

  updatePrice(value) {
    if (!this.selectedItem) return;

    const priceElement = this.selectedItem.querySelector('.editable-price');
    let currentPrice = priceElement.textContent.replace('S/ ', '').trim();

    // If the currentPrice is '0.00' or the price mode was just selected, replace the value
    if (this.isReplacingQuantity || currentPrice === '0.00' || this.priceJustSelected) {
      currentPrice = value;
      this.priceJustSelected = false; // Reset after the first replacement
    } else {
      // Append the new digit to the current price
      currentPrice += value;
    }

    const parsedPrice = parseFloat(currentPrice).toFixed(2);
    priceElement.textContent = `S/ ${parsedPrice}`;

    // Update subtotal
    const quantity = parseInt(this.selectedItem.querySelector('[data-item-quantity]').textContent);
    const subtotalElement = this.selectedItem.querySelector('[data-item-subtotal]');
    subtotalElement.textContent = `S/ ${(quantity * parsedPrice).toFixed(2)}`;

    this.calculateTotal();
    this.saveDraft();
  }

  updateSubtotal() {
    const quantity = parseInt(this.selectedItem.querySelector('[data-item-quantity]').textContent);
    const price = parseFloat(this.selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''));
    const subtotalElement = this.selectedItem.querySelector('[data-item-subtotal]');
    subtotalElement.textContent = `S/ ${(quantity * price).toFixed(2)}`;
  }

  removeItem() {
    this.selectedItem.remove();
    this.selectedItem = null;
    this.calculateTotal();
    this.saveDraft();
  }

  handleKeypadForPrice(digit) {
    console.log('Digit:', digit);
    const selectedItem = this.itemsTarget.querySelector('.bg-blue-100');
    if (!selectedItem) return;

    const priceElement = this.selectedItem.querySelector('.editable-price');
    let currentPrice = priceElement.textContent.replace('S/', '').trim();

    if (this.priceJustSelected || currentPrice === '0.00') {
      currentPrice = digit;
      this.priceJustSelected = false;
    } else {
      currentPrice += digit;
      this.priceJustSelected = true;
    }

    // Ensure the price is valid and formatted correctly
    if (!currentPrice.includes('.')) {
      currentPrice = parseFloat(currentPrice).toFixed(2);
    }

    priceElement.textContent = `S/ ${currentPrice}`;
    console.log('Current Price:', currentPrice);
    console.log('About to calculate total:');
    this.calculateTotal();
    this.saveDraft(); // Save changes immediately
  }

  handleBackspaceForQuantity() {
    if (!this.selectedItem) return;

    const quantityElement = this.selectedItem.querySelector('[data-item-quantity]');
    let currentQuantity = quantityElement.textContent.trim();

    if (currentQuantity === '0') {
      this.removeItemFromSelection(); // Remove item if quantity is already 0
    } else {
      if (currentQuantity.length > 1) {
        currentQuantity = currentQuantity.slice(0, -1); // Remove the last digit
      } else {
        currentQuantity = '0'; // Set quantity to 0 if only one digit left
      }
      quantityElement.textContent = currentQuantity;

      // Update subtotal
      const price = parseFloat(this.selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''));
      const subtotalElement = this.selectedItem.querySelector('[data-item-subtotal]');
      subtotalElement.textContent = `S/ ${(parseInt(currentQuantity) * price).toFixed(2)}`;

      this.calculateTotal();
      this.saveDraft();
    }
  }

  handleBackspaceForPrice() {
    if (!this.selectedItem) return;

    const priceElement = this.selectedItem.querySelector('.editable-price');
    let currentPrice = priceElement.textContent.replace('S/ ', '').trim();

    if (currentPrice.length > 1) {
      currentPrice = currentPrice.slice(0, -1); // Remove the last digit
    } else {
      currentPrice = '0.00'; // Set to 0.00 if only one digit left
    }

    priceElement.textContent = `S/ ${parseFloat(currentPrice).toFixed(2)}`;

    // Update subtotal
    const quantity = parseInt(this.selectedItem.querySelector('[data-item-quantity]').textContent);
    const subtotalElement = this.selectedItem.querySelector('[data-item-subtotal]');
    subtotalElement.textContent = `S/ ${(quantity * parseFloat(currentPrice)).toFixed(2)}`;

    this.calculateTotal();
    this.saveDraft();
  }

  removeItemFromSelection() {
    if (!this.selectedItem) return;
    this.selectedItem.remove();
    this.selectedItem = null;
    this.calculateTotal();
    this.saveDraft();
  }

  calculateTotal() {
    let total = 0;
    this.itemsTarget.querySelectorAll('div.flex').forEach(item => {
      console.log('inside calculateTotal, item:', item);
      const subtotal = parseFloat(item.querySelector('[data-item-subtotal]').textContent.replace('S/ ', ''));
      console.log('Subtotal:', subtotal);
      total += subtotal;
    });
    this.totalTarget.textContent = `S/ ${total.toFixed(2)}`;
  }

  addDraftItem(item) {
    // Logic to add the draft item to the order
    const itemElement = document.createElement('div');
    itemElement.classList.add('flex', 'gap-2', 'mb-2', 'items-start', 'cursor-pointer');
    itemElement.setAttribute('data-item-name', item.name);
    itemElement.setAttribute('data-item-sku', item.sku);
    itemElement.setAttribute('data-item-original-price', item.price);
    itemElement.setAttribute('data-item-quantity', item.quantity);
    itemElement.innerHTML = `
      <div class="flex-grow" style="flex-basis: 55%;">
        <span class="block font-medium">${item.name}</span>
        <span class="block text-sm text-gray-500">${item.sku}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span data-item-quantity="${item.quantity}">${item.quantity}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span class="editable-price">S/ ${item.price}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span data-item-subtotal>S/ ${(item.quantity * item.price).toFixed(2)}</span>
      </div>
    `;
    this.itemsTarget.appendChild(itemElement);
    this.calculateTotal();
  }

  saveDraft() {
    const orderData = this.collectOrderData();
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
    itemElement.setAttribute('data-product-id', product.id);
    itemElement.setAttribute('data-action', 'click->pos--order-items#selectItem');

    itemElement.innerHTML = `
      <div class="flex-grow" style="flex-basis: 55%;">
        <span class="block font-medium">${product.name}</span>
        <span class="block text-sm text-gray-500">${product.sku}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span data-item-quantity="${product.quantity}">${product.quantity}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span class="editable-price">S/ ${product.price.toFixed(2)}</span>
      </div>
      <div class="flex-grow" style="flex-basis: 15%;">
        <span data-item-subtotal>S/ ${(product.quantity * product.price).toFixed(2)}</span>
      </div>
    `;

    this.itemsTarget.appendChild(itemElement);
  }

  clearOrder() {
    console.log('Clearing order...');
    this.itemsTarget.innerHTML = '';
    this.selectedItem = null;
    this.calculateTotal();
  }
}
