import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["warehouseSelect", "productSelect"]
  static values = { url: String }

  connect() {
    console.log("Kardex controller connected!")
    this.initializeSelects()
    
    // Get product_id and warehouse_id from URL parameters
    const urlParams = new URLSearchParams(window.location.search)
    const productIdParam = urlParams.get('product_id')
    const warehouseIdParam = urlParams.get('warehouse_id')
    
    console.log("URL params:", { productIdParam, warehouseIdParam })
    
    // If both parameters exist in the URL, fetch movements directly
    if (productIdParam && warehouseIdParam) {
      console.log("Both parameters exist, fetching movements directly")
      this.fetchMovementsWithParams(productIdParam, warehouseIdParam)
    }
  }

  initializeSelects() {
    this.productSelect = this.element.querySelector('#select_product_id')
    this.warehouseSelect = this.element.querySelector('#select_warehouse_id')

    if (this.productSelect) {
      this.productSelect.addEventListener('change', () => this.fetchMovements())
    }
    if (this.warehouseSelect) {
      this.warehouseSelect.addEventListener('change', () => this.fetchMovements())
    }
  }

  fetchMovements() {
    const productId = this.productSelect ? this.productSelect.value : null
    const warehouseId = this.warehouseSelect ? this.warehouseSelect.value : null

    if (!productId) return

    this.fetchMovementsWithParams(productId, warehouseId)
  }

  fetchMovementsWithParams(productId, warehouseId) {
    const url = new URL(this.urlValue, window.location.origin)

    url.searchParams.set("product_id", productId)
    if (warehouseId) {
      url.searchParams.set("warehouse_id", warehouseId)
    }

    console.log("Fetching movements with URL:", url.toString())

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => {
        Turbo.renderStreamMessage(html)
        this.initializeSelects()
        this.reinitializeDatatable()
      })
      .catch(error => {
        console.error("Error fetching kardex movements:", error)
      })
  }

  reinitializeDatatable() {
    const datatableElement = document.getElementById('kardex-table')
    if (datatableElement) {
      // Assuming you're using a library like DataTables
      if ($.fn.DataTable.isDataTable(datatableElement)) {
        $(datatableElement).DataTable().destroy()
      }
      // Reinitialize the datatable
      const datatableController = this.application.getControllerForElementAndIdentifier(datatableElement, 'datatable')
      if (datatableController) {
        datatableController.initialize()
      } else {
        console.error('Datatable controller not found')
      }
    } else {
      console.error('Datatable element not found')
    }
  }
}