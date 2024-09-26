import { Controller } from "@hotwired/stimulus"

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
    const hasValidEmail = email && !email.includes('sincorreo.com');

    let content = '';

    if (hasValidEmail) {
      content += `
        <div class="col-span-2">
          <p class="text-sm text-gray-600">Comprobante ha sido enviado al correo: ${email}</p>
        </div>
      `;
      if (!phone) {
        content += this.getWhatsAppInputHtml();
      }
    } else if (phone) {
      content += this.getWhatsAppButtonHtml(phone);
    } else {
      content += `
        <div class="col-span-2 space-y-4">
          <p class="text-sm text-gray-600">El cliente no cuenta con un email o teléfono válido. Puede enviar el comprobante por WhatsApp o por Email.</p>
          ${this.getEmailInputHtml()}
          ${this.getWhatsAppInputHtml()}
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
        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"></path><path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"></path></svg>
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
        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/></svg>
        Enviar por WhatsApp
      </button>
    </div>
  `;
  }

  getWhatsAppButtonHtml(phone) {
    return `
    <div class="col-span-2">
      <button data-action="click->pos--post-pos-sale#sendWhatsApp" data-pos--post-pos-sale-phone-param="${phone}" class="w-full inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/></svg>
        Enviar Comprobante por WhatsApp
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
    let phone = event.currentTarget.dataset.posPostPosPhoneParam;
    if (!phone) {
      phone = this.phoneInputTarget.value;
    }
    if (phone) {
      // Make AJAX call to save phone and send invoice via WhatsApp
      this.saveContactInfo('phone', phone);
      this.openWhatsApp(phone);
    } else {
      alert("Por favor, ingrese un número de teléfono válido");
    }
  }

  saveContactInfo(type, value) {
    const url = `/admin/users/${this.orderData.order_data.user.id}/update_contact_info`;
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
        // You might want to update the UI or show a success message here
      })
      .catch(error => {
        console.error('Error updating contact info:', error);
        // Handle the error, maybe show an alert to the user
      });
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

  closeAndReload() {
    this.element.classList.add('hidden')
    window.location.reload()
  }
}