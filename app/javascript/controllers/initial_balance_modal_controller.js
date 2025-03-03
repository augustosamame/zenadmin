import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['container', 'content'];

  connect() {
    console.log("InitialBalanceModalController connected");
  }

  open() {
    console.log("Opening initial balance modal");
    this.containerTarget.classList.remove('hidden');
    this.contentTarget.classList.remove('hidden');
  }

  close(event = null) {
    if (event) {
      event.preventDefault();
    }
    this.containerTarget.classList.add('hidden');
    this.contentTarget.classList.add('hidden');
  }
}
