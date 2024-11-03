import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['menu', 'trigger'];

  connect() {
    document.addEventListener('click', this.hide.bind(this));
  }

  disconnect() {
    document.removeEventListener('click', this.hide.bind(this));
  }

  toggle(event) {
    event.stopPropagation();
    this.menuTarget.classList.toggle('hidden');
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden');
    }
  }

  confirm(objectModel, objectId) {
    if (confirm("¿Está seguro que desea confirmar este ajuste de inventario?")) {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

      fetch(`/admin/stock_transfers/${objectId}/adjustment_stock_transfer_admin_confirm`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
          'Accept': 'text/vnd.turbo-stream.html'
        },
        credentials: 'same-origin'
      })
        .then(response => {
          if (!response.ok) {
            throw new Error('Network response was not ok');
          }
          window.location.reload();
        })
        .catch(error => {
          console.error('Error:', error);
          alert('Error al confirmar el ajuste de inventario');
        });
    }
  }

  handleAction(event) {
    event.preventDefault();
    const objectId = event.currentTarget.dataset.objectId;
    const eventName = event.currentTarget.dataset.eventName;
    const objectModel = event.currentTarget.dataset.objectModel;

    console.log(`${eventName} clicked for objectId:`, objectId);

    this.menuTarget.classList.add('hidden'); // Hide the dropdown

    // Dispatch to the appropriate handler based on the event name
    if (this[eventName]) {
      this[eventName](objectModel, objectId);
    } else {
      console.warn(`No handler defined for event: ${eventName}`);
    }
  }

  // Add more methods for additional events as needed
}