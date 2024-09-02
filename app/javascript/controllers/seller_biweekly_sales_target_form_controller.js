import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sellerSelect", "referencePeriods", "referenceData", "salesTarget", "targetCommission"]

  connect() {
    if (this.hasSellerSelectTarget) {
      this.sellerSelectTarget.addEventListener('change', this.loadSellerData.bind(this))
    }
    if (this.hasReferencePeriodsTarget) {
      this.referencePeriodsTarget.addEventListener('change', this.loadSellerData.bind(this))
    }
  }

  loadSellerData() {
    const sellerId = this.sellerSelectTarget.value
    const referencePeriods = this.referencePeriodsTarget.value

    if (sellerId) {
      fetch(`/admin/seller_biweekly_sales_targets/seller_data?seller_id=${sellerId}&reference_periods=${referencePeriods}`)
        .then(response => response.json())
        .then(data => {
          this.updateReferenceData(data)
          this.clearTargetInformation()
        })
    } else {
      this.clearReferenceData()
      this.clearTargetInformation()
    }
  }

  updateReferenceData(data) {
    let html = '<table class="min-w-full divide-y divide-gray-200">'
    html += '<thead class="bg-gray-50"><tr>'
    html += '<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Period</th>'
    html += '<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sales</th>'
    html += '<th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location Sales</th>'
    html += '</tr></thead><tbody>'

    data.forEach((period, index) => {
      const rowClass = index % 2 === 0 ? 'bg-white' : 'bg-gray-50'
      html += `<tr class="${rowClass}">`
      html += `<td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${period.year_month_period}</td>`
      html += `<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${this.formatCurrency(period.sales)}</td>`
      html += `<td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${this.formatCurrency(period.location_sales)}</td>`
      html += '</tr>'
    })

    html += '</tbody></table>'
    this.referenceDataTarget.innerHTML = html
  }

  clearReferenceData() {
    this.referenceDataTarget.innerHTML = ''
  }

  clearTargetInformation() {
    this.salesTargetTarget.value = ''
    this.targetCommissionTarget.value = ''
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'PEN' }).format(amount / 100)
  }
}