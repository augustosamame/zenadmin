import { Controller } from "@hotwired/stimulus"
import axios from "axios"

export default class extends Controller {
  static targets = ["stock", "actualStock", "matchButton", "adjustmentType", "row", "processButton"]
  static values = { warehouseId: String }

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

  getSelectedUserId() {
    return document.querySelector('select[name="responsible_user_id"]').value
  }

  async processInventory(event) {
    const userId = this.element.querySelector('select[name="responsible_user_id"]').value
    if (!userId) {
      alert("Por favor seleccione un usuario responsable")
      return
    }

    const differences = this.rowTargets
      .filter(row => {
        const stock = parseInt(row.querySelector("[data-inventory-target='stock']").textContent.trim(), 10)
        const actualStockInput = row.querySelector("[data-inventory-target='actualStock']")
        const adjustmentTypeSelect = row.querySelector("[data-inventory-target='adjustmentType']")

        if (!actualStockInput.value) {
          alert("Debe llenar todos los campos de stock físico")
          return false
        }

        const actualStock = parseInt(actualStockInput.value, 10)
        if (stock !== actualStock) {
          const productId = row.dataset.productId
          const adjustmentType = adjustmentTypeSelect.value

          return {
            warehouse_id: this.element.dataset.warehouseId,
            product_id: productId,
            stock_qty: stock,
            actual_qty: actualStock,
            adjustment_type: adjustmentType,
            responsible_user_id: userId
          }
        }

        return false
      })
      .map(row => {
        const stock = parseInt(row.querySelector("[data-inventory-target='stock']").textContent.trim(), 10)
        const actualStockInput = row.querySelector("[data-inventory-target='actualStock']")
        const adjustmentTypeSelect = row.querySelector("[data-inventory-target='adjustmentType']")

        if (!actualStockInput.value) {
          alert("Debe llenar todos los campos de stock físico")
          return false
        }

        const actualStock = parseInt(actualStockInput.value, 10)
        if (stock !== actualStock) {
          const productId = row.dataset.productId
          const adjustmentType = adjustmentTypeSelect.value

          return {
            warehouse_id: this.element.dataset.warehouseId,
            product_id: productId,
            stock_qty: stock,
            actual_qty: actualStock,
            adjustment_type: adjustmentType,
            responsible_user_id: userId
          }
        }

        return false
      })

    // Add results object back
    const results = {
      warehouse_id: this.element.dataset.warehouseId,
      differences_count: differences.length
    }

    axios.post('/admin/inventory/periodic_inventories', 
      { 
        differences, 
        results,
        responsible_user_id: userId 
      }, 
      {
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      }
    )
      .then(response => {
        this.processButtonTarget.classList.add("hidden")
        document.getElementById('inventory-results').innerHTML = response.data
      })
      .catch(error => {
        console.error('Error processing inventory:', error)
      })
  }
}