import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  refreshTable(event) {
    const locationId = event.target.value
    const url = new URL(window.location.href)
    url.searchParams.set('location_id', locationId)

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
      })
  }
}