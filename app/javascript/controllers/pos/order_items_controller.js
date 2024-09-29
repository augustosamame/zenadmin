// app/javascript/controllers/order_items_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['items', 'total', 'loyaltyInfo', 'discountRow', 'discountAmount'];

  connect() {
    console.log('Connected to OrderItemsController!', this.element);
    // setup listeners for calls from other controllers
    this.element.addEventListener('clear-order', this.clearOrder.bind(this));

    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    this.maxDiscountPercentage = parseFloat(document.getElementById('max-price-discount-percentage').dataset.value);
    console.log('Max Discount Percentage:', this.maxDiscountPercentage);
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
    this.discountPercentage = 0;
    this.setupLoyaltyEventListeners();
    this.startingNewPrice = true;
  }

  setupLoyaltyEventListeners() {
    document.addEventListener('apply-loyalty-discount', this.handleLoyaltyDiscount.bind(this));
    document.addEventListener('add-loyalty-free-product', this.handleLoyaltyFreeProduct.bind(this));
  }

  handleLoyaltyDiscount(event) {
    this.discountPercentage = event.detail.discountPercentage;
    this.calculateTotal();
  }

  handleLoyaltyFreeProduct(event) {
    const { productId, productName, productCustomId } = event.detail;
    this.addItem({
      id: productId,
      custom_id: productCustomId,
      name: productName,
      price: 0,
      quantity: 1,
      isLoyaltyFree: true
    });
  }

  validateAllPrices() {
    let invalidProducts = [];
    const items = this.itemsTarget.querySelectorAll('div.flex');
    items.forEach(item => {
      const validationResult = this.validatePrice(item);
      if (!validationResult.isValid) {
        invalidProducts.push(validationResult);
      }
    });
    if (invalidProducts.length > 0) {
      this.showPriceValidationError(invalidProducts);
      return false;
    }
    return true;
  }

  validatePrice(item) {
    const priceElement = item.querySelector('.editable-price');
    const currentPrice = parseFloat(priceElement.textContent.replace('S/ ', ''));
    const originalPrice = parseFloat(item.getAttribute('data-item-original-price'));
    const minAllowedPrice = originalPrice * (1 - this.maxDiscountPercentage / 100);
    const productName = item.querySelector('div[style*="flex-basis: 55%"] span.font-medium').textContent.trim();

    if (currentPrice < minAllowedPrice) {
      return {
        isValid: false,
        productName: productName,
        currentPrice: currentPrice,
        minAllowedPrice: minAllowedPrice
      };
    }
    return { isValid: true };
  }

  showPriceValidationError(invalidProducts) {
    const productList = invalidProducts.map(product =>
      `- ${product.productName}: Precio actual S/ ${product.currentPrice.toFixed(2)}, Precio mínimo permitido S/ ${product.minAllowedPrice.toFixed(2)}`
    ).join('\n');

    const errorMessage = `Los siguientes productos tienen un precio por debajo del descuento máximo permitido (${this.maxDiscountPercentage}%):\n\n${productList}\n\nPor favor, revise los precios antes de continuar.`;

    const customModal = document.querySelector('[data-controller="custom-modal"]');
    if (customModal) {
      const customModalController = this.application.getControllerForElementAndIdentifier(customModal, 'custom-modal');
      if (customModalController) {
        customModalController.openWithContent('Error de Validación', errorMessage, [
          { label: 'OK', classes: 'btn btn-primary', action: 'click->custom-modal#close' }
        ]);
      } else {
        console.error('CustomModalController not found!');
        alert(errorMessage);
      }
    } else {
      console.error('Custom modal element not found!');
      alert(errorMessage);
    }
  }

  applyDiscount(event) {
    this.discountPercentage = parseFloat(event.currentTarget.dataset.discount);
    this.calculateTotal();
  }

  addItem(product) {
    const existingItem = this.itemsTarget.querySelector(`[data-item-sku="${product.custom_id}"]`);
    
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

    if (product.isLoyaltyFree) {
      const itemElement = existingItem || this.itemsTarget.lastChild;
      itemElement.setAttribute('data-item-loyalty-free', 'true');
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
    this.startingNewPrice = true;
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

  updateSubtotal(item) {
    const quantity = parseInt(item.querySelector('[data-item-quantity]').textContent);
    const price = parseFloat(item.querySelector('.editable-price').textContent.replace('S/ ', ''));
    const subtotalElement = item.querySelector('[data-item-subtotal]');
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
    if (!this.selectedItem) return;

    const priceElement = this.selectedItem.querySelector('.editable-price');
    let currentPrice = priceElement.textContent.replace('S/ ', '').replace('.', '');

    // If we're starting a new price entry or the current price is 0
    if (this.startingNewPrice || currentPrice === '000') {
      currentPrice = digit;
      this.startingNewPrice = false;
    } else {
      currentPrice += digit;
    }

    // Remove leading zeros
    currentPrice = currentPrice.replace(/^0+/, '');

    // Ensure we have at least 3 digits (including 2 decimal places)
    while (currentPrice.length < 3) {
      currentPrice = '0' + currentPrice;
    }

    // Insert decimal point
    let formattedPrice = (currentPrice.slice(0, -2) + '.' + currentPrice.slice(-2)).replace(/^\./, '0.');

    priceElement.textContent = `S/ ${formattedPrice}`;
    console.log('Current Price:', formattedPrice);

    this.updateSubtotal(this.selectedItem);
    this.calculateTotal();
    this.saveDraft();
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
    let currentPrice = priceElement.textContent.replace('S/ ', '').replace('.', '');

    if (currentPrice.length > 1) {
      currentPrice = currentPrice.slice(0, -1);
    } else {
      currentPrice = '000';
      this.startingNewPrice = true;
    }

    // Ensure we have at least 3 digits (including 2 decimal places)
    while (currentPrice.length < 3) {
      currentPrice = '0' + currentPrice;
    }

    // Insert decimal point
    let formattedPrice = (currentPrice.slice(0, -2) + '.' + currentPrice.slice(-2)).replace(/^\./, '0.');

    priceElement.textContent = `S/ ${formattedPrice}`;

    this.updateSubtotal(this.selectedItem);
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
    let subtotal = 0;
    const items = this.itemsTarget.querySelectorAll('div.flex');

    if (items.length === 0) {
      // No items in the order
      this.discountRowTarget.classList.add('hidden');
      this.totalTarget.textContent = 'S/ 0.00';
      return;
    }

    items.forEach(item => {
      console.log('inside calculateTotal, item:', item);
      const itemSubtotalElement = item.querySelector('[data-item-subtotal]');
      if (itemSubtotalElement) {
        const itemSubtotal = parseFloat(itemSubtotalElement.textContent.replace('S/ ', ''));
        console.log('Subtotal:', itemSubtotal);
        if (!isNaN(itemSubtotal)) {
          subtotal += itemSubtotal;
        }
      }
    });

    const discountAmount = subtotal * (this.discountPercentage / 100);
    const total = subtotal - discountAmount;

    if (this.discountPercentage > 0) {
      this.discountRowTarget.classList.remove('hidden');
      this.discountAmountTarget.textContent = `(S/ ${discountAmount.toFixed(2)})`;
    } else {
      this.discountRowTarget.classList.add('hidden');
    }

    this.totalTarget.textContent = `S/ ${total.toFixed(2)}`;

    // const event = new CustomEvent('orderTotalUpdated', { detail: { total: total } });
    // window.dispatchEvent(event);
  }

  addDraftItem(item) {
    // Logic to add the draft item to the order
    const itemElement = document.createElement('div');
    itemElement.classList.add('flex', 'gap-2', 'mb-2', 'items-start', 'cursor-pointer');
    itemElement.setAttribute('data-item-name', item.name);
    itemElement.setAttribute('data-item-sku', item.custom_id);
    itemElement.setAttribute('data-item-original-price', item.price);
    itemElement.setAttribute('data-item-quantity', item.quantity);
    itemElement.innerHTML = `
      <div class="flex-grow" style="flex-basis: 55%;">
        <span class="block font-medium">${item.name}</span>
        <span class="block text-sm text-gray-500">${item.custom_id}</span>
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
      const id = item.dataset.productId;
      const name = item.querySelector('div[style*="flex-basis: 55%"] span.font-medium').textContent.trim();
      const custom_id = item.querySelector('div[style*="flex-basis: 55%"] span.text-sm').textContent.trim();
      const quantity = parseInt(item.querySelector('[data-item-quantity]').textContent.trim());
      const price = parseFloat(item.querySelector('.editable-price').textContent.replace('S/ ', ''));
      const subtotal = parseFloat(item.querySelector('[data-item-subtotal]').textContent.replace('S/ ', ''));
      const isLoyaltyFree = item.hasAttribute('data-loyalty-free-product');

      orderItems.push({ id, name, custom_id, quantity, price, subtotal, isLoyaltyFree });
    });

    return {
      total_price: parseFloat(this.totalTarget.textContent.replace('S/ ', '')),
      discount_percentage: this.discountPercentage,
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
    itemElement.setAttribute('data-item-sku', product.custom_id);
    itemElement.setAttribute('data-item-original-price', product.price);
    itemElement.setAttribute('data-product-id', product.id);
    itemElement.setAttribute('data-action', 'click->pos--order-items#selectItem');

    itemElement.innerHTML = `
      <div class="flex-grow" style="flex-basis: 55%;">
        <span class="block font-medium">${product.name}</span>
        <span class="block text-sm text-gray-500">${product.custom_id}</span>
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
