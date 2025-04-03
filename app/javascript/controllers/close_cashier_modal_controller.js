import { Controller } from '@hotwired/stimulus';
import { useTransition, useClickOutside } from 'stimulus-use';

export default class extends Controller {
  static targets = ['container', 'content', 'template'];

  connect() {
    console.log('close-cashier-modal controller connected');
    useTransition(this, { element: this.containerTarget });
    useClickOutside(this, { element: this.containerTarget });
  }

  open(event) {
    console.log('close-cashier-modal open');

    // Get content ID from the button's data attribute
    const contentId = event.currentTarget.dataset.closeCashierModalContentId;

    // Find the template based on the content ID
    const template = this.templateTargets.find(t => t.dataset.closeCashierModalContentId === contentId);

    if (template) {
      this.contentTarget.innerHTML = template.innerHTML;
      this.containerTarget.classList.remove('hidden');
      this.containerTarget.classList.add('flex'); // Add flex class when opening
    } else {
      console.error('Template not found for content ID:', contentId);
    }
  }

  close(event) {
    event?.preventDefault();
    console.log('close-cashier-modal close');
    this.containerTarget.classList.add('hidden');
    this.containerTarget.classList.remove('flex'); // Remove flex class when closing
  }

  closeWithEsc(event) {
    if (event.key === 'Escape' && !this.containerTarget.classList.contains('hidden')) {
      this.close(event);
    }
  }

}