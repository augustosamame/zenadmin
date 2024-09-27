import { Controller } from "@hotwired/stimulus"
import { emailIcon, whatsappIcon, printIcon } from "../../icons"


export default class extends Controller {
  static targets = ["message", "optionsContainer", "emailInput", "phoneInput"]

  connect() {
    console.log("PostPosSaleController connected")
  }

  setupModal(orderData) {
    console.log('Setting up post-sale modal with order data:', orderData);
    console.log('order_data: ', orderData.order_data)
    console.log('user phone', orderData.order_data.user.phone)
    console.log('user email', orderData.order_data.user.email)
    this.orderData = orderData;
    this.messageTarget.textContent = `La Venta #${orderData.id} se creó satisfactoriamente.`;
    this.updateOptionsContainer();
  }

  updateOptionsContainer() {
    const email = this.orderData.order_data.user.email;
    const phone = this.orderData.order_data.user.phone;
    const hasValidEmail = email && !email.includes('sincorreo.com') && email !== 'generic_customer@devtechperu.com';

    let content = '';

    if (email === 'generic_customer@devtechperu.com') {
      content += this.getPrintButtonHtml();
    } else if (hasValidEmail) {
      content += `
        <div class="col-span-2">
          <p class="text-sm text-gray-600">Comprobante ha sido enviado al correo: ${email}</p>
        </div>
      `;
      if (!phone) {
        content += this.getWhatsAppInputHtml();
      }
      content += this.getPrintButtonHtml();
    } else if (phone) {
      content += this.getWhatsAppButtonHtml(phone);
      content += this.getPrintButtonHtml();
    } else {
      content += `
        <div class="col-span-2 space-y-4">
          <p class="text-sm text-gray-600">El cliente no cuenta con un email o teléfono válido. Puede enviar el comprobante por WhatsApp, por Email o imprimirlo.</p>
          ${this.getEmailInputHtml()}
          ${this.getWhatsAppInputHtml()}
          ${this.getPrintButtonHtml()}
        </div>
      `;
    }

    this.optionsContainerTarget.innerHTML = content;
  }

  getEmailInputHtml() {
    return `
    <div class="space-y-2">
      <input type="email" class="w-full px-3 py-2 border rounded-md" placeholder="Ingrese correo electrónico" data-pos--post-pos-sale-target="emailInput">
      <button data-action="click->pos--post-pos-sale#sendEmail" class="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
        ${emailIcon}
        Enviar por Email
      </button>
    </div>
  `;
  }

  getWhatsAppInputHtml() {
    return `
    <div class="space-y-2">
      <input type="tel" class="w-full px-3 py-2 border rounded-md" placeholder="Ingrese número de WhatsApp" data-pos--post-pos-sale-target="phoneInput">
      <button data-action="click->pos--post-pos-sale#sendWhatsApp" class="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
        ${whatsappIcon}
        Enviar por WhatsApp
      </button>
    </div>
  `;
  }

  getWhatsAppButtonHtml(phone) {
    return `
  <div class="col-span-2">
    <button data-action="click->pos--post-pos-sale#sendWhatsApp" class="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
      ${whatsappIcon}
      Enviar Comprobante por WhatsApp
    </button>
  </div>
  `;
  }

  getPrintButtonHtml() {
    return `
    <div class="col-span-2 mt-4">
      <button data-action="click->pos--post-pos-sale#printInvoice" class="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-gray-600 hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500">
        ${printIcon}
        Imprimir Comprobante
      </button>
    </div>
    `;
  }

  sendEmail() {
    const email = this.emailInputTarget.value;
    if (email) {
      // Make AJAX call to save email and send invoice
      this.saveContactInfo('email', email);
    } else {
      alert("Por favor, ingrese un correo electrónico válido");
    }
  }

  sendWhatsApp(event) {
    let phone;
    let isNewPhone = false;

    // First, check if there's a phone number in the order data
    if (this.orderData && this.orderData.order_data && this.orderData.order_data.user && this.orderData.order_data.user.phone) {
      phone = this.orderData.order_data.user.phone;
    } else if (this.hasPhoneInputTarget) {
      // If we don't have a phone in order data, but we have a phone input, use its value
      phone = this.phoneInputTarget.value;
      isNewPhone = true;
    }

    if (phone) {
      if (isNewPhone) {
        // Only save the contact info if it's a new phone number
        this.saveContactInfo('phone', phone);
      }
      this.openWhatsApp(phone);
    } else {
      this.showMessage('error', "No se pudo encontrar un número de teléfono válido. Por favor, ingrese uno.");
    }
  }

  saveContactInfo(type, value) {
    let success_message = '';
    let url = `/admin/users/${this.orderData.order_data.user.id}/update_contact_info`;
    if (type === "email") {
      url += `?order_to_email=${this.orderData.id}`;
    }
    const data = { [type]: value };

    fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(data)
    })
      .then(response => response.json())
      .then(data => {
        console.log('Contact info updated:', data);
        if (type === "email") {
          success_message = "Correo electrónico se actualizó para el cliente y su comprobante fue enviado."
        } else {
          success_message = "Número de teléfono se actualizó para el cliente."
        }
        this.showMessage('success', success_message);
      })
      .catch(error => {
        console.error('Error updating contact info:', error);
        this.showMessage('error', `Error al actualizar ${type === 'email' ? 'el correo electrónico' : 'el número de teléfono'}. Por favor, inténtelo de nuevo.`);
      });
  }

  showMessage(type, message) {
    const messageElement = document.createElement('div');
    messageElement.textContent = message;
    messageElement.classList.add('p-4', 'rounded-md', 'mb-4', 'text-sm', 'font-medium');

    if (type === 'success') {
      messageElement.classList.add('bg-green-100', 'text-green-700');
    } else {
      messageElement.classList.add('bg-red-100', 'text-red-700');
    }

    // Remove any existing message
    const existingMessage = this.element.querySelector('.message-alert');
    if (existingMessage) {
      existingMessage.remove();
    }

    // Add the new message
    messageElement.classList.add('message-alert');
    this.optionsContainerTarget.insertAdjacentElement('beforebegin', messageElement);

    // Automatically remove the message after 5 seconds
    setTimeout(() => {
      messageElement.remove();
    }, 5000);
  }


  openWhatsApp(phone) {
    phone = phone.replace(/\D/g, '');
    if (!phone.startsWith('51')) {
      phone = '51' + phone;
    }
    const message = encodeURIComponent(`Gracias por su compra. Adjuntamos su comprobante de pago por la Venta #${this.orderData.id}: ${this.orderData.universal_invoice_link}`);
    const url = `https://wa.me/${phone}?text=${message}`;
    window.open(url, '_blank');
  }

  printInvoice() {
    console.log('Printing invoice...');

    // Ensure we have an absolute URL
    let invoiceUrl = this.orderData.universal_invoice_link;
    console.log('invoiceUrl', invoiceUrl);

    // Check if the URL is relative (doesn't start with http:// or https://)
    if (!invoiceUrl.startsWith('http://') && !invoiceUrl.startsWith('https://')) {
      // If it's relative, prepend the origin (protocol + hostname + port)
      invoiceUrl = `${window.location.origin}${invoiceUrl.startsWith('/') ? '' : '/'}${invoiceUrl}`;
    }

    // Open the absolute URL in a new tab
    window.open(invoiceUrl, '_blank');
  }

  closeAndReload() {
    this.element.classList.add('hidden')
    window.location.reload()
  }
}