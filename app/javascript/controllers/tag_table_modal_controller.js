import { Controller } from '@hotwired/stimulus';
import axios from 'axios';

export default class extends Controller {
  static targets = ['container', 'content'];

  connect() {
    console.log("TagTableModalController connected");
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
    console.log("Loading tag table data");
    fetch('/admin/tags', {
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

  // Add additional methods as needed for modal interactions
}
