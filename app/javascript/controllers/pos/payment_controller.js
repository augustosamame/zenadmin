import { Controller } from '@hotwired/stimulus'
import axios from 'axios'

export default class extends Controller {
  static targets = ['productGrid', 'paymentContainer', 'remainingAmount', 'paymentMethods', 'paymentList', 'remainingLabel', 'paymentButton', 'total'];

  connect() {
    console.log('Connected to PaymentController!');
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
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
          button.dataset.id = method.id;
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
    const methodId = event.currentTarget.dataset.id;
    let remaining = parseFloat(this.remainingAmountTarget.textContent.replace('S/', ''));

    // If remaining is less than or equal to zero, set payment amount to 0
    const paymentAmount = remaining > 0 ? remaining : 0;

    const paymentElement = document.createElement('div');
    paymentElement.classList.add('grid', 'grid-cols-[auto_1fr_auto]', 'gap-2', 'p-2', 'bg-white', 'rounded', 'shadow-md', 'mb-2', 'dark:bg-gray-700');
    paymentElement.dataset.methodId = methodId;
    paymentElement.innerHTML = `
      <span class="self-center">${method}</span>
      <input type="number" class="text-right border-none focus:ring-0 self-center" value="${paymentAmount.toFixed(2)}" data-action="input->pos--payment#updateRemaining">
      <button type="button" class="text-red-500 self-center" data-action="click->pos--payment#removePayment">✖</button>
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
    const orderItems = document.querySelectorAll('[data-pos--order-items-target="items"] div.flex');
    console.log('Order Items:', orderItems);
    const orderItemsAttributes = [];

    orderItems.forEach(item => {
      const quantity = item.querySelector('[data-item-quantity]').textContent.trim();
      const price = item.querySelector('.editable-price').textContent.replace('S/ ', '').trim();

      orderItemsAttributes.push({
        product_id: item.dataset.productId, // Extract product ID
        quantity: quantity, // Extract quantity
        price: price
      });
    });

    const payments = [];
    this.paymentListTarget.querySelectorAll('input[type="number"]').forEach(input => {
      payments.push({
        amount: input.value,
        payment_method_id: input.closest('div').dataset.methodId,
        user_id: 1,
        payable_type: 'Order',
      });
    });

    const data = {
      order: {
        location_id: 1,
        stage: 'confirmed',
        user_id: 1,
        total_price: parseFloat(this.totalTarget.textContent.replace('S/', '')),
        total_discount: 0,
        shipping_price: 0,
        currency: 'PEN',
        payment_status: 'paid',
        order_items_attributes: orderItemsAttributes,
        payments_attributes: payments
      }
    };

    axios.post('/admin/orders', data, {
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': this.csrfToken // Include the CSRF token here
      } })
      .then(response => {
        console.log('Order saved:', response.data);
        // show a success message
        const title = 'Orden Creada';
        const message = `La Orden #${response.data.id} se creó satisfactoriamente.`;
        const buttons = [
          { label: 'OK', classes: 'btn btn-primary', action: 'click->custom-modal#close' },
          // { label: 'Confirm', classes: 'btn btn-secondary', action: 'click->your-controller#confirmAction' }
        ];

        this.customModalController = this.application.getControllerForElementAndIdentifier(
          document.querySelector('[data-controller="custom-modal"]'),
          'custom-modal'
        );

        this.customModalController.openWithContent(title, message, buttons);
        // Clear the order items and payment list
        const orderItemsController = this.application.getControllerForElementAndIdentifier(
          document.querySelector('[data-controller="pos--order-items"]'),
          'pos--order-items'
        );
        if (orderItemsController) {
          orderItemsController.clearOrder();
        }
        this.paymentListTarget.innerHTML = '';
        this.paymentContainerTarget.classList.add('hidden');
        this.productGridTarget.classList.remove('hidden');
        console.log('clearing order');

      })
      .catch(error => {
        console.error('Error saving order:', error);
      });

  }

  cancelPayment() {
    console.log('Cancel button clicked');
    this.paymentContainerTarget.classList.add('hidden');
    this.productGridTarget.classList.remove('hidden');
  }
}
