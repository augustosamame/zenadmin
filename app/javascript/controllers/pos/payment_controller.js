import { Controller } from '@hotwired/stimulus'
import axios from 'axios'

export default class extends Controller {
  static targets = ['productGrid', 'paymentContainer', 'remainingAmount', 'paymentMethods', 'paymentList', 'remainingLabel', 'paymentButton', 'total'];

  connect() {
    console.log('Connected to PaymentController!');
  }

  payOrder() {
    console.log('Pay button clicked');

    const orderItemsTotal = document.querySelector('[data-pos--order-items-target="total"]').textContent.trim();
    const totalAmount = parseFloat(orderItemsTotal.replace('S/', ''));
    if (totalAmount === 0) {
      console.log('Cannot proceed to payment: Total is 0');
      return;
    }

    // Hide the product grid and show the payment section
    this.productGridTarget.classList.add('hidden');
    this.paymentContainerTarget.classList.remove('hidden');

    // Update the total amount in the payment section
    this.updateTotal();

    // Fetch available payment methods
    this.fetchPaymentMethods();
  }

  fetchPaymentMethods() {
    axios.get('/admin/payment_methods', { headers: { 'Accept': 'application/json' } })
      .then(response => {
        const methods = response.data;
        this.paymentMethodsTarget.innerHTML = '';

        methods.forEach(method => {
          const button = document.createElement('button');
          button.classList.add('p-4', 'm-2', 'bg-gray-300', 'rounded', 'btn', 'dark:bg-gray-600');
          button.textContent = method.description;
          button.dataset.method = method.name;
          button.dataset.description = method.description;
          button.addEventListener('click', this.addPayment.bind(this));
          this.paymentMethodsTarget.appendChild(button);
        });
      })
      .catch(error => {
        console.error('Error fetching payment methods:', error);
      });
  }

  addPayment(event) {
    const method = event.currentTarget.dataset.description;
    const totalAmount = parseFloat(this.totalTarget.textContent.replace('S/', ''));
    const remaining = parseFloat(this.remainingAmountTarget.textContent.replace('S/', ''));
    const paymentAmount = remaining > 0 ? remaining : totalAmount;

    const paymentElement = document.createElement('div');
    paymentElement.classList.add('flex', 'justify-between', 'p-2', 'bg-white', 'rounded', 'shadow-md', 'mb-2', 'dark:bg-gray-700');
    paymentElement.innerHTML = `
      <span>${method}</span>
      <input type="number" class="text-right border-none focus:ring-0" value="${paymentAmount.toFixed(2)}" data-action="input->pos--payment#updateRemaining">
      <button type="button" class="text-red-500" data-action="click->pos--payment#removePayment">✖</button>
    `;

    this.paymentListTarget.appendChild(paymentElement);
    this.updateRemaining();
  }

  removePayment(event) {
    const paymentElement = event.currentTarget.closest('div');
    paymentElement.remove();
    this.updateRemaining();
  }

  updateTotal() {
    // Get the total from the order-items controller and display it in the payment section
    const orderItemsTotal = document.querySelector('[data-pos--order-items-target="total"]').textContent.trim();
    this.totalTarget.textContent = orderItemsTotal;

    // Set remaining amount to the total initially
    this.remainingAmountTarget.textContent = orderItemsTotal;
  }

  updateRemaining() {
    let total = parseFloat(this.totalTarget.textContent.replace('S/', ''));
    let payments = 0;

    this.paymentListTarget.querySelectorAll('input[type="number"]').forEach(input => {
      payments += parseFloat(input.value);
    });

    const remaining = total - payments;
    this.remainingAmountTarget.textContent = remaining >= 0
      ? `S/ ${remaining.toFixed(2)}`
      : `Cambio: S/ ${(remaining * -1).toFixed(2)}`;

    this.remainingLabelTarget.textContent = remaining >= 0 ? 'Remaining:' : 'Cambio:';
  }

  saveOrder() {
    console.log('Saving order...');
    this.dispatch('saveOrder', { detail: {} });
  }

  cancelPayment() {
    console.log('Cancel button clicked');
    this.paymentContainerTarget.classList.add('hidden');
    this.productGridTarget.classList.remove('hidden');
  }
}
