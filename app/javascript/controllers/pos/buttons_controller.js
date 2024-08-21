import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['draftButtonContainer'];

  connect() {
    console.log('Connected to ButtonsController!', this.element);
    this.checkForDraftOrder();
  }

  showDraftButton() {
    // Show the anchor element inside the draftButtonContainer
    console.log('Showing draft button...');
    const draftButton = this.draftButtonContainerTarget.querySelector('a');
    console.log('Draft Button Container:', this.draftButtonContainerTarget);
    console.log('Draft Button:', draftButton);
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
    console.log('Checking for draft order...');
    const draftData = JSON.parse(sessionStorage.getItem('draftOrder') || '{}');
    console.log('Draft Data:', draftData);

    const currentItemCount = this.element.querySelectorAll('[data-pos--order-items-target="items"] div.flex').length;
    const draftItemCount = draftData.order_items_attributes ? draftData.order_items_attributes.length : 0;
    console.log('Current Item Count:', currentItemCount);
    console.log('Draft Item Count:', draftItemCount);

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