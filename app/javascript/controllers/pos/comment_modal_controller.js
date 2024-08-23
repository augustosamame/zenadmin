import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['container', 'content', 'textarea'];

  connect() {
    console.log("CommentModalController connected");
  }

  open() {
    console.log("Opening comment modal");
    this.containerTarget.classList.remove('hidden');
    this.contentTarget.classList.remove('hidden');
  }

  close(event = null) {
    if (event) {
      event.preventDefault();
    }
    this.containerTarget.classList.add('hidden');
    this.contentTarget.classList.add('hidden');
  }

  saveComment() {
    const comment = this.contentTarget.querySelector('textarea').value.trim();

    // Store the comment in a hidden input field or directly in the data attribute of the order element
    const orderItemsController = document.querySelector('[data-controller="pos--order-items"]');
    orderItemsController.dataset.comment = comment;

    // Find the "Comentarios" button
    const commentButton = document.querySelector('[data-action="click->pos--comment-modal#open"]');

    if (comment === "") {
      // If the comment is blank, reset the button's appearance to the original state
      if (commentButton) {
        commentButton.innerHTML = `
        ${commentButton.querySelector('svg').outerHTML.replace('text-white', 'text-slate-600').replace('text-white mr-2', 'dark:text-slate-300 mr-2')} Comentarios
      `;
        commentButton.classList.remove('bg-blue-500', 'text-white'); // Revert background and text color
      }
    } else {
      // If a comment is present, update the button's appearance to indicate it
      if (commentButton) {
        commentButton.innerHTML = `
        ${commentButton.querySelector('svg').outerHTML.replace('text-slate-600', 'text-white').replace('dark:text-slate-300', 'text-white mr-2')} Comentarios
      `;
        commentButton.classList.add('bg-blue-500', 'text-white');
        commentButton.classList.remove('bg-white');
      }
    }

    this.close(); // Close the modal
  }
}