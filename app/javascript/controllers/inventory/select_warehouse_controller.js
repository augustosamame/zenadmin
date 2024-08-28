import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "menu"]

  connect() {
    console.log("Warehouse controller connected");
  }

  select(event) {
    event.preventDefault();
    const warehouseId = event.currentTarget.dataset.warehouseId;

    fetch(`/admin/set_current_warehouse?id=${warehouseId}`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    }).then(response => {
      if (response.ok) {
        window.location.reload();
      } else {
        console.error("Failed to set current warehouse.");
      }
    });
  }
}