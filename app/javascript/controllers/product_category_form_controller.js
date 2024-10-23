import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['name', 'status', 'parent']

  connect() {
    console.log('Connected to ProductCategoryFormController');
  }

  cancel(event) {
    event.preventDefault();
    // Redirige a la página de índice de categorías de productos
    window.location.href = '/admin/product_categories';
  }

  // Puedes agregar métodos adicionales para interacciones dinámicas si es necesario
}
