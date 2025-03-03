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
    this.packDiscountInstances = new Map(); // New map to track pack instances
    this.nextPackInstanceId = 1; // Counter for generating unique instance IDs

    document.addEventListener('click', (event) => {
      // Don't deselect if clicking within:
      // 1. Order items
      // 2. Keypad container
      // 3. Keypad buttons
      // 4. Mode buttons (Precio/Cant)
      // 5. Product grid
      const isClickInOrderItems = event.target.closest('[data-pos--order-items-target="items"]');
      const isClickInKeypad = event.target.closest('[data-controller="pos--keypad"]');
      const isClickOnKeypadButton = event.target.closest('.keypad-button');
      const isClickOnModeButton = event.target.closest('[data-action*="pos--keypad#select"]');
      const isClickInProductGrid = event.target.closest('[data-controller="pos--product-grid"]');

      if (!isClickInOrderItems &&
        !isClickInKeypad &&
        !isClickOnKeypadButton &&
        !isClickOnModeButton &&
        !isClickInProductGrid) {
        this.deselectItem();
      }
    });
  }

  disconnect() {
    // Remove the click listener when controller disconnects
    document.removeEventListener('click', this.handleBackgroundClick);
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

      if (item.getAttribute('data-birthday-discount') === 'true') {
        return;
      }
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

  validateNoItemsWithZeroPriceOrZeroQuantity() {
    const items = this.itemsTarget.querySelectorAll('div.flex');
    let invalidItems = [];

    for (const item of items) {
      const price = parseFloat(item.querySelector('.editable-price').textContent.replace('S/ ', ''));
      const quantity = parseInt(item.querySelector('[data-item-quantity]').textContent);
      const productName = item.querySelector('div[style*="flex-basis: 55%"] span.font-medium').textContent.trim();

      if (price === 0 || quantity === 0) {
        invalidItems.push({
          productName,
          price,
          quantity
        });
      }
    }

    if (invalidItems.length > 0) {
      this.showZeroPriceQuantityError(invalidItems);
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

    if (currentPrice < (minAllowedPrice - 0.001)) {
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
    console.log('Adding item:', product);

    // Check for existing item with combo/pack consideration
    const existingItem = Array.from(this.itemsTarget.children).find(item => {
      return item.getAttribute('data-item-sku') === product.custom_id &&
        !item.hasAttribute('data-combo-id') &&
        !item.hasAttribute('data-pack-id');
    });

    if (existingItem && !product.isComboItem && !product.isPackItem) {
      this.updateExistingItem(existingItem, product);
      this.selectItem(existingItem);
    } else {
      this.addNewItem(product);
      this.selectItem({ currentTarget: this.itemsTarget.lastElementChild });
      this.currentMode = 'quantity'; // Default to quantity mode
    }

    const buttonsElement = document.querySelector('[data-controller="pos--buttons"]');
    const buttonsController = this.application.getControllerForElementAndIdentifier(buttonsElement, 'pos--buttons');
    if (buttonsController) {
      // buttonsController.hideDraftButton();
    }

    if (product.isLoyaltyFree) {
      const itemElement = existingItem || this.itemsTarget.lastElementChild;
      itemElement.setAttribute('data-item-loyalty-free', 'true');
    }

    this.calculateTotal();
    this.evaluateGroupDiscount();
    this.saveDraft();
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
    itemElement.setAttribute('data-item-id', Date.now().toString());
    itemElement.setAttribute('data-product-pack-id', product.productPackId || '');  // Add this line
    itemElement.setAttribute('data-product-pack-name', product.productPackName || '');  // Add this line

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
    this.selectItem(itemElement);
  }

  updateExistingItem(existingItem, product) {
    const quantityElement = existingItem.querySelector('[data-item-quantity]');
    const subtotalElement = existingItem.querySelector('[data-item-subtotal]');
    const newQuantity = parseInt(quantityElement.textContent) + product.quantity;
    quantityElement.textContent = newQuantity;
    const price = parseFloat(existingItem.querySelector('.editable-price').textContent.replace('S/ ', ''));
    const newSubtotal = (newQuantity * price).toFixed(2);
    subtotalElement.textContent = `S/ ${newSubtotal}`;

    if (product.isComboItem) {
      const currentQuantity = parseInt(existingItem.querySelector('[data-item-quantity]').textContent);
      const newQuantity = currentQuantity + product.quantity;
      existingItem.setAttribute('data-original-quantity', newQuantity);
    }
  }

  selectItem(eventOrElement) {
    // Remove previous selection
    if (this.selectedItem) {
      this.selectedItem.classList.remove('bg-blue-100', 'dark:bg-blue-900');
      this.selectedItem.classList.add('bg-white', 'dark:bg-gray-700');
    }

    // Handle both event objects and direct element references
    const element = eventOrElement.currentTarget || eventOrElement;
    if (!element) return;

    // Set new selection
    this.selectedItem = element;
    if (this.selectedItem) {
      this.selectedItem.classList.remove('bg-white', 'dark:bg-gray-700');
      this.selectedItem.classList.add('bg-blue-100', 'dark:bg-blue-900');

      // Add a unique identifier if it doesn't exist
      if (!this.selectedItem.dataset.itemId) {
        this.selectedItem.dataset.itemId = Date.now().toString();
      }
    }

    // Mark the first keypress
    this.isFirstKeyPress = true;
    this.startingNewPrice = true;

    const keypadController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="pos--keypad"]'),
      'pos--keypad'
    );

    if (keypadController) {
      keypadController.enableKeyboardListener();
    }
  }

  // Add this method to handle deselection
  deselectItem() {
    if (this.selectedItem) {
      this.selectedItem.classList.remove('bg-blue-100');
      this.selectedItem = null;

      // Disable keyboard listener when deselecting
      const keypadController = this.application.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller="pos--keypad"]'),
        'pos--keypad'
      );

      if (keypadController) {
        keypadController.disableKeyboardListener();
      }
    }
  }

  updateQuantity(value) {
    console.log('updating quantity:', value);
    if (!this.selectedItem) return;

    const quantityElement = this.selectedItem.querySelector('[data-item-quantity]');
    const originalQuantity = parseInt(quantityElement.textContent.trim());
    let currentQuantity = quantityElement.textContent.trim();

    // If the current quantity is '1' (default) and it's the first keypress, replace it with the new digit
    if (currentQuantity === '1' && this.isFirstKeyPress) {
      currentQuantity = value;
      this.isFirstKeyPress = false;
    } else {
      // Append the new digit to the current quantity
      currentQuantity += value;
    }

    // Ensure no leading zeros are present (except when the result is 0)
    const newQuantity = parseInt(currentQuantity, 10);
    currentQuantity = newQuantity.toString();

    // Check if item is part of a pack and quantity is being reduced
    const packId = this.selectedItem.getAttribute('data-pack-id');
    if (packId && newQuantity < originalQuantity) {
      console.log('removing pack discount due to quantity reduction:', this.selectedItem, 'packId:', packId);
      this.removePackDiscount(packId);
    }

    quantityElement.textContent = currentQuantity;

    // Update subtotal
    const price = parseFloat(this.selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''));
    const subtotalElement = this.selectedItem.querySelector('[data-item-subtotal]');
    subtotalElement.textContent = `S/ ${(newQuantity * price).toFixed(2)}`;

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
    this.deselectItem()
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
      // Append the new digit to the current price
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
    const originalQuantity = parseInt(currentQuantity);

    // If it's a single digit or first backspace press
    if (currentQuantity.length === 1) {
      if (this.isFirstKeyPress) {
        currentQuantity = '0';
        this.isFirstKeyPress = false;
      } else {
        // Remove the item on second backspace press when quantity is 0
        this.removeItemFromSelection();
        return;
      }
    } else {
      // Remove the last digit
      currentQuantity = currentQuantity.slice(0, -1);
    }

    const newQuantity = parseInt(currentQuantity);

    // Check if item is part of a pack and quantity is being reduced
    const packId = this.selectedItem.getAttribute('data-pack-id');
    if (packId && newQuantity < originalQuantity) {
      console.log('removing pack discount due to backspace:', this.selectedItem, 'packId:', packId);
      this.removePackDiscount(packId);
    }

    quantityElement.textContent = currentQuantity;

    // Update subtotal
    const price = parseFloat(this.selectedItem.querySelector('.editable-price').textContent.replace('S/ ', ''));
    const subtotalElement = this.selectedItem.querySelector('[data-item-subtotal]');
    subtotalElement.textContent = `S/ ${(newQuantity * price).toFixed(2)}`;

    this.calculateTotal();
    this.evaluateGroupDiscount();
    this.saveDraft();
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
    this.deselectItem();
    this.evaluateGroupDiscount();
    this.calculateTotal();
    this.saveDraft();
  }

  addPackDiscount(packId, discountAmount, packName, productIds) {
    // Generate a unique instance ID for this pack
    const instanceId = `${packId}-${this.nextPackInstanceId++}`;

    this.packDiscounts.set(instanceId, {
      amount: discountAmount,
      name: packName,
      productIds: productIds,
      packId: packId // Store original packId for reference
    });

    // Mark all products in this pack with the instance ID
    productIds.forEach(productId => {
      const item = this.itemsTarget.querySelector(`[data-product-id="${productId}"][data-pack-id="${packId}"]`);
      if (item) {
        item.setAttribute('data-pack-instance', instanceId);
        item.setAttribute('data-item-already-discounted', 'true');
      }
    });

    this.calculateTotal();
  }

  removePackDiscount(packId, instanceId) {
    if (instanceId && this.packDiscounts.has(instanceId)) {
      // Remove specific instance
      this.packDiscounts.delete(instanceId);

      // Reset items for this specific instance
      this.itemsTarget.querySelectorAll(`[data-pack-instance="${instanceId}"]`)
        .forEach(this.resetPackItem.bind(this));
    } else {
      // Remove all instances of this pack (fallback behavior)
      for (const [key, value] of this.packDiscounts.entries()) {
        if (value.packId === packId) {
          this.packDiscounts.delete(key);
          this.itemsTarget.querySelectorAll(`[data-pack-instance="${key}"]`)
            .forEach(this.resetPackItem.bind(this));
        }
      }
    }

    this.calculateTotal();
  }

  resetPackItem(item) {
    item.removeAttribute('data-pack-instance');
    item.removeAttribute('data-pack-id');
    item.setAttribute('data-item-already-discounted', 'false');

    const originalPrice = item.getAttribute('data-item-original-price');
    const priceElement = item.querySelector('.editable-price');
    priceElement.textContent = `S/ ${parseFloat(originalPrice).toFixed(2)}`;

    this.updateSubtotal(item);
  }

  calculateTotal() {
    let subtotal = 0;
    const items = this.itemsTarget.querySelectorAll('div.flex');

    if (items.length === 0) {
      this.discountRowTarget.classList.add('hidden');
      this.totalTarget.textContent = 'S/ 0.00';
      return;
    }

    // Calculate subtotal
    items.forEach(item => {
      const itemSubtotalElement = item.querySelector('[data-item-subtotal]');
      if (itemSubtotalElement) {
        const itemSubtotal = parseFloat(itemSubtotalElement.textContent.replace('S/ ', '')) || 0;
        subtotal += itemSubtotal;
      }
    });

    // Ensure all discount values are numbers
    const totalComboDiscount = Array.from(this.comboDiscounts.values())
      .reduce((sum, discount) => sum + (parseFloat(discount) || 0), 0);

    const groupDiscountAmount = parseFloat(this.groupDiscountAmount) || 0;
    const subtotalAfterGroupDiscount = subtotal - groupDiscountAmount;

    let totalPackDiscount = 0;
    this.packDiscounts.forEach((discount) => {
      totalPackDiscount += parseFloat(discount.amount) || 0;
    });

    // Calculate percentage discount
    const discountPercentage = parseFloat(this.discountPercentage) || 0;
    const percentageDiscount = subtotalAfterGroupDiscount * (discountPercentage / 100);

    // Calculate total discount
    const totalDiscountAmount = (
      totalComboDiscount +
      percentageDiscount +
      groupDiscountAmount +
      totalPackDiscount
    );

    const totalAfterDiscounts = subtotal - totalDiscountAmount;

    // Update discount row
    if (totalDiscountAmount > 0) {
      console.log('totalDiscountAmount:', totalDiscountAmount);
      this.discountRowTarget.classList.remove('hidden');
      this.discountAmountTarget.textContent = `(S/ ${totalDiscountAmount.toFixed(2)})`;

      if (this.groupDiscountNames && this.groupDiscountNames.length > 0) {
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

    // Debug logging
    console.log({
      subtotal,
      totalComboDiscount,
      percentageDiscount,
      groupDiscountAmount,
      totalPackDiscount,
      totalDiscountAmount,
      totalAfterDiscounts
    });
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
      const itemData = {
        id: item.dataset.productId,
        name: item.querySelector('div[style*="flex-basis: 55%"] span.font-medium').textContent.trim(),
        custom_id: item.querySelector('div[style*="flex-basis: 55%"] span.text-sm').textContent.trim(),
        quantity: parseInt(item.querySelector('[data-item-quantity]').textContent.trim()),
        price: parseFloat(item.querySelector('.editable-price').textContent.replace('S/ ', '')),
        subtotal: parseFloat(item.querySelector('[data-item-subtotal]').textContent.replace('S/ ', '')),
        is_loyalty_free: item.hasAttribute('data-loyalty-free-product'),
        is_discounted: item.getAttribute('data-item-already-discounted') === 'true',
        pack_id: item.getAttribute('data-pack-id'),
        productPackId: item.getAttribute('data-product-pack-id'),  // Add this line
        productPackName: item.getAttribute('data-product-pack-name')  // Add this line
      };

      // Add birthday discount data if present
      if (item.hasAttribute('data-birthday-discount')) {
        console.log('Found birthday discount item');
        itemData.birthday_discount = true;
        const imageData = item.getAttribute('data-birthday-image');
        if (imageData) {
          console.log('Found birthday image data, length:', imageData.length);
          itemData.birthday_image = imageData;
        }
      }

      orderItems.push(itemData);
    });

    return {
      total_price: parseFloat(this.totalTarget.textContent.replace('S/ ', '')),
      discount_percentage: this.discountPercentage,
      order_items_attributes: orderItems
    };
  }

  addComboDiscount(comboId, discountAmount) {
    this.comboDiscounts.set(comboId, discountAmount);
    this.calculateTotal();
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

  applyBirthdayDiscount(imageData) {
    if (!this.selectedItem) {
      alert('Por favor seleccione un producto para aplicar el descuento');
      return;
    }

    const discountPercentage = parseInt(document.getElementById('birthday-discount-percentage').dataset.value);
    const priceElement = this.selectedItem.querySelector('.editable-price');
    const originalPrice = parseFloat(this.selectedItem.dataset.itemOriginalPrice);
    const discountedPrice = originalPrice * (1 - discountPercentage / 100);

    priceElement.textContent = `S/ ${discountedPrice.toFixed(2)}`;
    this.selectedItem.setAttribute('data-birthday-discount', 'true');
    this.selectedItem.setAttribute('data-item-already-discounted', 'true');

    // Store the image data with the item
    if (imageData) {
      this.selectedItem.setAttribute('data-birthday-image', imageData);
    }

    this.updateSubtotal(this.selectedItem);
    this.calculateTotal();
  }

  showZeroPriceQuantityError(invalidItems) {
    const productList = invalidItems.map(item =>
      `- ${item.productName}: ${item.price === 0 ? 'Precio S/ 0.00' : ''} ${item.quantity === 0 ? 'Cantidad 0' : ''}`
    ).join('\n');

    const errorMessage = `Los siguientes productos tienen precio o cantidad igual a 0:\n\n${productList}\n\nPor favor, corrija los valores antes de continuar.`;

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

  updatePricesForCustomer(customerId) {
    if (!customerId) return;
    
    const items = this.itemsTarget.querySelectorAll('div.flex');
    if (items.length === 0) return;
    
    const productIds = Array.from(items).map(item => item.getAttribute('data-product-id')).filter(id => id);
    if (productIds.length === 0) return;
    
    // Show loading indicator
    const loadingToast = this.showToast('Actualizando precios...', 'info');
    
    // Fetch updated prices for all products in the cart
    fetch(`/admin/products/customer_prices?customer_id=${customerId}&product_ids=${productIds.join(',')}`)
      .then(response => {
        if (!response.ok) {
          throw new Error('Error fetching customer prices');
        }
        return response.json();
      })
      .then(data => {
        // If no data or empty array, don't proceed with updates
        if (!data || data.length === 0) {
          this.hideToast(loadingToast);
          return;
        }
        
        // Update each item with the new price
        items.forEach(item => {
          const productId = item.getAttribute('data-product-id');
          if (!productId) return;
          
          const productData = data.find(p => p.id.toString() === productId);
          if (!productData) return;
          
          // Skip combo items and already discounted items
          if (item.hasAttribute('data-combo-id') || 
              item.getAttribute('data-item-already-discounted') === 'true' ||
              item.hasAttribute('data-item-loyalty-free')) {
            return;
          }
          
          // Update price and original price
          const priceElement = item.querySelector('.editable-price');
          const quantityElement = item.querySelector('[data-item-quantity]');
          const subtotalElement = item.querySelector('[data-item-subtotal]');
          const quantity = parseInt(quantityElement.textContent);
          
          // Update price display
          priceElement.textContent = `S/ ${productData.price.toFixed(2)}`;
          
          // Update original price attribute for validation
          item.setAttribute('data-item-original-price', productData.price);
          
          // Update subtotal
          subtotalElement.textContent = `S/ ${(quantity * productData.price).toFixed(2)}`;
          
          // Mark as price list item if applicable
          if (productData.price_list_id) {
            item.setAttribute('data-price-list-id', productData.price_list_id);
          } else {
            item.removeAttribute('data-price-list-id');
          }
        });
        
        // Recalculate total
        this.calculateTotal();
        
        // Show success toast
        this.hideToast(loadingToast);
        this.showToast('Precios actualizados según lista de precios del cliente', 'success');
      })
      .catch(error => {
        console.error('Error updating prices:', error);
        this.hideToast(loadingToast);
        this.showToast('Error al actualizar precios', 'error');
      });
  }
  
  resetPricesToDefault() {
    const items = this.itemsTarget.querySelectorAll('div.flex');
    if (items.length === 0) return;
    
    const productIds = Array.from(items)
      .filter(item => item.hasAttribute('data-price-list-id'))
      .map(item => item.getAttribute('data-product-id'))
      .filter(id => id);
    
    if (productIds.length === 0) return;
    
    // Show loading indicator
    const loadingToast = this.showToast('Restaurando precios por defecto...', 'info');
    
    // Fetch default prices for products
    fetch(`/admin/products/default_prices?product_ids=${productIds.join(',')}`)
      .then(response => {
        if (!response.ok) {
          throw new Error('Error fetching default prices');
        }
        return response.json();
      })
      .then(data => {
        // If no data or empty array, don't proceed with updates
        if (!data || data.length === 0) {
          this.hideToast(loadingToast);
          return;
        }
        
        // Update each item with the default price
        items.forEach(item => {
          // Skip items that don't have a price list ID attribute
          if (!item.hasAttribute('data-price-list-id')) return;
          
          const productId = item.getAttribute('data-product-id');
          if (!productId) return;
          
          const productData = data.find(p => p.id.toString() === productId);
          if (!productData) return;
          
          // Skip combo items and already discounted items
          if (item.hasAttribute('data-combo-id') || 
              item.getAttribute('data-item-already-discounted') === 'true' ||
              item.hasAttribute('data-item-loyalty-free')) {
            return;
          }
          
          // Update price and original price
          const priceElement = item.querySelector('.editable-price');
          const quantityElement = item.querySelector('[data-item-quantity]');
          const subtotalElement = item.querySelector('[data-item-subtotal]');
          const quantity = parseInt(quantityElement.textContent);
          
          // Update price display
          priceElement.textContent = `S/ ${productData.price.toFixed(2)}`;
          
          // Update original price attribute for validation
          item.setAttribute('data-item-original-price', productData.price);
          
          // Update subtotal
          subtotalElement.textContent = `S/ ${(quantity * productData.price).toFixed(2)}`;
          
          // Remove price list ID attribute
          item.removeAttribute('data-price-list-id');
        });
        
        // Recalculate total
        this.calculateTotal();
        
        // Show success toast
        this.hideToast(loadingToast);
        this.showToast('Precios restaurados a valores por defecto', 'success');
      })
      .catch(error => {
        console.error('Error resetting prices:', error);
        this.hideToast(loadingToast);
        this.showToast('Error al restaurar precios', 'error');
      });
  }
  
  showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.classList.add('fixed', 'bottom-4', 'right-4', 'p-4', 'rounded', 'shadow-lg', 'z-50');
    
    // Set background color based on type
    if (type === 'success') {
      toast.classList.add('bg-green-500', 'text-white');
    } else if (type === 'error') {
      toast.classList.add('bg-red-500', 'text-white');
    } else {
      toast.classList.add('bg-blue-500', 'text-white');
    }
    
    toast.textContent = message;
    document.body.appendChild(toast);
    
    // Auto-hide after 3 seconds unless it's a loading toast
    if (type !== 'info') {
      setTimeout(() => {
        this.hideToast(toast);
      }, 3000);
    }
    
    return toast;
  }
  
  hideToast(toast) {
    if (toast && toast.parentNode) {
      toast.parentNode.removeChild(toast);
    }
  }
  
}
