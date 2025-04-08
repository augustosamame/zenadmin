import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['dueDateField', 'form'];

  connect() {
    console.log("InitialBalanceFormController connected");
    this.toggleDueDate();
    
    // Add event listener for form submission
    this.element.addEventListener('submit', this.handleSubmit.bind(this));
  }

  toggleDueDate(event) {
    const amountField = this.element.querySelector('input[name="amount"]');
    const amount = parseFloat(amountField.value) || 0;
    
    if (amount > 0) {
      this.dueDateFieldTarget.classList.remove('hidden');
      this.dueDateFieldTarget.querySelector('input').required = true;
    } else {
      this.dueDateFieldTarget.classList.add('hidden');
      this.dueDateFieldTarget.querySelector('input').required = false;
    }
  }
  
  handleSubmit(event) {
    event.preventDefault();
    
    const form = this.element;
    const formData = new FormData(form);
    
    fetch(form.action, {
      method: form.method,
      body: formData,
      headers: {
        'Accept': 'application/json'
      },
      credentials: 'same-origin'
    })
    .then(response => {
      if (response.ok) {
        // Force a full page reload to avoid DataTables reinitialization issues
        window.location.reload();
      } else {
        response.json().then(data => {
          alert(data.error || 'Ocurrió un error al procesar la solicitud.');
        }).catch(() => {
          alert('Ocurrió un error al procesar la solicitud.');
        });
      }
    })
    .catch(error => {
      console.error('Error:', error);
      alert('Ocurrió un error al procesar la solicitud.');
    });
  }
}
