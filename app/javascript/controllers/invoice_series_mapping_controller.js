import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["invoicer", "invoiceSeries"]

  connect() {
    console.log("invoice_series_mapping_controller connected")
    if (this.hasInvoicerTarget && this.hasInvoiceSeriesTarget) {
      this.updateInvoiceSeries()
    }
  }

  updateInvoiceSeries() {
    const invoicerId = this.invoicerTarget.value
    if (!invoicerId) return

    fetch(`/admin/invoicers/${invoicerId}/invoice_series`)
      .then(response => response.json())
      .then(data => {
        this.invoiceSeriesTarget.innerHTML = data.map(series =>
          `<option value="${series.id}">${series.prefix}</option>`
        ).join('')
      })
  }
}