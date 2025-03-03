import { Controller } from '@hotwired/stimulus'
import axios from 'axios'
import debounce from 'lodash/debounce'

export default class extends Controller {
  static targets = ['search', 'product', 'productContainer', 'clearButton', 'priceListNotification']

  connect() {
    console.log('Connected to the POS product grid controller!')
    this.searchTarget.focus()
    this.loadProducts()
    this.updateClearButtonVisibility()
    this.debouncedSearch = debounce(this.performSearch, 300)
    this.beepSound = document.getElementById('barcode-add-sound')
    
    // Listen for customer selection events
    document.addEventListener('customer-selected', this.handleCustomerSelected.bind(this))
    document.addEventListener('clear-selected-user', this.handleCustomerCleared.bind(this))
    
    // Initialize selected customer ID and price list info
    this.selectedCustomerId = null
    this.activePriceListId = null
    this.activePriceListName = null
    
    // Hide price list notification initially
    if (this.hasPriceListNotificationTarget) {
      this.priceListNotificationTarget.classList.add('hidden')
    }
  }
  
  disconnect() {
    // Clean up event listeners when controller disconnects
    document.removeEventListener('customer-selected', this.handleCustomerSelected.bind(this))
    document.removeEventListener('clear-selected-user', this.handleCustomerCleared.bind(this))
  }
  
  handleCustomerSelected(event) {
    console.log('Customer selected in product grid:', event.detail)
    this.selectedCustomerId = event.detail.userId
    this.activePriceListId = event.detail.priceListId
    
    // If price list ID is present, fetch the price list name
    if (this.activePriceListId && this.hasPriceListNotificationTarget) {
      this.fetchPriceListName(this.activePriceListId)
    } else {
      // Hide notification if no price list
      if (this.hasPriceListNotificationTarget) {
        this.priceListNotificationTarget.classList.add('hidden')
      }
    }
    
    // Reload products with the selected customer to get correct pricing
    this.loadProducts(this.searchTarget.value.trim())
  }
  
  fetchPriceListName(priceListId) {
    axios.get(`/admin/price_lists/${priceListId}.json`)
      .then(response => {
        this.activePriceListName = response.data.name
        this.updatePriceListNotification()
      })
      .catch(error => {
        console.error('Error fetching price list details:', error)
        this.activePriceListName = null
        if (this.hasPriceListNotificationTarget) {
          this.priceListNotificationTarget.classList.add('hidden')
        }
      })
  }
  
  updatePriceListNotification() {
    if (!this.hasPriceListNotificationTarget || !this.activePriceListName) return
    
    this.priceListNotificationTarget.innerHTML = `
      <div class="flex items-center">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5 mr-2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9.568 3H5.25A2.25 2.25 0 003 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 005.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 009.568 3z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 6h.008v.008H6V6z" />
        </svg>
        <span>Lista de Precios Activa: <strong>${this.activePriceListName}</strong></span>
      </div>
    `
    this.priceListNotificationTarget.classList.remove('hidden')
  }
  
  handleCustomerCleared() {
    console.log('Customer cleared in product grid')
    this.selectedCustomerId = null
    this.activePriceListId = null
    this.activePriceListName = null
    
    // Hide price list notification
    if (this.hasPriceListNotificationTarget) {
      this.priceListNotificationTarget.classList.add('hidden')
    }
    
    // Reload products without customer to reset pricing
    this.loadProducts(this.searchTarget.value.trim())
  }

