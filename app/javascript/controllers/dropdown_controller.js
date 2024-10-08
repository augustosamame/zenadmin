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
    const eventName = event.currentTarget.dataset.eventName
    const editUrl = event.currentTarget.dataset.editUrl
    const destroyUrl = event.currentTarget.dataset.destroyUrl
    this.menuTarget.classList.add('hidden') // Hide the dropdown

    // Dispatch to the appropriate handler based on the event name
    if (this[eventName]) {
      this[eventName](editUrl, destroyUrl)
    } else {
      console.warn(`No handler defined for event: ${eventName}`)
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