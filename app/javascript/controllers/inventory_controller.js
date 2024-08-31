import { Controller } from "@hotwired/stimulus"
import axios from "axios"

export default class extends Controller {
  static targets = ["stock", "actualStock", "matchButton", "adjustmentType", "row", "processButton"]

  connect() {
    console.log("InventoryController connected")
  }

  matchStock(event) {
    const button = event.currentTarget
    const row = button.closest("tr")
    const stock = parseInt(row.querySelector("[data-inventory-target='stock']").textContent.trim(), 10)
    const actualStockInput = row.querySelector("[data-inventory-target='actualStock']")
    const adjustmentTypeSelect = row.querySelector("[data-inventory-target='adjustmentType']")

    actualStockInput.value = stock

    // Check if stock and actual stock match
    if (stock !== parseInt(actualStockInput.value, 10)) {
      adjustmentTypeSelect.classList.remove("hidden")
    } else {
      adjustmentTypeSelect.classList.add("hidden")
    }
  }

  checkStock(event) {
    const input = event.currentTarget
    const row = input.closest("tr")
    const stock = parseInt(row.querySelector("[data-inventory-target='stock']").textContent.trim(), 10)
    const adjustmentTypeSelect = row.querySelector("[data-inventory-target='adjustmentType']")

    // Check if stock and actual stock match
    if (stock !== parseInt(input.value, 10)) {
      adjustmentTypeSelect.classList.remove("hidden")
    } else {
      adjustmentTypeSelect.classList.add("hidden")
    }
  }

  processInventory(event) {
    event.preventDefault()

    const rows = this.rowTargets
    const differences = []

    for (const row of rows) {
      const stock = parseInt(row.querySelector("[data-inventory-target='stock']").textContent.trim(), 10)
      const actualStockInput = row.querySelector("[data-inventory-target='actualStock']")
      const adjustmentTypeSelect = row.querySelector("[data-inventory-target='adjustmentType']")

      if (!actualStockInput.value) {
        alert("Debe llenar todos los campos de stock físico")
        return
      }

      const actualStock = parseInt(actualStockInput.value, 10)
      if (stock !== actualStock) {
        const productId = row.dataset.productId
        const adjustmentType = adjustmentTypeSelect.value

        differences.push({
          warehouse_id: this.element.dataset.warehouseId,
          product_id: productId,
          stock_qty: stock,
          actual_qty: actualStock,
          adjustment_type: adjustmentType
        })
      }
    }

    // add a results object to the differences array
    const results = {
      warehouse_id: this.element.dataset.warehouseId,
      differences_count: differences.length
    }

    axios.post('/admin/inventory/periodic_inventories', { differences, results }, {
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
    .then(response => {
      // Handle the response, e.g., show the table of stock transfers created
      this.processButtonTarget.classList.add("hidden")
      document.getElementById('inventory-results').innerHTML = response.data
    })
    .catch(error => {
      console.error('Error processing inventory:', error)
    })
  }
}