  searchProducts() {
    const query = this.searchTarget.value.trim()
    // Trim the query and check again

    if (query.length >= 7 && query.startsWith('PRO')) {
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
    const params = { 
      query: query, 
      exact_match: true
    }
    
    // Add customer_id to params if a customer is selected
    if (this.selectedCustomerId) {
      params.customer_id = this.selectedCustomerId
    }
    
    axios.get('/admin/products/search', { params: params })
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
    const params = { query: query }
    
    // Add customer_id to params if a customer is selected
    if (this.selectedCustomerId) {
      params.customer_id = this.selectedCustomerId
    }
    
    axios.get('/admin/products/search', { params: params })
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
          <img src="${product.image || ''}" alt="${product.name || ''}" class="object-cover mb-2 w-24 h-24">
        </div>
        <span class="block text-sm">${product.custom_id || ''}</span>
        <span class="block text-sm">${product.name || ''}</span>
        <div class="flex justify-between text-sm">
          ${product.original_price !== product.discounted_price
          ? `<span class="text-red-500">
                <del class="text-gray-500">S/ ${(product.original_price || 0).toFixed(2)}</del>
                S/ ${(product.discounted_price || 0).toFixed(2)}
              </span>`
          : `<span class="text-gray-500">S/ ${(product.price || 0).toFixed(2)}</span>`
        }
          <span class="text-gray-500">Stock: ${product.stock || 0}</span>
        </div>
      `;

      productElement.addEventListener('click', () => this.addProductToOrder(product))
      this.productContainerTarget.appendChild(productElement)
    })
  }

  addProductToOrder(item) {
    const orderItemsContainer = document.querySelector('[data-controller="pos--order-items"]');
    const orderItemsController = this.application.getControllerForElementAndIdentifier(
      orderItemsContainer,
      'pos--order-items'
    );

    if (!orderItemsController) {
      console.error('Order Items Controller not found');
      return;
    }

    if (item.type === "Product") {
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
        console.log('Product:', product);
        orderItemsController.addItem({
          id: product.id,
          custom_id: product.custom_id,
          name: product.name,
          price: product.regular_price,
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
    } else if (item.type === "ProductPack") {
      // Handle product pack
      this.openProductPackModal(item, orderItemsController);
    }
  }

  openProductPackModal(pack, orderItemsController) {
    const customModal = document.querySelector('[data-controller="custom-modal"]');
    const customModalController = this.application.getControllerForElementAndIdentifier(customModal, 'custom-modal');

    // First, open the modal with a loading message
    customModalController.openWithContent('Seleccionar Productos del Pack', 'Cargando opciones de productos...', []);
    customModalController.open();

    // Then fetch the product options and update the modal content
    this.createProductPackModalContent(pack)
      .then(modalContent => {
        // Open a new modal with the fetched content
        customModalController.openWithContent('Seleccionar Productos del Pack', modalContent, [
          {
            label: 'Agregar',
            classes: 'btn btn-primary add-pack-button',
            action: 'click->custom-modal#close'
          },
          {
            label: 'Cancelar',
            classes: 'btn btn-secondary',
            action: 'click->custom-modal#close'
          }
        ]);

        // Add a click event listener to the "Agregar" button
        const addButton = customModal.querySelector('.add-pack-button');
        if (addButton) {
          addButton.addEventListener('click', (event) => this.addProductPackToOrder(event));
        }

        // Initialize TomSelect for each dropdown using the select controller
        pack.pack_details.items.forEach((item, index) => {
          const selectElement = document.getElementById(`pack-item-${index}`);
          if (selectElement) {
            selectElement.setAttribute('data-controller', 'select');
            selectElement.setAttribute('data-select-multi-select-value', 'false');
            selectElement.setAttribute('data-select-placeholder-value', 'Seleccionar producto...');

            // Manually initialize the select controller
            const selectController = this.application.getControllerForElementAndIdentifier(selectElement, 'select');
            if (selectController) {
              selectController.initializeTomSelect();
            }
          }
        });

        // Store the pack and orderItemsController for later use
        this.currentPack = pack;
        this.currentOrderItemsController = orderItemsController;
      })
      .catch(error => {
        console.error('Error loading product options:', error);
        // Open a new modal with the error message
        customModalController.openWithContent('Error', 'Error al cargar las opciones de productos. Por favor, inténtelo de nuevo.', [
          {
            label: 'Cerrar',
            classes: 'btn btn-secondary',
            action: 'click->custom-modal#close'
          }
        ]);
      });
  }

  addProductPackToOrder(event) {
    console.log('addProductPackToOrder called');
    event.preventDefault();

    const pack = this.currentPack;
    const orderItemsController = this.currentOrderItemsController;

    if (!pack || !orderItemsController) {
      console.error("Pack or orderItemsController is not defined");
      return;
    }

    const selectedProducts = pack.pack_details.items.map((item, index) => {
      const select = document.getElementById(`pack-item-${index}`);
      const selectedOption = select.options[select.selectedIndex];
      return {
        id: select.value,
        name: selectedOption.text,
        price: parseFloat(selectedOption.dataset.price),
        quantity: item.quantity
      };
    });

    if (selectedProducts.some(product => !product.id)) {
      alert('Por favor, seleccione un producto para cada ítem del pack.');
      return;
    }

    // Calculate the total regular price of the selected products
    const regularTotal = selectedProducts.reduce((sum, product) => {
      return sum + (product.quantity * product.price);
    }, 0);

    // Calculate the pack discount
    const packDiscount = regularTotal - pack.price;

    // Add each selected product to the order at its original price
    selectedProducts.forEach(product => {
      orderItemsController.addItem({
        id: product.id,
        custom_id: `PACK-${pack.id}-${product.id}`,
        name: product.name,
        price: product.price,
        already_discounted: true,
        quantity: product.quantity,
        isPackItem: true,
        packId: pack.id,
        productPackId: pack.id,  // Add pack ID for tracking in order_items
        productPackName: pack.name  // Add pack name for display
      });
    });

    // Apply the pack discount
    if (packDiscount > 0) {
      orderItemsController.addPackDiscount(
        pack.id,
        packDiscount,
        pack.name,
        selectedProducts.map(product => product.id)
      );
    }

    // Close the modal
    const customModal = document.querySelector('[data-controller="custom-modal"]');
    const customModalController = this.application.getControllerForElementAndIdentifier(customModal, 'custom-modal');
    customModalController.close({ preventDefault: () => { } });
  }

  createProductPackModalContent(pack) {
    console.log('Creating product pack modal content:', pack);
    let content = `
    <div class="mb-4">
      <h3 class="text-lg font-semibold">${pack.name}</h3>
      <p class="text-sm text-gray-600">Precio: S/ ${pack.price.toFixed(2)}</p>
    </div>
  `;

    const fetchPromises = pack.pack_details.items.map((item, index) =>
      this.getProductOptionsForTags(item.tags)
        .then(productOptions => `
        <div class="mb-4">
          <label for="pack-item-${index}" class="block text-sm font-medium text-gray-700">
            Seleccionar producto (${item.quantity}x ${item.tags.join(', ')})
          </label>
          <select id="pack-item-${index}" class="block py-2 pr-10 pl-3 mt-1 w-full text-base rounded-md border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm">
            <option value="">Seleccionar producto...</option>
            ${productOptions}
          </select>
        </div>
      `)
    );

    return Promise.all(fetchPromises)
      .then(itemContents => content + itemContents.join(''));
  }

  getProductOptionsForTags(tags) {
    const tagNames = tags.map(encodeURIComponent).join(',');
    return fetch(`/admin/products/products_matching_tags?tag_names=${tagNames}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        return response.json();
      })
      .then(products => {
        if (products.length === 0) {
          return '<option value="">No hay productos disponibles</option>';
        }
        return products.map(product =>
          `<option value="${product.id}" data-price="${product.price}">${product.name} - S/ ${product.price.toFixed(2)}</option>`
        ).join('');
      })
      .catch(error => {
        console.error('Error fetching products:', error);
        return '<option value="">Error al cargar productos</option>';
      });
  }
}