import { Controller } from '@hotwired/stimulus';
import axios from 'axios';

export default class extends Controller {
  static targets = ['docType', 'docId', 'firstName', 'lastName', 'birthDate'];

  connect() {
    console.log('Connected to customer form controller');
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
}