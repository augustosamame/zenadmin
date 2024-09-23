import { Controller } from '@hotwired/stimulus';
import axios from 'axios';

export default class extends Controller {
  static targets = ['container', 'content', 'modalContainer', 'firstName', 'lastName', 'birthDate'];

  connect() {
    console.log("CustomerTableModalController connected");
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  }

  open() {
    this.containerTarget.classList.remove('hidden');
    this.contentTarget.classList.remove('hidden');
    this.loadTableData();
  }

  close(event) {
    if (event) {
      event.preventDefault();
    }
    this.containerTarget.classList.add('hidden');
    this.contentTarget.classList.add('hidden');
  }

  loadTableData() {
    console.log("Loading table data");
    fetch('/admin/customers', {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(response => response.text())
      .then(html => {
        Turbo.renderStreamMessage(html)
      })
  }

  showCreateForm(event) {
    console.log("showCreateForm button clicked");
    event.preventDefault();

    fetch('/admin/customers/new?in_modal=true', {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': this.csrfToken
      }
    })
      .then(response => response.text())
      .then(html => {
        Turbo.renderStreamMessage(html);
      });
  }

  cancelCreateForm(event) {
    console.log("cancelCreateForm called");
    event.preventDefault();
    this.loadTableData();
  }

  handleDocTypeChange(event) {
    // Reset fields when document type changes
    this.clearCustomerFields();
  }

  clearCustomerFields() {
    this.firstNameTarget.value = '';
    this.lastNameTarget.value = '';
  }

  fetchCustomerData(event) {
    const docType = this.contentTarget.querySelector('#doc_type').value;
    const docId = event.target.value.trim();

    if (docType === 'dni' && docId !== '') {
      axios.get(`/admin/search_dni?numero=${docId}`, { headers: { 'Accept': 'application/json' } })
        .then(response => {
          if (response.data.error) {
            // Show the default error dialog with the error content
            this.showErrorDialog('Error', response.data.error);
          } else {
            const data = response.data;

            // Map the JSON response to form fields and capitalize names
            const firstName = data.nombres;
            const lastName = `${data.apellido_paterno} ${data.apellido_materno}`;
            const birthDate = data.fecha_nacimiento;

            this.firstNameTarget.value = firstName;
            this.lastNameTarget.value = lastName;
            this.birthDateTarget.value = "04/01/1974".split('/').reverse().join('-');
          }
        })
        .catch(error => {
          console.error('Error fetching customer data:', error);
          // Show a generic error dialog in case of a request failure
          this.showErrorDialog('Error', 'Error al buscar datos de cliente. Por favor, inténtelo de nuevo.');
        });
    }
  }

  showErrorDialog(title, message) {
    const buttons = [
      { label: 'OK', classes: 'btn btn-primary', action: 'click->custom-modal#close' }
    ];

    this.customModalController = this.application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="custom-modal"]'),
      'custom-modal'
    );

    if (this.customModalController) {
      this.customModalController.openWithContent(title, message, buttons);
    } else {
      console.error('CustomModalController not found!');
    }
  }

  selectObject(event) {
    const selectedRow = event.currentTarget.closest('tr');
    const objectId = selectedRow.dataset.objectId;
    const userId = selectedRow.dataset.userId;
    const phone = selectedRow.dataset.phone;
    const email = selectedRow.dataset.email;
    const firstName = selectedRow.querySelector('td:nth-child(1)').textContent.trim();
    const lastName = selectedRow.querySelector('td:nth-child(2)').textContent.trim();
    const ruc = selectedRow.querySelector('td:nth-child(4)').textContent.trim();
    const fullName = ruc ? `${firstName} ${lastName} - RUC: ${ruc}` : `${firstName} ${lastName}`;

    // Update the Cliente button
    const clienteButton = document.querySelector('[data-action="click->customer-table-modal#open"]');
    clienteButton.dataset.selectedObjectId = objectId;
    clienteButton.dataset.selectedUserId = userId;
    clienteButton.dataset.selectedRuc = ruc;
    clienteButton.dataset.selectedPhone = phone
    clienteButton.dataset.selectedEmail = email

    // Keep the existing icon and update the text
    clienteButton.innerHTML = `
      ${clienteButton.querySelector('svg').outerHTML.replace('text-slate-600', 'text-white').replace('dark:text-slate-300', 'text-white mr-2')} ${fullName}
    `;
    clienteButton.classList.add('bg-blue-500', 'text-white');
    clienteButton.classList.remove('bg-white');

    const customerSelectedEvent = new CustomEvent('customer-selected', {
      bubbles: true,
      detail: { userId: userId }
    });
    this.element.dispatchEvent(customerSelectedEvent);

    console.log('Customer selected event dispatched', { userId: userId });

    // Close the modal
    this.close(event);

    console.log(`Object with ID ${objectId} selected.`);
  }
}