import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['draftButtonContainer'];

  connect() {
    console.log('Connected to the POS buttons controller!');
    // setup listeners for calls from other controllers
    this.element.addEventListener('clear-selected-user', this.clearSelectedUser.bind(this));

    this.checkForDraftOrder();
  }

  showDraftButton() {
    // Show the anchor element inside the draftButtonContainer
    const draftButton = this.draftButtonContainerTarget.querySelector('a');
    if (draftButton) {
      draftButton.classList.remove('hidden');
    }
  }

  hideDraftButton() {
    // Hide the anchor element inside the draftButtonContainer
    const draftButton = this.draftButtonContainerTarget.querySelector('a');
    if (draftButton) {
      draftButton.classList.add('hidden');
    }
  }


  checkForDraftOrder() {
    const draftData = JSON.parse(sessionStorage.getItem('draftOrder') || '{}');

    const currentItemCount = this.element.querySelectorAll('[data-pos--order-items-target="items"] div.flex').length;
    const draftItemCount = draftData.order_items_attributes ? draftData.order_items_attributes.length : 0;
    
    if (currentItemCount === 0 && draftItemCount > 0) {
      this.showDraftButton();
    } else {
      this.hideDraftButton();
    }
  }

  loadDraft(event) {
    event.preventDefault();

    const draftData = JSON.parse(sessionStorage.getItem('draftOrder') || '{}');
    if (draftData.order_items_attributes) {
      const orderItemsElement = document.querySelector('[data-controller="pos--order-items"]');
      const orderItemsController = this.application.getControllerForElementAndIdentifier(orderItemsElement, 'pos--order-items');

      draftData.order_items_attributes.forEach(item => {
        orderItemsController.addDraftItem(item);
      });
    }

    this.hideDraftButton();
  }

  clearSelectedUser() {
    console.log('Clearing selected user...');

    const clienteButton = document.querySelector('[data-action="click->customer-table-modal#open"]');

    const originalIcon = `
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" role="img" aria-labelledby="aflku4s3u7inp91d48twlttjbap2mjj9" class="stroke-current w-4 h-4 text-slate-600 dark:text-slate-300 mr-2">
        <title id="aflku4s3u7inp91d48twlttjbap2mjj9">User</title>
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"></path>
      </svg>
    `;

    // Reset button content to original icon and text
    clienteButton.innerHTML = `${originalIcon} Cliente`;

    // Reset button styles to original
    clienteButton.classList.remove('bg-blue-500', 'text-white');
    clienteButton.classList.add('text-black', 'bg-white', 'border', 'border-gray-300', 'dark:bg-slate-600', 'dark:text-white', 'dark:border-slate-400');

    // Remove selected customer data
    clienteButton.removeAttribute('data-selected-object-id');
    console.log('Selected user cleared.');
  }


}