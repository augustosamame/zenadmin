import { Controller } from "@hotwired/stimulus"
import axios from "axios"

export default class extends Controller {
  static targets = ["menu", "trigger"]

  connect() {
    console.log("SelectLocationDropdownController connected")
  }

  toggle(event) {
    event.preventDefault()
    this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  select(event) {
    event.preventDefault()
    const locationId = event.currentTarget.dataset.locationId
    const locationName = event.currentTarget.textContent.trim()

    // Update the button label
    this.triggerTarget.querySelector('span').textContent = locationName || "Todas"

    // Hide the menu
    this.menuTarget.classList.add("hidden")

    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

    // Send AJAX request to set the location
    axios.post("/admin/dashboards/set_location", { location_id: locationId }, {
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => {
      Turbo.renderStreamMessage(response.data)
    })
    .catch(error => {
      console.error("Error setting location:", error)
    })
  }
}