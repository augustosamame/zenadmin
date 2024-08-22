import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['draftButtonContainer'];

  connect() {
    console.log('Connected to the POS buttons controller!');
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


}