import { Controller } from '@hotwired/stimulus'
import axios from 'axios'

export default class extends Controller {
  static targets = ['productGrid', 'paymentContainer', 'remainingAmount', 'paymentMethods', 'paymentList', 'remainingLabel', 'paymentButton', 'total', 'rucSection', 'ruc', 'razonSocial', 'direccion'];

  connect() {
    console.log('Connected to PaymentController!');
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    this.canCreateUnpaidOrders = this.element.dataset.posCanCreateUnpaidOrders === 'true';
  }

  getRucData(customerId) {
    return axios.get(`/admin/customers/${customerId}`, { headers: { 'Accept': 'application/json' } })
      .then(response => {
        console.log('customer data response:', response.data);
        return response.data;
      })
      .catch(error => {
        console.error('Error fetching RUC data:', error);
        return null;
      });
  }

  payOrder() {
    console.log('Pay button clicked');

    // Get the OrderItemsController
    const orderItemsElement = document.querySelector('[data-controller="pos--order-items"]');
    const orderItemsController = this.application.getControllerForElementAndIdentifier(
      orderItemsElement,
      'pos--order-items'
    );

    // Validate all prices
    if (orderItemsController && !orderItemsController.validateAllPrices()) {
      console.log('Price validation failed');
      return; // Stop here if validation fails
    }

    const selectedCustomerId = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedObjectId;
    const selectedRuc = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedRuc;
    if (selectedRuc && selectedRuc.trim() !== '') {
      this.getRucData(selectedCustomerId)
        .then(ruc_data => {
          console.log('response', ruc_data);
          this.rucSectionTarget.classList.remove('hidden');
          this.rucTarget.textContent = `RUC: ${selectedRuc}`;
          this.razonSocialTarget.textContent = `Razón Social: ${ruc_data.factura_razon_social}`;
          this.direccionTarget.textContent = `Dirección: ${ruc_data.factura_direccion}`;
        })
        .catch(error => {
          console.error('Error fetching RUC data:', error);
        });
    }

    const orderItemsTotal = document.querySelector('[data-pos--order-items-target="total"]').textContent.trim();
    const totalAmount = parseFloat(orderItemsTotal.replace('S/', ''));
    if (totalAmount === 0) {
      console.log('Cannot proceed to payment: Total is 0');
      return;
    }

    this.productGridTarget.classList.add('hidden');
    this.paymentContainerTarget.classList.remove('hidden');
    this.updateTotal();
    this.fetchPaymentMethods();
  }

