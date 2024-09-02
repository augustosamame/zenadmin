import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ["rangesTable"]

  connect() {
    console.log("CommissionRangeIndexController connected")
  }

  filterByLocation(event) {
    const locationId = event.target.value;

    if (locationId) {
      const url = `/admin/commission_ranges?location_id=${locationId}`;

      get(url, {
        responseKind: "turbo-stream"
      }).catch(error => {
        console.error("There was an error fetching the commission ranges:", error);
      });
    }
  }
}