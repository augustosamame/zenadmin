// app/javascript/controllers/keypad_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['button'];

  connect() {
    console.log('Connected to KeypadController!');
    this.currentMode = 'quantity';
    this.processingKeyboard = false;
    this.boundKeyboardHandler = this.handleKeyboardInput.bind(this);
  }

  enableKeyboardListener() {
    console.log('Enabling keyboard listener');
    this.disableKeyboardListener();
    document.addEventListener('keydown', this.boundKeyboardHandler);
  }

  disableKeyboardListener() {
    console.log('Disabling keyboard listener');
    document.removeEventListener('keydown', this.boundKeyboardHandler);
  }

  handleKeyboardInput(event) {
    // Process keyboard input for both price and quantity modes
    const orderItemsController = this.getOrderItemsController();
    if (!orderItemsController || !orderItemsController.selectedItem) return;

    // Prevent default behavior for these keys when we're handling them
    if (this.isValidInput(event.key)) {
      event.preventDefault();
      event.stopPropagation();
    }

    if (event.key === 'Backspace') {
      if (this.currentMode === 'quantity') {
        orderItemsController.handleBackspaceForQuantity();
      } else if (this.currentMode === 'price') {
        orderItemsController.handleBackspaceForPrice();
      }
    } else if (event.key === '.') {
      if (this.currentMode === 'price') {
        orderItemsController.handleDecimalPoint();
      }
    } else if (this.isNumeric(event.key)) {
      if (this.currentMode === 'quantity') {
        orderItemsController.updateQuantity(event.key);
      } else if (this.currentMode === 'price') {
        orderItemsController.handleKeypadForPrice(event.key);
      }
    }
  }

  handleKeypad(event) {
    const value = event.currentTarget.textContent.trim();
    const orderItemsController = this.getOrderItemsController();

    if (orderItemsController) {
      if (value === '⌫' || value === 'backspace') {
        if (this.currentMode === 'quantity') {
          orderItemsController.handleBackspaceForQuantity();
        } else if (this.currentMode === 'price') {
          orderItemsController.handleBackspaceForPrice();
        }
      } else if (value === '.') {
        if (this.currentMode === 'price') {
          orderItemsController.handleDecimalPoint();
        }
      } else {
        if (orderItemsController.selectedItem) {
          if (this.currentMode === 'quantity') {
            orderItemsController.updateQuantity(value);
          } else if (this.currentMode === 'price') {
            orderItemsController.handleKeypadForPrice(value);
          }
        }
      }
    }
  }

  // Helper methods
  getOrderItemsController() {
    return this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="pos--order-items"]'),
      'pos--order-items'
    );
  }

  isNumeric(key) {
    return /^\d$/.test(key);
  }

  isValidInput(key) {
    return this.isNumeric(key) || key === 'Backspace' || key === '.';
  }

  disconnect() {
    this.disableKeyboardListener();
  }

  selectQuantityMode() {
    this.currentMode = 'quantity';
    this.clearModeSelection();
    const quantityButton = document.getElementById('quantity-mode-button');
    console.log('Quantity Button:', quantityButton);
    quantityButton.classList.add('bg-blue-100');
    quantityButton.style.backgroundColor = '#bfdbfe'; // Tailwind's blue-100 hex color as a fallback
  }

  selectPriceMode() {
    this.currentMode = 'price';
    this.clearModeSelection();
    const priceButton = document.getElementById('price-mode-button');
    console.log('Price Button:', priceButton);
    priceButton.classList.add('bg-blue-100');
    priceButton.style.backgroundColor = '#bfdbfe'; // Tailwind's blue-100 hex color as a fallback
  }

  clearModeSelection() {
    const buttons = document.querySelectorAll('[data-action="click->pos--keypad#selectQuantityMode"], [data-action="click->pos--keypad#selectPriceMode"]');
    buttons.forEach(button => {
      button.classList.remove('bg-blue-100');
      button.style.backgroundColor = ''; // Clear any inline style
    });
  }

  highlightSelectedButton(button) {
    // Remove highlight from all buttons
    this.buttonTargets.forEach(btn => btn.classList.remove('bg-blue-100'));

    // Add highlight to the selected button
    button.classList.add('bg-blue-100');
  }
}