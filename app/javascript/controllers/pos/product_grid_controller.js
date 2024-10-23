import { Controller } from '@hotwired/stimulus'
import axios from 'axios'
import debounce from 'lodash/debounce'

export default class extends Controller {
  static targets = ['search', 'product', 'productContainer', 'clearButton']

  connect() {
    console.log('Connected to the POS product grid controller!')
    this.searchTarget.focus()
    this.loadProducts()
    this.updateClearButtonVisibility()
    this.debouncedSearch = debounce(this.performSearch, 300)
    this.beepSound = document.getElementById('barcode-add-sound')
  }

  searchProducts() {
    const query = this.searchTarget.value.trim()
    // Trim the query and check again
    
    if (query.length >= 7) {
      console.log('Searching for exact match:', query)
      this.findExactMatch(query)
    } else {
      console.log('Performing regular search:', query)
      this.debouncedSearch(query)
    }

    this.updateClearButtonVisibility()
  }

  performSearch = (query) => {
    this.loadProducts(query)
  }

  findExactMatch(query) {
    axios.get('/admin/products/search', { params: { query: query, exact_match: true } })
      .then(response => {
        if (response.data.length === 1) {
          // If exactly one product is found, add it to the order
          this.addProductToOrder(response.data[0])
          this.clearSearch()
          this.beepSound.play()
        } else {
          // If no exact match or multiple matches, perform a regular search
          this.renderProducts(response.data)
        }
      })
      .catch(error => {
        console.error('There was an error fetching the product:', error)
      })
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

  clearSearch() {
    this.searchTarget.value = ''
    this.loadProducts()
    this.updateClearButtonVisibility()
    this.searchTarget.focus()
  }

  updateClearButtonVisibility() {
    if (this.searchTarget.value) {
      this.clearButtonTarget.classList.remove('hidden')
    } else {
      this.clearButtonTarget.classList.add('hidden')
    }
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
        <div class="flex justify-between text-sm">
          ${product.original_price !== product.discounted_price
                ? `<span class="text-red-500">
                <del class="text-gray-500">S/ ${product.original_price.toFixed(2)}</del>
                S/ ${product.discounted_price.toFixed(2)}
              </span>`
                : `<span class="text-gray-500">S/ ${product.price.toFixed(2)}</span>`
              }
          <span class="text-gray-500">Stock: ${product.stock}</span>
        </div>
      `;

      productElement.addEventListener('click', () => this.addProductToOrder(product))
      this.productContainerTarget.appendChild(productElement)
    })
  }

  addProductToOrder(item) {
    // Find the element that contains the pos--order-items controller
    const orderItemsContainer = document.querySelector('[data-controller="pos--order-items"]');
    console.log('Order Items Container:', orderItemsContainer);

    // Get the controller instance
    const orderItemsController = this.application.getControllerForElementAndIdentifier(orderItemsContainer, 'pos--order-items');

    console.log('Order Items Controller:', orderItemsController);

    if (item.type === "Product") {
      // Handle regular product
      orderItemsController.addItem({
        id: item.id,
        custom_id: item.custom_id,
        name: item.name,
        price: item.price,
        already_discounted: item.discounted_price !== item.original_price,
        quantity: 1,
        isComboItem: false
      });
    } else if (item.type === "ComboProduct") {
      // Handle combo product
      const comboDetails = item.combo_details;
      const comboId = item.id;

      // Add each product in the combo
      comboDetails.products.forEach(product => {
        orderItemsController.addItem({
          id: product.id,
          custom_id: product.custom_id,
          name: product.name,
          price: product.discounted_price,
          already_discounted: true,
          quantity: product.quantity,
          isComboItem: true,
          comboId: comboId
        });
      });

      // Calculate and apply the discount
      const discountAmount = comboDetails.discount;
      if (discountAmount > 0) {
      orderItemsController.addComboDiscount(comboId, discountAmount);
      }
    }
  }
}