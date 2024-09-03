import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["warehouseSelect", "productSelect", "movementsContainer"]

  connect() {
    if (this.hasWarehouseSelectTarget) {
      this.fetchMovements()
    }
  }

  fetchMovements() {
    const productId = this.productSelectTarget.value
    const warehouseId = this.hasWarehouseSelectTarget ? this.warehouseSelectTarget.value : null

    if (!productId) return

    console.log('url', this.movementsContainerTarget.dataset.url)
    const url = new URL(this.movementsContainerTarget.dataset.url, window.location.origin)

    url.searchParams.set("product_id", productId)
    if (warehouseId) {
      url.searchParams.set("warehouse_id", warehouseId)
    }

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => {
        Turbo.renderStreamMessage(html)
      })
  }
}