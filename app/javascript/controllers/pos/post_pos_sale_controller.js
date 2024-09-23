import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message", "whatsappButton", "phoneInput", "sendInvoiceButton"]

  connect() {
    console.log("PostPosSaleController connected")
    console.log('received order data', this.orderData)
  }

  setupModal(orderData) {
    console.log('Setting up post-sale modal with order data:', orderData);
    console.log('order_data: ', orderData.order_data)
    console.log('user phone', orderData.order_data.user.phone)
    console.log('user email', orderData.order_data.user.email)
    this.orderData = orderData;
    this.messageTarget.textContent = `La Venta #${orderData.id} se creó satisfactoriamente.`;

    if (orderData.order_data.user.phone) {
      this.setupWhatsAppButton(orderData.order_data.user.phone, orderData.id);
    } else if (!orderData.order_data.user.email) {
      this.showPhoneInput(orderData.id);
    }
  }

  setupWhatsAppButton(phone, orderId) {
    const button = document.createElement('button');
    button.textContent = 'Enviar Comprobante por WhatsApp';
    button.className = 'inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-green-600 border border-transparent rounded-md shadow-sm hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500';
    button.dataset.action = 'click->pos--post-pos-sale#openWhatsapp';
    button.dataset.phone = phone;
    button.dataset.orderId = orderId;
    this.whatsappButtonTarget.innerHTML = '';
    this.whatsappButtonTarget.appendChild(button);
  }

  showPhoneInput(orderId) {
    this.phoneInputTarget.classList.remove('hidden');
    this.sendInvoiceButtonTarget.dataset.orderId = orderId;
  }

  openWhatsapp(event) {
    event.preventDefault()
    let phone = event.currentTarget.dataset.phone
    phone = phone.replace(/\D/g, '');
    if (!phone.startsWith('51')) {
      phone = '51' + phone;
    }
    console.log('will send invoice to phone', phone)
    const orderId = event.currentTarget.dataset.orderId
    const message = encodeURIComponent(`Gracias por su compra. Adjuntamos su comprobante de pago por la Venta #${orderId}: ${this.orderData.universal_invoice_link}`)
    const url = `https://wa.me/${phone}?text=${message}`
    window.open(url, '_blank')
  }

  sendInvoice(event) {
    event.preventDefault()
    const phone = this.phoneInputTarget.querySelector('input[type="tel"]').value
    const orderId = event.currentTarget.dataset.orderId
    if (phone) {
      const url = `https://web.whatsapp.com/send?phone=${phone}&text=Here's your invoice for order ${orderId}`
      window.open(url, '_blank')
    } else {
      alert("Please enter a phone number")
    }
  }

  closeAndReload() {
    this.element.classList.add('hidden')
    window.location.reload()
  }
}