// app/javascript/controllers/keypad_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['button'];

  connect() {
    console.log('Connected to KeypadController!');
    this.currentMode = 'quantity';
  }

  handleKeypad(event) {
    const value = event.currentTarget.textContent.trim();
    const orderItemsController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="pos--order-items"]'),
      'pos--order-items'
    );

    if (orderItemsController) {
      if (value === '⌫' || value === 'backspace') {
        if (this.currentMode === 'quantity') {
          orderItemsController.handleBackspaceForQuantity();
        } else if (this.currentMode === 'price') {
          orderItemsController.handleBackspaceForPrice();
        }
      } else {
        if (orderItemsController.selectedItem) { // Ensure an item is selected
          if (this.currentMode === 'quantity') {
            orderItemsController.updateQuantity(value);
          } else if (this.currentMode === 'price') {
            orderItemsController.handleKeypadForPrice(value);
          }
        }
      }
    }
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