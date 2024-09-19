import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    console.log("Loyalty Tier form controller connected")
  }

  // Add any additional interactions if needed
}