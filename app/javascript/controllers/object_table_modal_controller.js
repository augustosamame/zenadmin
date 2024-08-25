import { Controller } from '@hotwired/stimulus';
import axios from 'axios';

export default class extends Controller {
  static targets = ['container', 'content', 'modalContainer', 'firstName', 'lastName', 'birthDate'];

  connect() {
    console.log("ObjectTableModalController connected");
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  }

  open() {
    this.containerTarget.classList.remove('hidden');
    this.contentTarget.classList.remove('hidden');
    this.loadTableData();
  }

  close(event) {
    event.preventDefault();
    this.containerTarget.classList.add('hidden');
    this.contentTarget.classList.add('hidden');
  }

  loadTableData() {
    axios.get('/admin/customers', { headers: { 'Accept': 'application/json' } })
      .then(response => {
        const customers = response.data;
        const tableHtml = this.buildTable(customers);
        this.contentTarget.querySelector('#object-table-datatable').innerHTML = tableHtml;
      })
      .catch(error => {
        console.error('Error fetching customers:', error);
      });
  }

  buildTable(customers) {
    return `
      <div data-controller="datatable" data-datatable-options-value="no_buttons">
        <div class="container p-2 mx-auto mt-6 bg-white border rounded-lg shadow border-slate-300/80 shadow-slate-100 dark:shadow-slate-950 dark:bg-slate-800 dark:border-slate-600/80">
          <table id="datatable-element" class="min-w-full bg-white dark:bg-slate-800">
            <thead>
              <tr>
                <th class="px-4 py-2 text-left">Nombres</th>
                <th class="px-4 py-2 text-left">Apellidos</th>
                <th class="px-4 py-2 text-left">Correo</th>
                <th class="px-4 py-2 text-left">Teléfono</th>
                <th class="px-4 py-2 text-left">Acciones</th>
              </tr>
            </thead>
            <tbody>
              ${customers.map(customer => `
                <tr data-object-id="${customer.id}" data-action="click->object-table-modal#selectObject">
                  <td class="px-4 py-2">${customer.first_name}</td>
                  <td class="px-4 py-2">${customer.last_name}</td>
                  <td class="px-4 py-2">${customer.email}</td>
                  <td class="px-4 py-2">${customer.phone}</td>
                  <td class="px-4 py-2">
                    <button class="btn btn-primary">Seleccionar</button>
                  </td>
                </tr>`).join('')}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  showCreateForm(event) {
    event.preventDefault();

    const formHtml = `
    <form id="new-customer-form">
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-row space-x-4">
          <div class="flex flex-col w-1/2">
            <label for="doc_type" class="block mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">Document Type</label>
            <select id="doc_type" name="doc_type" class="block w-full p-2 border rounded-md dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600">
              <option value="dni">DNI</option>
              <option value="ce">Carnet De Extranjeria</option>
              <option value="passport">Pasaporte</option>
              <option value="other">Otros</option>
            </select>
          </div>
          <div class="flex flex-col w-1/2">
            <label for="document_id" class="block mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">Document Id</label>
            <input type="text" id="document_id" name="document_id" class="block w-full p-2 border rounded-md dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600" data-action="blur->object-table-modal#fetchCustomerData">

          </div>
        </div>
        <div>
            <label for="first_name" class="block mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">First Name</label>
            <input type="text" id="first_name" name="first_name" class="block w-full p-2 border rounded-md dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600" data-object-table-modal-target="firstName">
          </div>
          <div>
            <label for="last_name" class="block mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">Last Name</label>
            <input type="text" id="last_name" name="last_name" class="block w-full p-2 border rounded-md dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600" data-object-table-modal-target="lastName">
          </div>
          <div>
            <label for="phone" class="block mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">Phone</label>
            <input type="text" id="phone" name="phone" class="block w-full p-2 border rounded-md dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600">
          </div>
          <div>
            <label for="email" class="block mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">Email</label>
            <input type="email" id="email" name="email" class="block w-full p-2 border rounded-md dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600">
          </div>
          <div>
            <label for="birthdate" class="block mb-2 text-sm font-medium text-gray-700 dark:text-gray-300">Birthdate</label>
            <input type="date" id="birthdate" name="birthdate" class="block w-full p-2 border rounded-md dark:bg-slate-700 dark:text-slate-200 dark:border-slate-600" data-object-table-modal-target="birthDate">
          </div>
        </div>
        <div class="flex justify-end mt-4 space-x-4">
          <button type="button" class="btn btn-secondary" data-action="click->object-table-modal#loadTableData">Cancelar</button>
          <button type="submit" class="btn btn-primary">Crear Cliente</button>
        </div>
      </form>
    `;

    this.contentTarget.querySelector('#object-table-datatable').innerHTML = formHtml;
    this.addFormSubmitListener();
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

  addFormSubmitListener() {
    const form = this.contentTarget.querySelector('#new-customer-form');
    form.addEventListener('submit', (event) => this.submitNewCustomerForm(event));
  }

  submitNewCustomerForm(event) {
    event.preventDefault();

    const formData = new FormData(event.target);
    const customerData = Object.fromEntries(formData.entries());

    // Transform the data into the required structure
    const structuredData = {
      user: {
        first_name: customerData.first_name,
        last_name: customerData.last_name,
        email: customerData.email,
        phone: customerData.phone,
        birthdate: customerData.birthdate,
        customer_attributes: {
          doc_type: customerData.doc_type, // Value from the dropdown
          doc_id: customerData.document_id // Document ID from the form
        }
      }
    };

    axios.post('/admin/pos_create_customer', structuredData, { headers: { 'Accept': 'application/json', 'X-CSRF-Token': this.csrfToken } })
      .then(response => {
        const customer = response.data;

        // Update the Cliente button with the new customer
        const clienteButton = document.querySelector('[data-action="click->object-table-modal#open"]');
        clienteButton.innerHTML = `
        ${clienteButton.querySelector('svg').outerHTML.replace('text-slate-600', 'text-white').replace('dark:text-slate-300', 'text-white mr-2')} ${customer.first_name} ${customer.last_name}
      `;
        clienteButton.classList.add('bg-blue-500', 'text-white');
        clienteButton.classList.remove('bg-white');

        // Close the modal
        this.close(event);
        console.log(`New customer with ID ${customer.id} created and selected.`);
      })
      .catch(error => {
        console.error('Error creating customer:', error);
        // Optionally display an error message in the form
      });
  }

  selectObject(event) {
    const selectedRow = event.currentTarget.closest('tr');
    const objectId = selectedRow.dataset.objectId;
    const firstName = selectedRow.querySelector('td:nth-child(1)').textContent.trim();
    const lastName = selectedRow.querySelector('td:nth-child(2)').textContent.trim();
    const fullName = `${firstName} ${lastName}`;

    // Update the Cliente button
    const clienteButton = document.querySelector('[data-action="click->object-table-modal#open"]');
    clienteButton.dataset.selectedObjectId = objectId;

    // Keep the existing icon and update the text
    clienteButton.innerHTML = `
      ${clienteButton.querySelector('svg').outerHTML.replace('text-slate-600', 'text-white').replace('dark:text-slate-300', 'text-white mr-2')} ${fullName}
    `;
    clienteButton.classList.add('bg-blue-500', 'text-white');
    clienteButton.classList.remove('bg-white');

    // Close the modal
    this.close(event);

    console.log(`Object with ID ${objectId} selected.`);
  }
}