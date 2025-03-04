import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['dueDateField'];

  connect() {
    console.log("InitialBalanceFormController connected");
    this.toggleDueDate();
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
}
