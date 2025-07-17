import { Controller } from '@hotwired/stimulus'
import axios from 'axios'

export default class extends Controller {
  static targets = ['productGrid', 'paymentContainer', 'remainingAmount', 'paymentMethods', 'paymentList', 'remainingLabel', 'paymentButton', 'total', 'totalDiscount', 'rucSection', 'ruc', 'razonSocial', 'direccion', 'paymentSection', 'automaticDelivery', 'notaDeVenta'];

  static values = {
    creditPaymentMethodId: Number
  }

  connect() {
    console.log('Connected to PaymentController!');
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    // Get the setting from data attribute
    this.settingAllowsUnpaidOrders = this.element.dataset.posCanCreateUnpaidOrders === 'true';

    // Initialize based on checkbox if it exists, otherwise use setting
    const automaticPaymentCheckbox = document.getElementById('automatic-payment');
    this.canCreateUnpaidOrders = automaticPaymentCheckbox ?
      !automaticPaymentCheckbox.checked :
      this.settingAllowsUnpaidOrders;

    this.maxTotalSaleWithoutCustomer = parseFloat(document.getElementById('max-total-sale-without-customer').dataset.value);
    this.orderPaymentStatus = 'unpaid';
    this.creditPaymentMethodId = parseInt(this.element.dataset.creditPaymentMethodId);
    console.log('maxTotalSaleWithoutCustomer', this.maxTotalSaleWithoutCustomer);
    this.isProcessing = false;
    this.priceListsEnabled = window.globalSettings && window.globalSettings.feature_flag_price_lists === true;
    
    // Add event listener for the "Generar Nota de Venta" checkbox
    const notaDeVentaCheckbox = document.getElementById('nota-de-venta');
    if (notaDeVentaCheckbox) {
      notaDeVentaCheckbox.addEventListener('change', this.toggleFactura.bind(this));
    }
  }

  togglePaymentSection(event) {
    const showPaymentSection = event.target.checked;
    if (showPaymentSection) {
      this.paymentSectionTarget.classList.remove('hidden');
      this.fetchPaymentMethods();
    } else {
      this.paymentSectionTarget.classList.add('hidden');
      this.paymentListTarget.innerHTML = '';
    }
    
    // Toggle the "Emitir factura" checkbox to the opposite state
    const confirmFacturaCheckbox = document.getElementById('confirm-factura');
    if (confirmFacturaCheckbox) {
      confirmFacturaCheckbox.checked = !showPaymentSection;
    }
  }
  
  toggleAutomaticPayment(event) {
    // Toggle the automatic payment checkbox to the opposite state
    const automaticPaymentCheckbox = document.getElementById('automatic-payment');
    if (automaticPaymentCheckbox) {
      automaticPaymentCheckbox.checked = !event.target.checked;
      // Trigger the change event to update the UI
      const changeEvent = new Event('change');
      automaticPaymentCheckbox.dispatchEvent(changeEvent);
    }
  }
  
