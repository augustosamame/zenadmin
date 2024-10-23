// app/javascript/controllers/discount_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["globalFields", "groupFields"]

  connect() {
    this.toggleDiscountFields()
    document.addEventListener("turbo:render", this.reconnect.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.reconnect.bind(this))
  }

  reconnect() {
    this.toggleDiscountFields()
  }

  toggleDiscountFields() {
    const discountType = this.element.querySelector('#discount_discount_type').value
    if (discountType === 'type_global') {
      this.globalFieldsTarget.classList.remove('hidden')
      this.groupFieldsTarget.classList.add('hidden')
    } else if (discountType === 'type_group') {
      this.globalFieldsTarget.classList.add('hidden')
      this.groupFieldsTarget.classList.remove('hidden')
    }
  }
}