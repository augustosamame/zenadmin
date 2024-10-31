import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  refreshTable(event) {
    event.preventDefault()
    const form = event.target.closest('form')
    const url = new URL(window.location.href)
    
    // Get all form values
    const formData = new FormData(form)
    
    // Update URL with all form parameters
    formData.forEach((value, key) => {
      if (value) {
        url.searchParams.set(key, value)
      } else {
        url.searchParams.delete(key)
      }
    })

    this.fetchTable(url)
  }

  removeFilters(event) {
    event.preventDefault()
    const url = new URL(event.currentTarget.href)
    
    // Clear all form inputs
    const form = this.element.querySelector('form')
    if (form) {
      form.reset() // Reset all form fields
      
      // Explicitly clear datetime inputs as they might not be cleared by reset()
      form.querySelectorAll('input[type="datetime-local"]').forEach(input => {
        input.value = ''
      })
      
      // Reset select to first option
      const locationSelect = form.querySelector('select[name="location_id"]')
      if (locationSelect) {
        locationSelect.selectedIndex = 0
      }
    }

    this.fetchTable(url)
  }

  fetchTable(url) {
    fetch(url, {
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const newTable = doc.getElementById('datatable-element')
        const currentTable = document.getElementById('datatable-element')
        currentTable.innerHTML = newTable.innerHTML
        
        // Also update the form area to show/hide the remove filters button
        const formArea = doc.querySelector('[data-controller="attendance-logs"]')
        if (formArea) {
          this.element.innerHTML = formArea.innerHTML
        }
      })
  }
}