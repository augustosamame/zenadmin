import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["warehouseSelect", "productSelect"]
  static values = { url: String }

  connect() {
    this.initializeSelects()
    if (this.hasWarehouseSelectTarget) {
      this.fetchMovements()
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

    const url = new URL(this.urlValue, window.location.origin)

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
        this.initializeSelects()
        this.reinitializeDatatable()
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