  fetchPaymentMethods() {
    axios.get('/admin/payment_methods', { headers: { 'Accept': 'application/json' } })
      .then(response => {
        const methods = response.data;
        this.paymentMethodsTarget.innerHTML = '';

        methods.forEach(method => {
          const button = document.createElement('button');
          button.classList.add(
            'px-4', 'py-2', 'm-2',
            'bg-white', 'hover:bg-gray-100',
            'text-blue-600', 'font-semibold',
            'border', 'border-blue-600',
            'rounded-lg', 'shadow-sm',
            'transition', 'duration-300', 'ease-in-out',
            'focus:outline-none', 'focus:ring-2', 'focus:ring-blue-500', 'focus:ring-opacity-50',
            'dark:bg-gray-800', 'dark:text-blue-400', 'dark:border-blue-400',
            'dark:hover:bg-gray-700'
          );
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
    const methodName = event.currentTarget.dataset.method;
    const methodId = event.currentTarget.dataset.id;
    let remaining = parseFloat(this.remainingAmountTarget.textContent.replace('S/', ''));
    const paymentAmount = remaining > 0 ? remaining : 0;

    const paymentElement = document.createElement('div');
    paymentElement.classList.add('grid', 'gap-2', 'p-2', 'bg-white', 'rounded', 'shadow-md', 'mb-2', 'dark:bg-gray-700');
    paymentElement.dataset.methodId = methodId;
    paymentElement.dataset.methodName = methodName;

    let gridColumns = 'grid-cols-[2fr_1fr_auto]';
    let innerHtml = `
  <span class="self-center mr-2 w-full">${method}</span>
  <input type="number" class="text-right border-none focus:ring-0 self-center payment-amount w-full" value="${paymentAmount.toFixed(2)}" data-action="input->pos--payment#updateRemaining">
  <button type="button" class="text-red-500 self-center ml-2" data-action="click->pos--payment#removePayment">✖</button>
`;

    if (methodName === "card") {
      gridColumns = 'grid-cols-[2fr_2fr_1fr_auto]';
      innerHtml = `
    <span class="self-center mr-2 w-full">${method}</span>
    <div class="flex items-center w-full">
      <label for="tx${this.getUniqueId()}" class="mr-2 whitespace-nowrap">Tx #</label>
      <input type="text" id="tx${this.getUniqueId()}" class="w-full border border-gray-300 rounded px-2 py-1 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 tx-input" >
    </div>
    <input type="number" class="text-right border-none focus:ring-0 self-center payment-amount w-[104%]" value="${paymentAmount.toFixed(2)}" data-action="input->pos--payment#updateRemaining">
    <button type="button" class="text-red-500 self-center" data-action="click->pos--payment#removePayment">✖</button>
  `;
    }

    paymentElement.classList.add(gridColumns);
    paymentElement.innerHTML = innerHtml;

    this.paymentListTarget.appendChild(paymentElement);
    this.updateRemaining();
  }

  getUniqueId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  removePayment(event) {
    const paymentElement = event.currentTarget.closest('div');
    paymentElement.remove();
    this.updateRemaining();
  }

  updateTotal() {
    const orderItemsTotal = document.querySelector('[data-pos--order-items-target="total"]').textContent.trim();
    this.totalTarget.textContent = orderItemsTotal;
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

    const totalOrderAmount = parseFloat(this.totalTarget.textContent.replace('S/', ''));
    let totalPayments = 0;

    this.paymentListTarget.querySelectorAll('.payment-amount').forEach(input => {
      totalPayments += parseFloat(input.value);
    });

    if (!this.canCreateUnpaidOrders && totalPayments < totalOrderAmount) {
      this.showErrorModal(
        'Error',
        'El monto total de los métodos de pago debe coincidir con el monto total del pedido.',
        [{ label: 'OK', classes: 'btn btn-primary', action: 'click->custom-modal#close' }]
      );
      return;
    }

    const selectedRuc = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedRuc;
    console.log('selectedRuc', selectedRuc);

    const rucCheckbox = document.querySelector('#confirm-factura');
    console.log(rucCheckbox);
    const isRucChecked = rucCheckbox ? rucCheckbox.checked : false;
    console.log('is_ruc_checked', isRucChecked);

    const orderItems = document.querySelectorAll('[data-pos--order-items-target="items"] div.flex');
    const orderItemsAttributes = [];

    orderItems.forEach(item => {
      const quantity = item.querySelector('[data-item-quantity]').textContent.trim();
      const price = item.querySelector('.editable-price').textContent.replace('S/ ', '').trim();

      orderItemsAttributes.push({
        product_id: item.dataset.productId,
        quantity: quantity,
        price_cents: parseInt(price * 100, 10),
        discounted_price_cents: 0,
        currency: 'PEN',
        is_loyalty_free: item.dataset.itemLoyaltyFree === 'true'
      });
    });

    const payments = [];
    this.paymentListTarget.querySelectorAll('.payment-amount').forEach(input => {
      const paymentElement = input.closest('div');
      const paymentMethod = paymentElement.dataset.methodName;
      const payment = {
        amount_cents: parseInt(input.value * 100, 10),
        payment_method_id: paymentElement.dataset.methodId,
        user_id: 1,
        payable_type: 'Order',
      };

      if (paymentMethod === 'card') {
        const txInput = paymentElement.querySelector('.tx-input');
        if (txInput) {
          payment.processor_transacion_id = txInput.value;
        }
      }

      payments.push(payment);
    });

    const selectedCustomerId = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedObjectId;
    console.log('selectedCustomerId', selectedCustomerId);
    const comment = document.querySelector('[data-controller="pos--order-items"]').dataset.comment || '';
    const sellersButton = document.querySelector('[data-action="click->pos--sellers-modal#open"]');
    const selectedSellers = JSON.parse(sellersButton.dataset.sellers || '[]');

    const orderData = {
      order: {
        stage: 'confirmed',
        user_id: selectedCustomerId,
        total_price: parseFloat(this.totalTarget.textContent.replace('S/', '')),
        total_discount: 0,
        shipping_price: 0,
        currency: 'PEN',
        wants_factura: selectedRuc && isRucChecked,
        payment_status: 'paid',
        seller_note: comment,
        order_items_attributes: orderItemsAttributes,
        payments_attributes: payments,
        sellers_attributes: selectedSellers
      }
    };

    axios.post('/admin/orders', orderData, {
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': this.csrfToken
      }
    })
      .then(response => {
        console.log('Order save response:', response);
        if (response.status !== 200 || response.data.status === 'error') {
          let errorMessage = 'Hubo un error al guardar la venta. Por favor, inténtalo de nuevo.';
          if (response.data.status === 'error') {
            errorMessage = `Hubo un error al guardar la venta: ${response.data.errors.join(', ')}`;
          }
          this.showErrorModal('Error', errorMessage);
          return;
        }

        // Handle success
        this.showPostSaleModal(response.data);
      })
      .catch(error => {
        console.error('Error saving order:', error);
        this.showErrorModal('Error', 'Hubo un error al guardar la venta. Por favor, inténtalo de nuevo.', [
          { label: 'OK', classes: 'btn btn-primary', action: 'click->custom-modal#close' }
        ]);
      });
  }

  showPostSaleModal(orderData) {
    console.log('showing postsalemodal with orderData', orderData)
    const modal = document.getElementById('post-sale-modal');
    const controller = this.application.getControllerForElementAndIdentifier(modal, 'pos--post-pos-sale');

    if (controller) {
      // Pass the order data to the PostPosSaleController
      controller.setupModal(orderData);
      modal.classList.remove('hidden');
    } else {
      console.error('PostPosSaleController not found');
    }
  }

  showErrorModal(title, message, buttons) {
    const customModal = document.querySelector('[data-controller="custom-modal"]');
    if (customModal) {
      const customModalController = this.application.getControllerForElementAndIdentifier(customModal, 'custom-modal');
      if (customModalController) {
        customModalController.openWithContent(title, message, buttons);
      } else {
        console.error('CustomModalController not found!');
      }
    } else {
      console.error('Custom modal element not found!');
    }
  }

  cancelPayment() {
    console.log('Cancel button clicked');
    this.paymentContainerTarget.classList.add('hidden');
    this.productGridTarget.classList.remove('hidden');
  }
}