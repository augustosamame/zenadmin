import { Controller } from '@hotwired/stimulus';
import axios from 'axios';

export default class extends Controller {
  static targets = ['docType', 'docId', 'firstName', 'lastName', 'birthDate', 'form'];
  static values = { inModal: Boolean }

  connect() {
    console.log('Connected to customer form controller');
    this.formTarget.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this));
    document.addEventListener("customer-form-result", this.handleFormResult.bind(this));
  }

  fetchCustomerData(event) {
    const docType = this.docTypeTarget.value;
    const docId = event.target.value.trim();

    if (docType === 'dni' && docId !== '') {
      axios.get(`/admin/search_dni?numero=${docId}`, { headers: { 'Accept': 'application/json' } })
        .then(response => {
          if (response.data.error) {
            this.showErrorDialog('Error', response.data.error);
          } else {
            const data = response.data;
            const firstName = data.nombres;
            const lastName = `${data.apellido_paterno} ${data.apellido_materno}`;
            const birthDate = data.fecha_nacimiento.split('/').reverse().join('-');

            this.firstNameTarget.value = firstName;
            this.lastNameTarget.value = lastName;
            this.birthDateTarget.value = birthDate;
          }
        })
        .catch(error => {
          console.error('Error fetching customer data:', error);
          this.showErrorDialog('Error', 'Error al buscar datos de cliente. Por favor, inténtelo de nuevo.');
        });
    }
  }

  showErrorDialog(title, message) {
    alert(`${title}: ${message}`); // Simple alert for error handling; replace with your custom modal if available
  }

  cancel(event) {
    console.log("cancel button clicked");
    event.preventDefault();
    if (this.inModalValue) {
      // call customer_table_modal_controller#cancelCreateForm
      const modalElement = document.querySelector('[data-controller="customer-table-modal"]');
      if (modalElement) {
        this.application.getControllerForElementAndIdentifier(modalElement, 'customer-table-modal').cancelCreateForm(event);
      } else {
        console.error('CustomerTableModalController element not found');
      }
    } else {
      // Redirect to the customer index page after successful form submission
      window.location.href = '/admin/customers';
    }
  }

  handleSubmitEnd(event) {
    console.log("Form submitted");
  }

  handleFormResult(event) {
    console.log("Form result received:", event.detail);

    if (event.detail.success) {
      if (this.inModalValue) {
        console.log("We're in the modal context");
        // this.handleModalSubmit();
      } else {
        console.log("We're in the regular form context");
        // Redirect to the customer index page after successful form submission
        window.location.href = '/admin/customers';
      }
    } else {
      console.log("Form submission failed, staying on the current page");
    }
  }

}