import { Controller } from '@hotwired/stimulus'
import axios from 'axios'

export default class extends Controller {
  static targets = ['search', 'product', 'productContainer']

  connect() {
    console.log('Connected to the POS product grid controller!')
    this.searchTarget.focus()
    this.loadProducts()
  }

  searchProducts() {
    const query = this.searchTarget.value
    this.loadProducts(query)
  }

  loadProducts(query = '') {
    axios.get('/admin/products/search', { params: { query: query } })
      .then(response => {
        this.renderProducts(response.data)
      })
      .catch(error => {
        console.error('There was an error fetching the products:', error)
      })
  }

  renderProducts(products) {
    if (!this.hasProductContainerTarget) {
      console.error('Product container target is not defined')
      return
    }

    this.productContainerTarget.innerHTML = ''

    products.forEach(product => {
      const productElement = document.createElement('div')
      productElement.classList.add('p-2', 'bg-white', 'rounded', 'shadow', 'dark:bg-gray-800', 'cursor-pointer')

      // Centering the image within the container
      productElement.innerHTML = `
        <div class="flex justify-center">
          <img src="${product.image}" alt="${product.name}" class="object-cover h-24 w-24 mb-2">
        </div>
        <span class="block text-sm">${product.custom_id}</span>
        <span class="block text-sm">${product.name}</span>
        <div class="flex justify-between text-sm text-gray-500">
          <span>S/ ${product.price}</span>
          <span>Stock: ${product.stock}</span>
        </div>
      `;

      productElement.addEventListener('click', () => this.addProductToOrder(product))
      this.productContainerTarget.appendChild(productElement)
    })
  }

  addProductToOrder(product) {
    // Find the element that contains the pos--order-items controller
    const orderItemsContainer = document.querySelector('[data-controller="pos--order-items"]');
    console.log('Order Items Container:', orderItemsContainer);

    // Get the controller instance
    const orderItemsController = this.application.getControllerForElementAndIdentifier(orderItemsContainer, 'pos--order-items');

    console.log('Order Items Controller:', orderItemsController);

    // Call the addItem method on the orderItemsController
    orderItemsController.addItem({
      id: product.id,
      custom_id: product.custom_id,
      name: product.name,
      price: product.price,
      quantity: 1
    });
  }
}