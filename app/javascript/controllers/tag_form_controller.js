import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['name', 'status'];

  connect() {
    console.log('Connected to TagFormController');
  }

  cancel(event) {
    event.preventDefault();
    // Redirect to tags index page
    window.location.href = '/admin/tags';
  }

  // Add additional methods as needed for form interactions
}
