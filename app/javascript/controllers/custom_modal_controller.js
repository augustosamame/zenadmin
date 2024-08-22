import { Controller } from '@hotwired/stimulus';
import { useTransition, useClickOutside } from 'stimulus-use';

export default class extends Controller {
  static targets = ['container', 'content'];

  connect() {
    useTransition(this, { element: this.contentTarget });
    useClickOutside(this, { element: this.contentTarget });
  }

  openWithContent(title, message, buttons = []) {
    const buttonHtml = buttons.map(button => {
      return `<button type="button" class="btn btn-primary mx-auto block ${button.classes}" data-action="${button.action}">${button.label}</button>`;
    }).join('');

    const fullContent = `
      <div class="text-center">
        <h2 id="modal-title" class="text-2xl font-semibold text-gray-800 dark:text-gray-100">${title}</h2>
        <hr class="my-4 border-gray-300 dark:border-gray-600">
        <p class="text-lg text-gray-700 dark:text-gray-200">${message}</p>
      </div>
      <div class="flex justify-end space-x-4 mt-6">
        ${buttonHtml}
      </div>
    `;

    this.contentTarget.innerHTML = fullContent;
    this.open();
  }

  open() {
    this.containerTarget.classList.remove('hidden');
    this.toggleTransition();
  }

  close(event) {
    event?.preventDefault();
    this.leave();
    this.containerTarget.classList.add('hidden');
  }

  clickOutside(event) {
    const action = event.target.dataset.action;
    if (action == 'click->custom-modal#open' || action == 'click->custom-modal#open:prevent') {
      return;
    }
    this.close(event);
  }

  closeWithEsc(event) {
    if (event.keyCode === 27 && !this.containerTarget.classList.contains('hidden')) {
      this.close(event);
    }
  }
}