import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Initialize the DataTable when the controller connects
    this.initializeDataTable()
  }

  refreshTable(event) {
    event.preventDefault()
    const form = event.target.closest('form')
    
    // Get all form values
    const formData = new FormData(form)
    
    // Collect form values for DataTable filtering
    const params = {}
    let hasFilters = false
    
    formData.forEach((value, key) => {
      if (value) {
        params[key] = value
        hasFilters = true
      }
    })

    // Show or hide the remove filters button
    this.toggleRemoveFiltersButton(hasFilters)

    // Reload DataTable with new parameters
    if ($.fn.DataTable.isDataTable('#datatable-element')) {
      const table = $('#datatable-element').DataTable()
      
      // Store the form values in the DataTable's AJAX data function
      table.ajax.reload(null, false)
      
      // Update the URL with the filter parameters (without reloading the page)
      const url = new URL(window.location.href)
      Object.entries(params).forEach(([key, value]) => {
        if (value) {
          url.searchParams.set(key, value)
        } else {
          url.searchParams.delete(key)
        }
      })
      window.history.pushState({}, '', url)
    }
  }

  removeFilters(event) {
    event.preventDefault()
    
    // Navigate to the clear filters URL
    window.location.href = event.currentTarget.href
  }

  toggleRemoveFiltersButton(show) {
    // Find the remove filters button container
    const form = this.element.querySelector('form')
    if (!form) return
    
    let removeFiltersLink = form.querySelector('a[data-action="attendance-logs#removeFilters"]')
    
    if (!removeFiltersLink) {
      // If the button doesn't exist and we need to show it, create it
      if (show) {
        const clearUrl = new URL(window.location.pathname, window.location.origin)
        clearUrl.searchParams.set('clear_filters', 'true')
        
        removeFiltersLink = document.createElement('a')
        removeFiltersLink.href = clearUrl.toString()
        removeFiltersLink.className = 'btn btn-secondary w-[300px] max-w-[160px]'
        removeFiltersLink.dataset.action = 'attendance-logs#removeFilters'
        removeFiltersLink.innerHTML = '<i class="mr-1 fas fa-times"></i> Quitar Filtros'
        
        // Append after the submit button
        const submitButton = form.querySelector('input[type="submit"]')
        if (submitButton) {
          submitButton.insertAdjacentElement('afterend', removeFiltersLink)
        } else {
          form.appendChild(removeFiltersLink)
        }
      }
    } else {
      // If it exists, show/hide based on parameter
      removeFiltersLink.style.display = show ? 'inline-block' : 'none'
    }
  }

  initializeDataTable() {
    // The DataTable is initialized by the datatable controller
    // We just need to make sure our filters are applied to AJAX requests
    $(document).on('preXhr.dt', (e, settings, data) => {
      // Add filter parameters from the form
      const form = this.element.querySelector('form')
      if (form) {
        const formData = new FormData(form)
        let hasFilters = false
        
        formData.forEach((value, key) => {
          if (value) {
            data[key] = value
            hasFilters = true
          }
        })
        
        // Update the remove filters button visibility
        this.toggleRemoveFiltersButton(hasFilters)
      }
    })
  }
}