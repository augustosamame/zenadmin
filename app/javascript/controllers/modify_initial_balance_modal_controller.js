import { Controller } from '@hotwired/stimulus';
import { useTransition, useClickOutside } from 'stimulus-use';

export default class extends Controller {
  static targets = ['container', 'content', 'template'];

  connect() {
    console.log('modify-initial-balance-modal controller connected');
    console.log('Template targets:', this.templateTargets.length);
    useTransition(this, { element: this.containerTarget });
    useClickOutside(this, { element: this.containerTarget });
    
    // Add click outside handler
    document.addEventListener('click', this.handleClickOutside.bind(this));
  }
  
  disconnect() {
    // Clean up event listener
    document.removeEventListener('click', this.handleClickOutside.bind(this));
  }
  
  handleClickOutside(event) {
    if (!this.containerTarget.classList.contains('hidden') && 
        !this.containerTarget.contains(event.target) && 
        !event.target.closest('[data-action*="modify-initial-balance-modal#open"]')) {
      this.close();
    }
  }

  open(event) {
    console.log('modify-initial-balance-modal open');

    // Get content ID from the button's data attribute
    const contentId = event.currentTarget.dataset.modifyInitialBalanceModalContentId;
    console.log('Content ID:', contentId);

    // Find the template based on the content ID
    console.log('Available templates:', this.templateTargets.map(t => t.dataset.modifyInitialBalanceModalContentId));
    const template = this.templateTargets.find(t => t.dataset.modifyInitialBalanceModalContentId === contentId);

    if (template) {
      console.log('Template found');
      this.contentTarget.innerHTML = template.innerHTML;
      this.containerTarget.classList.remove('hidden');
      this.containerTarget.classList.add('flex'); // Add flex class when opening
    } else {
      console.error('Template not found for content ID:', contentId);
    }
  }

  close(event) {
    if (event) event.preventDefault();
    console.log('modify-initial-balance-modal close');
    this.containerTarget.classList.add('hidden');
    this.containerTarget.classList.remove('flex'); // Remove flex class when closing
  }

  closeWithEsc(event) {
    if (event.key === 'Escape' && !this.containerTarget.classList.contains('hidden')) {
      this.close();
    }
  }

  submit(event) {
    // Form will submit normally, this is just a hook for any additional logic
    console.log('modify-initial-balance-modal submit');
    // The modal will be closed by the redirect after form submission
  }
}
