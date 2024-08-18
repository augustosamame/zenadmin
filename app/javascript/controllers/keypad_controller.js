import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['display']

  enterNumber(event) {
    // Append number to the display
    this.displayTarget.value += event.target.textContent
  }

  enterDecimal(event) {
    if (!this.displayTarget.value.includes('.')) {
      this.displayTarget.value += '.'
    }
  }

  clear() {
    this.displayTarget.value = ''
  }

  selectQty() {
    // Handle quantity selection logic
  }

  selectDiscount() {
    // Handle discount selection logic
  }

  selectPrice() {
    // Handle price selection logic
  }
}