  toggleFactura(event) {
    // Toggle the "Emitir factura" checkbox to the opposite state
    const confirmFacturaCheckbox = document.getElementById('confirm-factura');
    if (confirmFacturaCheckbox) {
      confirmFacturaCheckbox.checked = !event.target.checked;
    }
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

    if (!this.validatePrices()) {
      console.log('Validation failed, stopping payment process');
      return;
    }
    if (!this.validateCustomerForLargeOrder()) return;

    const selectedUserId = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedUserId;
    const selectedCustomerObjectId = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedObjectId;
    const selectedRuc = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedRuc;
    if (selectedRuc && selectedRuc.trim() !== '') {
      this.getRucData(selectedCustomerObjectId)
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

    const orderItemsDiscountAmount = document.querySelector('[data-pos--order-items-target="discountAmount"]').textContent.trim();
    const discountAmount = parseFloat(orderItemsDiscountAmount.replace(/\(S\/\s*|\)/g, ''));

    this.productGridTarget.classList.add('hidden');
    this.paymentContainerTarget.classList.remove('hidden');
    this.updateTotal();
    this.fetchPaymentMethods();
  }

  validatePrices() {
    const orderItemsElement = document.querySelector('[data-controller="pos--order-items"]');
    const orderItemsController = this.application.getControllerForElementAndIdentifier(
      orderItemsElement,
      'pos--order-items'
    );

    if (!orderItemsController.validateAllPrices()) {
      console.log('Price validation failed');
      return false;
    }

    // Add zero price/quantity validation here
    if (!orderItemsController.validateNoItemsWithZeroPriceOrZeroQuantity()) {
      console.log('Zero price/quantity validation failed');
      return false;
    }

    return true;
  }

  validateCustomerForLargeOrder() {
    const orderItemsTotal = document.querySelector('[data-pos--order-items-target="total"]').textContent.trim();
    const totalAmount = parseFloat(orderItemsTotal.replace('S/', ''));

    if (totalAmount >= this.maxTotalSaleWithoutCustomer) {
      const selectedCustomerId = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedUserId;
      const genericCustomerId = '1'; // Assuming 1 is the ID of the generic customer, adjust if needed

      if (!selectedCustomerId || selectedCustomerId === genericCustomerId) {
        this.showErrorModal(
          'Error de Validación',
          `Las ventas sobre ${this.maxTotalSaleWithoutCustomer} soles requieren identificar al cliente con su DNI o RUC. Por favor escoja un cliente.`,
          [{ label: 'OK', classes: 'btn btn-primary', action: 'click->custom-modal#close' }]
        );
        return false;
      }
    }
    return true;
  }

  validateCustomerForCreditSale() {
    const selectedCustomerId = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedUserId;
    const genericCustomerId = '1'; // Assuming 1 is the ID of the generic customer, adjust if needed
    
    // Check if the can_create_unpaid_orders checkbox is checked
    const canCreateUnpaidOrders = this.canCreateUnpaidOrders;
    
    // Check if any payment method of type "credit" is selected
    const hasCreditPayment = Array.from(this.paymentListTarget.children).some(
      payment => payment.dataset.methodType === 'credit' || payment.dataset.methodName === 'credit'
    );
    
    if ((canCreateUnpaidOrders || hasCreditPayment) && (!selectedCustomerId || selectedCustomerId === genericCustomerId)) {
      console.log('Selected customer ID:', selectedCustomerId);
      console.log('canCreateUnpaidOrders:', canCreateUnpaidOrders);
      console.log('hasCreditPayment:', hasCreditPayment);
      this.showErrorModal(
        'Error de Validación',
        'Se debe seleccionar a un cliente para ventas al crédito.',
        [{ label: 'OK', classes: 'btn btn-primary', action: 'click->custom-modal#close' }]
      );
      return false;
    }
    
    return true;
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
          button.dataset.methodType = method.payment_method_type;
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
    const methodType = event.currentTarget.dataset.methodType;
    const methodId = event.currentTarget.dataset.id;
    let remaining = parseFloat(this.remainingAmountTarget.textContent.replace('S/', ''));
    const paymentAmount = remaining > 0 ? remaining : 0;

    const paymentElement = document.createElement('div');
    paymentElement.classList.add('grid', 'gap-2', 'p-2', 'bg-white', 'rounded', 'shadow-md', 'mb-2', 'dark:bg-gray-700');
    paymentElement.dataset.methodId = methodId;
    paymentElement.dataset.methodName = methodName;
    paymentElement.dataset.methodType = methodType;

    let gridColumns = 'grid-cols-[2fr_1fr_auto]';
    let innerHtml = `
      <span class="self-center mr-2 w-full">${method}</span>
      <input type="number" class="self-center w-full text-right border-none focus:ring-0 payment-amount" value="${paymentAmount.toFixed(2)}" data-action="input->pos--payment#updateRemaining">
      <button type="button" class="self-center ml-2 text-red-500" data-action="click->pos--payment#removePayment">✖</button>
    `;

    if (methodName === "card" || methodName === "wallet" || methodType === "bank") {
      gridColumns = 'grid-cols-[2fr_2fr_1fr_auto]';
      innerHtml = `
        <span class="self-center mr-2 w-full">${method}</span>
        <div class="flex items-center w-full">
          <label for="tx${this.getUniqueId()}" class="mr-2 whitespace-nowrap">Tx #</label>
          <input type="text" id="tx${this.getUniqueId()}" class="px-2 py-1 w-full rounded border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 tx-input" >
        </div>
        <input type="number" class="text-right border-none focus:ring-0 self-center payment-amount w-[104%]" value="${paymentAmount.toFixed(2)}" data-action="input->pos--payment#updateRemaining">
        <button type="button" class="self-center text-red-500" data-action="click->pos--payment#removePayment">✖</button>
      `;
    }

    if (methodName === 'credit') {
      gridColumns = 'grid-cols-[2fr_2fr_1fr_auto]';
      innerHtml = `
        <span class="self-center mr-2 w-full">${method}</span>
        <div class="flex items-center w-full">
          <label for="credit-date${this.getUniqueId()}" class="mr-2 whitespace-nowrap">Fecha Cuota</label>
          <input type="date" id="credit-date${this.getUniqueId()}" class="px-2 py-1 w-full rounded border border-gray-300 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 credit-date-input" >
        </div>
        <input type="number" class="text-right border-none focus:ring-0 self-center payment-amount w-[104%]" value="${paymentAmount.toFixed(2)}" data-action="input->pos--payment#updateRemaining">
        <button type="button" class="self-center text-red-500" data-action="click->pos--payment#removePayment">✖</button>
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
    const orderItemsDiscountAmount = document.querySelector('[data-pos--order-items-target="discountAmount"]').textContent.trim();
    const discountAmount = parseFloat(orderItemsDiscountAmount.replace(/\(S\/\s*|\)/g, ''));
    this.totalDiscountTarget.textContent = discountAmount;
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

    this.remainingLabelTarget.textContent = remaining >= 0 ? 'Restante:' : 'Cambio:';
  }

  saveOrder(event) {
    const button = event.currentTarget;
    if (button.disabled) return;

    button.disabled = true;
    button.classList.add('opacity-50', 'cursor-not-allowed');
    button.innerHTML = '<span class="spinner"></span> Procesando...';

    // Store the original text to restore it if there's an error
    const originalText = 'Crear Venta';

    // Check if a customer is selected for credit sales
    if (!this.validateCustomerForCreditSale()) {
      this.resetButton(button, originalText);
      return;
    }

    const totalOrderAmount = parseFloat(this.totalTarget.textContent.replace('S/', ''));
    const totalDiscountAmount = parseFloat(this.totalDiscountTarget.textContent.replace(/\(S\/\s*|\)/g, ''));
    let totalPayments = 0;

    this.paymentListTarget.querySelectorAll('.payment-amount').forEach(input => {
      totalPayments += parseFloat(input.value);
    });

    if (!(totalPayments < totalOrderAmount)) {
      this.orderPaymentStatus = 'paid';
    }

    // Get the automatic payment checkbox state
    const automaticPaymentCheckbox = document.getElementById('automatic-payment');
    const isAutomaticPaymentChecked = automaticPaymentCheckbox ? automaticPaymentCheckbox.checked : false;

    // Only allow unpaid orders if canCreateUnpaidOrders is true AND automatic payment is NOT checked
    if (totalPayments < totalOrderAmount && (!this.canCreateUnpaidOrders || isAutomaticPaymentChecked)) {
      this.showErrorModal(
        'Error',
        'El monto total de los métodos de pago debe coincidir con el monto total del pedido.',
        [{ label: 'OK', classes: 'btn btn-primary', action: 'click->custom-modal#close' }]
      );
      this.resetButton(button, originalText);
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

      const itemData = {
        product_id: item.dataset.productId,
        quantity: quantity,
        price_cents: Math.round(parseFloat(price) * 100),
        discounted_price_cents: 0,
        currency: 'PEN',
        is_loyalty_free: item.dataset.itemLoyaltyFree === 'true',
        product_pack_id: item.dataset.productPackId || null
      };

      // Add birthday discount data if present
      if (item.hasAttribute('data-birthday-discount')) {
        itemData.birthday_discount = true;
        itemData.birthday_image = item.getAttribute('data-birthday-image');
      }

      orderItemsAttributes.push(itemData);
    });

    const payments = [];
    // No payments, and we can create unpaid orders
    if (this.paymentListTarget.querySelectorAll('.payment-amount').length === 0 && this.canCreateUnpaidOrders) {
      const payment = {
        amount_cents: parseInt(totalOrderAmount * 100, 10),
        payment_method_id: this.creditPaymentMethodId,
        user_id: 1, // Use the selected customer's ID instead of hardcoding to 1
        payable_type: 'Order'
      };
      payments.push(payment);
    }
    // There are payments (regular flow)
    this.paymentListTarget.querySelectorAll('.payment-amount').forEach(input => {
      const paymentElement = input.closest('div');
      const paymentMethod = paymentElement.dataset.methodName;
      const methodType = paymentElement.dataset.methodType;
      const payment = {
        amount_cents: parseInt(input.value * 100, 10),
        payment_method_id: paymentElement.dataset.methodId,
        user_id: 1,
        payable_type: 'Order',
      };

      if (paymentMethod === 'card' || paymentMethod === 'wallet' || methodType === 'bank') {
        const txInput = paymentElement.querySelector('.tx-input');
        if (txInput) {
          payment.processor_transacion_id = txInput.value;
        }
      }

      if (paymentMethod === 'credit') {
        const creditDateInput = paymentElement.querySelector('.credit-date-input');
        if (creditDateInput) {
          payment.due_date = creditDateInput.value;
        }
      }

      payments.push(payment);
    });

    const selectedCustomerId = document.querySelector('[data-action="click->customer-table-modal#open"]').dataset.selectedUserId;
    const clienteButton = document.querySelector('[data-action="click->customer-table-modal#open"]');
    const selectedPriceListId = this.priceListsEnabled ? clienteButton.dataset.selectedPriceListId : null;
    console.log('selectedCustomerId (user_id):', selectedCustomerId);
    console.log('selectedPriceListId:', selectedPriceListId);
    console.log('All button data attributes:', clienteButton.dataset);
    
    const comment = document.querySelector('[data-controller="pos--order-items"]').dataset.comment || '';
    const sellersButton = document.querySelector('[data-action="click->pos--sellers-modal#open"]');
    const selectedSellers = sellersButton ? JSON.parse(sellersButton.dataset.sellers || '[]') : [];

    console.log('totalOrderAmount', totalOrderAmount);
    console.log('totalDiscountAmount', totalDiscountAmount);

    // Generate a unique request ID
    this.requestId = Date.now().toString();

    const orderDateInput = document.getElementById('pos-order-date');

    const orderData = {
      order: {
        stage: 'confirmed',
        user_id: selectedCustomerId,
        price_list_id: this.priceListsEnabled ? selectedPriceListId : null,
        total_price: totalOrderAmount,
        total_discount: totalDiscountAmount,
        total_original_price: totalOrderAmount + totalDiscountAmount,
        shipping_price: 0,
        currency: 'PEN',
        wants_factura: selectedRuc && isRucChecked,
        payment_status: this.orderPaymentStatus,
        seller_note: comment,
        order_items_attributes: orderItemsAttributes,
        payments_attributes: payments,
        sellers_attributes: selectedSellers,
        request_id: this.requestId,
        fast_stock_transfer_flag: this.hasAutomaticDeliveryTarget ? this.automaticDeliveryTarget.checked : true,
        order_date: orderDateInput?.value || null,
        nota_de_venta: this.hasNotaDeVentaTarget ? this.notaDeVentaTarget.checked : false
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
          this.resetButton(button, originalText);
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
        this.resetButton(button, originalText);
      });
  }

  resetButton(button, originalText) {
    button.disabled = false;
    button.classList.remove('opacity-50', 'cursor-not-allowed');
    button.innerHTML = originalText;
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