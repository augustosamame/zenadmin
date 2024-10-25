import { Controller } from "@hotwired/stimulus"
import axios from 'axios'

export default class extends Controller {
  static targets = ["content"]

  connect() {
    console.log("LoyaltyInfoController connected")
    this.setupLoyaltyInfoListener()
  }

  setupLoyaltyInfoListener() {
    document.addEventListener('customer-selected', this.handleCustomerSelected.bind(this))
  }

  handleCustomerSelected(event) {
    console.log('Customer selected event received', event.detail)
    const userId = event.detail.userId
    this.loadLoyaltyInfo(userId)
  }

  loadLoyaltyInfo(userId) {
    console.log('Loading loyalty info for user', userId)
    axios.get(`/admin/users/${userId}/loyalty_info`)
      .then(response => {
        console.log('Loyalty info received', response.data)
        if (response.data) {
          this.renderLoyaltyInfo(response.data)
        } else {
          // generic customer
          this.clearLoyaltyInfo()
        }
      })
      .catch(error => {
        console.error('Error loading loyalty info:', error)
        this.contentTarget.innerHTML = '<p>Error loading loyalty information.</p>'
      })
  }

  clearLoyaltyInfo() {
    console.log('Clearing loyalty info')
    this.contentTarget.innerHTML = ''
  }

  renderLoyaltyInfo(data) {
    console.log('Rendering loyalty info', data);
    const pendingTierSuffix = data.tier_active ? '' : ' (falta 1 día para que esté activo)';
    
    this.contentTarget.innerHTML = `
      <div class="flex">
        <div class="w-2/3 pr-4">
          <p><strong>Rango actual:</strong> ${data.current_tier_name}${pendingTierSuffix}</p>
          ${this.renderPendingTierInfo(data)}
          <p><strong>Progreso al siguiente rango:</strong> ${data.progress_to_next_tier}</p>
          ${this.renderDiscountInfoText(data)}
          ${this.renderFreeProductInfoText(data)}
        </div>
        <div class="w-1/3">
          ${this.renderDiscountButton(data)}
          ${this.renderFreeProductButton(data)}
        </div>
      </div>
    `;
  }

  renderPendingTierInfo(data) {
    if (data.pending_tier_name) {
      return `
        <p><strong>Rango pendiente:</strong> ${data.pending_tier_name}</p>
        <p><strong>Descuento pendiente:</strong> ${data.pending_tier_discount_percentage}%</p>
        ${this.renderPendingFreeProductInfo(data)}
      `;
    }
    return '';
  }

  renderPendingFreeProductInfo(data) {
    return data.pending_tier_free_product
      ? `<p><strong>Producto Gratis Pendiente:</strong> ${data.pending_tier_free_product.name}</p>`
      : '';
  }

  renderDiscountInfoText(data) {
    return data.discount_percentage
      ? `<p><strong>Descuento Disponible:</strong> ${data.discount_percentage}%</p>`
      : '';
  }

  renderFreeProductInfoText(data) {
    return data.free_product
      ? `<p><strong>Producto Gratis Disponible:</strong> ${data.free_product.name}</p>`
      : '';
  }

  renderDiscountButton(data) {
    if (!data.discount_percentage) return '';
    
    const disabledClass = data.tier_active ? '' : 'opacity-50 cursor-not-allowed';
    const disabledAttr = data.tier_active ? '' : 'disabled';
    
    return `
      <button class="btn btn-primary w-full mb-2 ${disabledClass}" 
              data-action="click->pos--loyalty-info#applyDiscount" 
              data-discount="${data.discount_percentage}"
              ${disabledAttr}>
        Aplicar Descuento
      </button>
    `;
  }

  renderFreeProductButton(data) {
    if (!data.free_product) return '';
    
    const disabledClass = data.tier_active ? '' : 'opacity-50 cursor-not-allowed';
    const disabledAttr = data.tier_active ? '' : 'disabled';
    
    return `
      <button class="btn btn-secondary w-full ${disabledClass}" 
              data-action="click->pos--loyalty-info#addFreeProduct" 
              data-product-id="${data.free_product.id}" 
              data-product-name="${data.free_product.name}" 
              data-product-custom-id="${data.free_product.custom_id}"
              ${disabledAttr}>
        Agregar Producto Gratis
      </button>
    `;
  }

  applyDiscount(event) {
    const discountPercentage = parseFloat(event.currentTarget.dataset.discount)
    const customEvent = new CustomEvent('apply-loyalty-discount', {
      detail: { discountPercentage },
      bubbles: true
    })
    this.element.dispatchEvent(customEvent)
  }

  addFreeProduct(event) {
    const productId = event.currentTarget.dataset.productId
    const productName = event.currentTarget.dataset.productName
    const productCustomId = event.currentTarget.dataset.productCustomId
    const customEvent = new CustomEvent('add-loyalty-free-product', {
      detail: { productId, productName, productCustomId },
      bubbles: true
    })
    this.element.dispatchEvent(customEvent)
  }
}
