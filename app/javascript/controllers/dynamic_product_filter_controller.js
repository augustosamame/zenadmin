// app/javascript/controllers/dynamic_product_filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tagSelect", "productsTable"]

  connect() {
    console.log("dynamic_product_filter_controller connected")
    this.debouncedFetchProducts = this.debounce(this.fetchProducts.bind(this), 300)

    // Wait for Tom Select to initialize
    setTimeout(() => {
      this.initializeChangeListeners()
      this.fetchProducts() // Fetch products after initialization
    }, 0)
  }

  initializeChangeListeners() {
    this.initializeChangeListener(this.tagSelectTarget, 'tag')
  }

  initializeChangeListener(element, type) {
    console.log(`Initializing change listener for ${type}`)
    if (element.tomSelect) {
      console.log(`Tom Select instance found for ${type}`)
      element.tomSelect.on('change', () => {
        console.log(`${type} selection changed`)
        this.filterChanged()
      })
    } else {
      console.warn(`No Tom Select instance found for ${type}. Falling back to native select.`)
      element.addEventListener('change', () => {
        console.log(`${type} selection changed (native select)`)
        this.filterChanged()
      })
    }
  }

  fetchProducts() {
    console.log("fetchProducts called")
    const tagIds = this.getSelectedValues(this.tagSelectTarget)

    console.log("Selected tag IDs:", tagIds)

    const url = new URL(this.productsTableTarget.dataset.url, window.location.origin)
    tagIds.forEach(id => url.searchParams.append('tag_ids[]', id))

    console.log("Fetching products from URL:", url.toString())

    fetch(url)
      .then(response => response.text())
      .then(html => {
        console.log("Received response, updating products table")
        this.productsTableTarget.innerHTML = html
      })
      .catch(error => {
        console.error("Error fetching products:", error)
      })
  }

  filterChanged() {
    console.log("filterChanged called")
    this.debouncedFetchProducts()
  }

  getSelectedValues(selectElement) {
    if (selectElement.tomSelect) {
      const values = selectElement.tomSelect.getValue()
      console.log(`Selected values for ${selectElement.id}:`, values)
      return values
    } else {
      console.warn(`No Tom Select instance found for ${selectElement.id}. Using native select.`)
      return Array.from(selectElement.selectedOptions).map(option => option.value)
    }
  }

  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        console.log("Debounced function executed")
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
}