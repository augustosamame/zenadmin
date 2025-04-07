import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['menu', 'trigger']

  connect() {
    document.addEventListener('click', this.hide.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.hide.bind(this))
  }

  toggle(event) {
    event.stopPropagation()
    this.closeOtherDropdowns()
    this.menuTarget.classList.toggle('hidden')
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
    }
  }

  closeOtherDropdowns() {
    document.querySelectorAll('[data-controller="dropdown"]').forEach((dropdown) => {
      if (dropdown !== this.element) {
        dropdown.querySelector('[data-dropdown-target="menu"]').classList.add('hidden')
      }
    })
  }

  handleAction(event) {
    event.preventDefault()
    const objectId = event.currentTarget.dataset.objectId
    const eventName = event.currentTarget.dataset.eventName
    this.menuTarget.classList.add('hidden') // Hide the dropdown

    // Dispatch to the appropriate handler based on the event name
    if (eventName === 'edit') {
      this.editAction(objectId)
    } else if (eventName === 'delete') {
      this.deleteAction(objectId)
    } else if (this[eventName]) {
      this[eventName]()
    } else {
      console.warn(`No handler defined for event: ${eventName}`)
    }
  }

  editAction(objectId) {
    const resourceType = window.location.pathname.split('/')[2] // Gets 'transportistas' from '/admin/transportistas'
    if (resourceType && objectId) {
      window.location.href = `/admin/${resourceType}/${objectId}/edit`
    } else {
      console.warn('Unable to determine edit URL')
    }
  }

  deleteAction(objectId) {
    const resourceType = window.location.pathname.split('/')[2] // Gets 'transportistas' from '/admin/transportistas'
    if (resourceType && objectId) {
      if (confirm('¿Está seguro que desea eliminar este registro?')) {
        const csrfToken = document.querySelector('meta[name="csrf-token"]').content
        
        fetch(`/admin/${resourceType}/${objectId}`, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': csrfToken,
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          credentials: 'same-origin'
        })
        .then(response => {
          if (!response.ok) {
            throw new Error('Network response was not ok')
          }
          window.location.reload()
        })
        .catch(error => {
          console.error('Error:', error)
          alert('Error al eliminar el registro')
        })
      }
    } else {
      console.warn('Unable to determine delete URL')
    }
  }

  edit(editUrl) {
    if (editUrl) {
      window.location.href = editUrl
    } else {
      console.warn('No edit URL provided')
    }
  }

  destroy(destroyUrl) {
    if (destroyUrl) {
      window.location.href = destroyUrl
    } else {
      console.warn('No destroy URL provided')
    }
  }

  message() {
    // Implement message logic here
  }

  // Add more methods for additional events as needed
}