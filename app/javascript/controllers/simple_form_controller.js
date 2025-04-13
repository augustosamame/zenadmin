import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    console.log("Simple Form controller connected");
  }

  submitForm(event) {
    // Allow normal form submission
    console.log("Form submission requested");
  }
}
