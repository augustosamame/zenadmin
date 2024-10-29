// app/javascript/controllers/order_items_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['items', 'total', 'loyaltyInfo', 'discountRow', 'discountAmount', 'discountName'];

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
    this.comboDiscounts = new Map(); // To store discounts for each combo
    this.groupDiscountAmount = 0;
    this.groupDiscountNames = [];
    this.packDiscounts = new Map();
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
      already_discounted: true,
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
      // buttonsController.hideDraftButton();
    }

    if (product.isLoyaltyFree) {
      const itemElement = existingItem || this.itemsTarget.lastChild;
      itemElement.setAttribute('data-item-loyalty-free', 'true');
    }

    this.calculateTotal();
    this.evaluateGroupDiscount();
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
    console.log('updating quantity:', value);
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

    if (this.selectedItem.hasAttribute('data-combo-id')) {
      console.log('has Combo ID:', this.selectedItem.getAttribute('data-combo-id'), 'will check and update');
      this.checkAndUpdateComboDiscount(this.selectedItem);
    }

    this.calculateTotal();
    this.evaluateGroupDiscount();
    this.saveDraft();
  }

  checkAndUpdateComboDiscount(item) {
    const originalQuantity = parseInt(item.getAttribute('data-original-quantity'));
    const currentQuantity = parseInt(item.querySelector('[data-item-quantity]').textContent);

    if (currentQuantity < originalQuantity) {
      this.removeComboDiscount(item);
    }
  }

  removeComboDiscount(item) {
    console.log('removing combo discount for:', item);
    const comboId = item.getAttribute('data-combo-id');
    // Convert comboId to the same type as the keys in the Map
    const keyToDelete = Array.from(this.comboDiscounts.keys()).find(key => key.toString() === comboId);

    if (keyToDelete !== undefined) {
      this.comboDiscounts.delete(keyToDelete);
    }

    // Remove combo attributes from all items with this combo ID
    this.itemsTarget.querySelectorAll(`[data-combo-id="${comboId}"]`).forEach(comboItem => {
      comboItem.removeAttribute('data-combo-id');
      comboItem.removeAttribute('data-original-quantity');
    });
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

  evaluateGroupDiscount() {
    // Reset only previous group discount flags
    this.resetGroupDiscountFlags();

    const orderData = this.collectOrderData();
    const orderDataItemsAttributes = orderData.order_items_attributes;
    console.log('orderDataItemsAttributes:', orderDataItemsAttributes);
    const orderItemsArrayOfHashes = orderDataItemsAttributes
      .filter(item => !item.isDiscounted)
      .map(item => ({
        product_id: item.id,
        qty: item.quantity,
        price: item.price
      }));

    fetch('/admin/products/evaluate_group_discount', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({ pos_items: orderItemsArrayOfHashes })
    })
      .then(response => response.json())
      .then(data => {
        if (data.discounted_product_ids) {
          this.itemsTarget.querySelectorAll('div.flex').forEach(item => {
            const productId = item.dataset.productId;
            if (data.discounted_product_ids.map(String).includes(productId)) {
              console.log(`Marking product ${productId} as group discounted`);
              item.setAttribute('data-item-already-discounted', 'true');
              item.setAttribute('data-group-discount', 'true'); // Add this flag for group discounts
            }
          });
        }

        this.applyGroupDiscount(data.total_discount_to_apply, data.applied_discount_names);
      })
      .catch(error => console.error('Error evaluating group discount:', error));
  }

  applyGroupDiscount(totalDiscount, discountNames) {
    this.groupDiscountAmount = totalDiscount;
    this.groupDiscountNames = discountNames || [];
    this.calculateTotal();
    // Logic to apply the discount to the total
    // const currentTotal = parseFloat(this.totalTarget.textContent.replace('S/ ', ''));
    // const newTotal = currentTotal - totalDiscount;
    // this.totalTarget.textContent = `S/ ${newTotal.toFixed(2)}`;
  }

  removeItem() {
    console.log('removing item:', this.selectedItem);
    if (this.selectedItem.hasAttribute('data-combo-id')) {
      console.log('removing combo discount for:', this.selectedItem);
      this.removeComboDiscount(this.selectedItem);;
    }

    this.selectedItem.remove();
    this.selectedItem = null;
    this.calculateTotal();
    this.evaluateGroupDiscount();
    this.saveDraft();
  }

  handleKeypadForPrice(digit) {
    console.log('Digit:', digit);
    if (!this.selectedItem) return;

    // Check if the item is already discounted
    const isAlreadyDiscounted = this.selectedItem.getAttribute('data-item-already-discounted') === 'true';
    if (isAlreadyDiscounted) {
      console.log('Cannot edit price for already discounted item');
      return; // Exit the method if the item is already discounted
    }

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

      if (this.selectedItem.hasAttribute('data-combo-id')) {
        console.log('has Combo ID:', this.selectedItem.getAttribute('data-combo-id'), 'will check and update');
        this.checkAndUpdateComboDiscount(this.selectedItem);
      }

      this.evaluateGroupDiscount();
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
    this.evaluateGroupDiscount();
    this.calculateTotal();
    this.saveDraft();
  }
  
  removeItemFromSelection() {
    console.log('removing item:', this.selectedItem);
    if (this.selectedItem.hasAttribute('data-combo-id')) {
      this.removeComboDiscount(this.selectedItem);;
    }

    if (!this.selectedItem) return;
    this.selectedItem.remove();
    this.selectedItem = null;
    this.evaluateGroupDiscount();
    this.calculateTotal();
    this.saveDraft();
  }

  addPackDiscount(packId, discountAmount, packName) {
    this.packDiscounts = this.packDiscounts || new Map();
    this.packDiscounts.set(packId, { amount: discountAmount, name: packName });
    this.calculateTotal();
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
      const itemSubtotalElement = item.querySelector('[data-item-subtotal]');
      if (itemSubtotalElement) {
        const itemSubtotal = parseFloat(itemSubtotalElement.textContent.replace('S/ ', ''));
        if (!isNaN(itemSubtotal)) {
          subtotal += itemSubtotal;
        }
      }
    });

    const totalComboDiscount = Array.from(this.comboDiscounts.values()).reduce((sum, discount) => sum + discount, 0);

    const subtotalAfterGroupDiscount = subtotal - this.groupDiscountAmount;

    let totalPackDiscount = 0;
    this.packDiscounts.forEach((discount, packId) => {
      totalPackDiscount += discount.amount;
      // You might want to display each pack discount separately in the UI
      // For example:
      // this.addDiscountRow(`Descuento Pack: ${discount.name}`, discount.amount);
    });

    // Apply combo discount, pack discount and percentage discount
    const percentageDiscount = subtotalAfterGroupDiscount * (this.discountPercentage / 100);
    const totalDiscountAmount = totalComboDiscount + percentageDiscount + this.groupDiscountAmount + totalPackDiscount;

    const totalAfterDiscounts = subtotal - totalDiscountAmount;

    // Update discount row
    if (totalDiscountAmount > 0) {
      this.discountRowTarget.classList.remove('hidden');
      this.discountAmountTarget.textContent = `(S/ ${totalDiscountAmount.toFixed(2)})`;

      if (this.groupDiscountNames.length > 0) {
        const discountNamesString = this.groupDiscountNames.join(', ');
        this.discountNameTarget.textContent = `Descuento: ${discountNamesString}`;
      } else {
        this.discountNameTarget.textContent = 'Descuento:';
      }
    } else {
      this.discountRowTarget.classList.add('hidden');
    }

    // Update total
    this.totalTarget.textContent = `S/ ${totalAfterDiscounts.toFixed(2)}`;

    console.log('Subtotal:', subtotal);
    console.log('Total Combo Discount:', totalComboDiscount);
    console.log('Percentage Discount:', percentageDiscount);
    console.log('Group Discount:', this.groupDiscountAmount);
    console.log('Total Discount:', totalDiscountAmount);
    console.log('Total after discounts:', totalAfterDiscounts);

    // Uncomment if you want to dispatch an event with the updated total
    // const event = new CustomEvent('orderTotalUpdated', { detail: { total: totalAfterDiscounts } });
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
      const isDiscounted = item.getAttribute('data-item-already-discounted') === 'true';

      orderItems.push({ id, name, custom_id, quantity, price, subtotal, isLoyaltyFree, isDiscounted });
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

    if (product.isComboItem) {
      const currentQuantity = parseInt(existingItem.querySelector('[data-item-quantity]').textContent);
      const newQuantity = currentQuantity + product.quantity;
      existingItem.setAttribute('data-original-quantity', newQuantity);
    }
    existingItem.setAttribute('data-item-already-discounted', product.already_discounted);
  }

  addComboDiscount(comboId, discountAmount) {
    this.comboDiscounts.set(comboId, discountAmount);
    this.calculateTotal();
  }

  addNewItem(product) {
    console.log('Adding new item:', product);
    const itemElement = document.createElement('div');
    itemElement.classList.add('flex', 'gap-2', 'mb-2', 'items-start', 'cursor-pointer');
    itemElement.setAttribute('data-item-name', product.name);
    itemElement.setAttribute('data-item-sku', product.custom_id);
    itemElement.setAttribute('data-item-original-price', product.price);
    itemElement.setAttribute('data-product-id', product.id);
    itemElement.setAttribute('data-action', 'click->pos--order-items#selectItem');
    itemElement.setAttribute('data-item-already-discounted', product.already_discounted);
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

    if (product.isComboItem) {
      itemElement.setAttribute('data-combo-id', product.comboId);
      itemElement.setAttribute('data-original-quantity', product.quantity);
    }

    this.itemsTarget.appendChild(itemElement);
  }

  clearOrder() {
    console.log('Clearing order...');
    this.itemsTarget.innerHTML = '';
    this.selectedItem = null;
    this.calculateTotal();
  }

  resetGroupDiscountFlags() {
    this.itemsTarget.querySelectorAll('div.flex[data-group-discount="true"]').forEach(item => {
      item.setAttribute('data-item-already-discounted', 'false');
      item.removeAttribute('data-group-discount');
    });
  }
}
