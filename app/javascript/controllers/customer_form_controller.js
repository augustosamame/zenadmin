import { Controller } from '@hotwired/stimulus';
import axios from 'axios';

export default class extends Controller {
  static targets = ['docType', 'docId', 'firstName', 'lastName', 'birthDate', 'form', 'wantsFactura', 'facturaFields', 'facturaRuc', 'facturaRazonSocial', 'facturaDireccion'];
  static values = { inModal: Boolean }

  connect() {
    console.log('Connected to customer form controller');
    this.formTarget.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this));
    document.addEventListener("customer-form-result", this.handleFormResult.bind(this));
    this.toggleFacturaFields();
  }

  fetchCustomerData(event) {
    const docType = this.docTypeTarget.value;
    const docId = event.target.value.trim();

    if (docType === 'dni' && docId !== '') {
      axios.get(`/admin/search_dni?numero=${docId}`, { headers: { 'Accept': 'application/json' } })
        .then(response => {
          if (response.data.error) {
            //this.showErrorDialog('Error', response.data.error);
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
          //this.showErrorDialog('Error', 'Error al buscar datos de cliente. Por favor, inténtelo de nuevo.');
        });
    }
  }

  fetchCustomerDataIfLength(event) {
    if (event.target.value.length === 8) {
      this.fetchCustomerData(event);
    }
  }

  fetchRucData(event) {
    const rucId = event.target.value.trim();

    if (rucId !== '') {
      axios.get(`/admin/search_ruc?numero=${rucId}`, { headers: { 'Accept': 'application/json' } })
        .then(response => {
          if (response.data.error) {
            this.showErrorDialog('Error', response.data.error);
          } else {
            const data = response.data;
            const facturaRazonSocial = data.razon_social;
            const facturaDireccion = data.direccion;

            this.facturaRazonSocialTarget.value = facturaRazonSocial;
            this.facturaDireccionTarget.value = facturaDireccion;
          }
        })
        .catch(error => {
          console.error('Error fetching customer data:', error);
          this.showErrorDialog('Error', 'Error al buscar datos del RUC. Por favor, inténtelo de nuevo.');
        });
    }
  }

  fetchRucDataIfLength(event) {
    if (event.target.value.length === 11) {
      this.fetchRucData(event);
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

  disconnect() {
    document.removeEventListener("customer-form-result", this.handleFormResult);
    this.formTarget.removeEventListener("turbo:submit-end", this.handleSubmitEnd);
  }

  toggleFacturaFields() {
    if (this.wantsFacturaTarget.checked) {
      this.facturaFieldsTarget.classList.remove('hidden');
    } else {
      this.facturaFieldsTarget.classList.add('hidden');
      // Clear all factura-related fields
      this.facturaRucTarget.value = '';
      this.facturaRazonSocialTarget.value = '';
      this.facturaDireccionTarget.value = '';
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