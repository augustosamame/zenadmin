import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['container', 'content', 'video', 'canvas', 'applyButton']
  static values = {
    selectedItemId: String
  }

  connect() {
    this.stream = null;
    this.photoTaken = false;
    this.imageData = null;
  }

  disconnect() {
    this.stopCamera();
  }

  open() {
    const orderItemsController = this.getOrderItemsController();
    if (orderItemsController && orderItemsController.selectedItem) {
      this.selectedItemValue = orderItemsController.selectedItem.dataset.itemId ||
        Date.now().toString();

      orderItemsController.selectedItem.dataset.tempSelected = 'true';
    }

    this.containerTarget.classList.remove('hidden');
    this.contentTarget.classList.remove('hidden');
    this.resetState();
  }

  close(event) {
    event?.preventDefault();
    this.containerTarget.classList.add('hidden');
    this.contentTarget.classList.add('hidden');
    this.stopCamera();
    this.resetState();
    this.restoreSelectedItem();
  }

  resetState() {
    this.photoTaken = false;
    this.applyButtonTarget.disabled = true;
    this.videoTarget.classList.add('hidden');
    this.canvasTarget.classList.add('hidden');
  }

  getOrderItemsController() {
    const element = document.querySelector('[data-controller="pos--order-items"]');
    return this.application.getControllerForElementAndIdentifier(element, 'pos--order-items');
  }

  restoreSelectedItem() {
    const orderItemsController = this.getOrderItemsController();
    if (orderItemsController) {
      const previouslySelectedItem = document.querySelector('[data-temp-selected="true"]');
      if (previouslySelectedItem) {
        previouslySelectedItem.removeAttribute('data-temp-selected');
        orderItemsController.selectItem(previouslySelectedItem);
      }
    }
  }

  async startCamera() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ video: true });
      this.videoTarget.srcObject = this.stream;
      this.videoTarget.classList.remove('hidden');
      this.canvasTarget.classList.add('hidden');
      await this.videoTarget.play();
    } catch (err) {
      console.error('Error accessing camera:', err);
      alert('Error al acceder a la cámara. Por favor, verifique los permisos.');
    }
  }

  stopCamera() {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
    this.videoTarget.srcObject = null;
  }

  takePhoto() {
    if (!this.stream) return;

    const context = this.canvasTarget.getContext('2d');
    this.canvasTarget.width = this.videoTarget.videoWidth;
    this.canvasTarget.height = this.videoTarget.videoHeight;
    context.drawImage(this.videoTarget, 0, 0);

    this.imageData = this.canvasTarget.toDataURL('image/jpeg');

    this.videoTarget.classList.add('hidden');
    this.canvasTarget.classList.remove('hidden');
    this.stopCamera();

    this.photoTaken = true;
    this.applyButtonTarget.disabled = false;
  }

  applyDiscount(event) {
    event.preventDefault();

    if (!this.photoTaken) {
      alert('Por favor tome una foto del DNI primero');
      return;
    }

    const orderItemsController = this.getOrderItemsController();
    if (orderItemsController) {
      this.restoreSelectedItem();
      orderItemsController.applyBirthdayDiscount(this.imageData);
      this.close(event);
    }
  }

  handleBackgroundClick(event) {
    if (event.target === this.containerTarget) {
      this.close(event);
    }
  }

  handleContentClick(event) {
    event.stopPropagation();
  }
}