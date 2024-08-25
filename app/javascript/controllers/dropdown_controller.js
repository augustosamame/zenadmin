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
    this.menuTarget.classList.toggle('hidden')
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
    }
  }

  handleAction(event) {
    event.preventDefault()

    this.menuTarget.classList.add('hidden') // Hide the dropdown

    // Dispatch to the appropriate handler based on the event name
    if (this[eventName]) {
      this[eventName]()
    } else {
      console.warn(`No handler defined for event: ${eventName}`)
    }
  }

  edit() {
    // Implement edit logic here
  }

  message() {
    // Implement message logic here
  }

  // Add more methods for additional events as needed
}