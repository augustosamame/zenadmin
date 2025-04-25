import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Transportista form controller connected");
    // this.toggleFieldsOnLoad();
  }

  toggleFieldsOnLoad() {
    const docTypeSelect = this.element.querySelector('select[name="transportista[doc_type]"]');
    if (docTypeSelect) {
      this.toggleDocTypeFields({ target: docTypeSelect });
    }
  }

  toggleDocTypeFields(event) {
    const docType = event.target.value;
    const rucFields = document.querySelectorAll('.ruc-field');
    const dniFields = document.querySelectorAll('.dni-field');

    if (docType === 'ruc') {
      // rucFields.forEach(field => field.style.display = '');
      // dniFields.forEach(field => field.style.display = 'none');
    } else if (docType === 'dni') {
      // rucFields.forEach(field => field.style.display = 'none');
      // dniFields.forEach(field => field.style.display = '');
    }
  }
}
