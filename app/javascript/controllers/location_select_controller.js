import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    console.log("LocationSelectController connected")
  }

  submit(event) {
    // Get the closest form element
    const form = this.element.closest('form')
    if (form) {
      form.submit()
    }
  }
}