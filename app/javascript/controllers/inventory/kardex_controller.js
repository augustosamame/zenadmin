import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table", "productSelect", "warehouseSelect"]

  connect() {
    console.log("KardexController connected")
    if (this.tableTarget) {
      console.log("Table target exists")
    }
    // Automatically fetch movements if both product and warehouse are preselected
    if (this.productSelectTarget.value && this.warehouseSelectTarget.value) {
      this.fetchMovements()
    }
  }

  //check if table target exists


  fetchMovements() {
    const productId = this.productSelectTarget.value
    const warehouseId = this.warehouseSelectTarget.value

    if (productId) {
      const url = new URL('/admin/inventory/fetch_kardex_movements', window.location.origin)
      url.searchParams.append('product_id', productId)
      if (warehouseId) {
        url.searchParams.append('warehouse_id', warehouseId)
      }

      console.log("Fetching movements for product:", productId, "and warehouse:", warehouseId)

      fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        }
      })
        .then(response => response.text())
        .then(html => {
          this.tableTarget.innerHTML = html
        })
        .catch(error => console.error('Error fetching movements:', error))
    }
  }
}