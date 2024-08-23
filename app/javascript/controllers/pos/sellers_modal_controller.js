import { Controller } from '@hotwired/stimulus';
import axios from 'axios';

export default class extends Controller {
  static targets = ['container', 'content', 'modalContainer', 'saveButton'];

  connect() {
    console.log("SellersModalController connected");
    this.selectedSellers = [];
    this.manualUpdate = false; // Flag to indicate manual update
  }

  open() {
    this.containerTarget.classList.remove('hidden');
    this.contentTarget.classList.remove('hidden');
    this.loadSellers();
  }

  close(event) {
    event?.preventDefault();
    this.containerTarget.classList.add('hidden');
    this.contentTarget.classList.add('hidden');
  }

  loadSellers() {
    axios.get('/admin/sellers', { headers: { 'Accept': 'application/json' } })
      .then(response => {
        const sellers = response.data;
        const modalContent = this.buildModalContent(sellers);
        this.contentTarget.innerHTML = modalContent;

        // Restore selected sellers and their percentages
        this.restoreSavedSellers();
      })
      .catch(error => {
        console.error('Error fetching sellers:', error);
      });
  }

  buildModalContent(sellers) {
    return `
      <h2 class="text-lg font-semibold text-center dark:text-slate-100">Selecciona a los Vendedores</h2>
      <div class="container p-4 mx-auto mt-6 bg-white border rounded-lg shadow border-slate-300/80 shadow-slate-100 dark:shadow-slate-950 dark:bg-slate-800 dark:border-slate-600/80">
        <ul class="divide-y divide-gray-200 dark:divide-slate-600">
          ${sellers.map(seller => `
            <li class="flex items-center justify-between py-2" data-seller-id="${seller.id}">
              <span class="flex-1 text-gray-800 dark:text-gray-200 truncate">${seller.name}</span>
              <input type="checkbox" class="seller-checkbox h-6 w-6 text-green-500 bg-gray-100 border-gray-300 rounded focus:ring-green-400 focus:ring-opacity-25 dark:bg-slate-600 dark:border-slate-500 dark:focus:ring-slate-500" data-action="change->pos--sellers-modal#toggleSeller">
              <input type="number" class="seller-percentage w-32 ml-4 text-center border border-gray-300 rounded dark:bg-slate-700 dark:border-slate-600 dark:text-white" value="0" min="0" max="100" step="1" data-action="input->pos--sellers-modal#handleManualUpdate">
            </li>
          `).join('')}
        </ul>
      </div>
      <div class="flex justify-end mt-4 space-x-4">
        <button type="button" class="btn btn-secondary" data-action="click->pos--sellers-modal#close">Cancelar</button>
        <button type="button" class="btn btn-primary" data-action="click->pos--sellers-modal#saveSellers">Guardar</button>
      </div>
    `;
  }

  restoreSavedSellers() {
    const savedSellers = JSON.parse(document.querySelector('[data-action="click->pos--sellers-modal#open"]').dataset.sellers || '[]');
    this.selectedSellers = savedSellers.map(seller => seller.id);

    this.selectedSellers.forEach(id => {
      const row = this.contentTarget.querySelector(`li[data-seller-id="${id}"]`);
      const checkbox = row.querySelector('.seller-checkbox');
      checkbox.checked = true;
      const percentageInput = row.querySelector('.seller-percentage');
      const savedSeller = savedSellers.find(seller => seller.id === id);
      percentageInput.value = savedSeller.percentage;
    });

    this.updateCommission();
  }

  toggleSeller(event) {
    this.manualUpdate = false; // Reset manual update flag

    const checkbox = event.target;
    const sellerId = checkbox.closest('li').dataset.sellerId;

    if (checkbox.checked) {
      this.selectedSellers.push(sellerId);
    } else {
      this.selectedSellers = this.selectedSellers.filter(id => id !== sellerId);
    }

    this.updateCommission();
  }

  handleManualUpdate(event) {
    const input = event.target;
    const sellerId = input.closest('li').dataset.sellerId;

    if (!this.selectedSellers.includes(sellerId)) {
      this.selectedSellers.push(sellerId);
      input.closest('li').querySelector('.seller-checkbox').checked = true;
    }

    this.manualUpdate = true; // Set manual update flag
  }

  updateCommission() {
    if (this.manualUpdate) return; // Skip if manually updating

    const selectedCount = this.selectedSellers.length;
    const defaultPercentage = selectedCount > 0 ? (100 / selectedCount).toFixed(2) : 0;

    this.selectedSellers.forEach(id => {
      const row = this.contentTarget.querySelector(`li[data-seller-id="${id}"]`);
      const percentageInput = row.querySelector('.seller-percentage');
      percentageInput.value = defaultPercentage;
    });

    // Reset the percentages for any deselected sellers
    this.contentTarget.querySelectorAll('li').forEach(row => {
      const sellerId = row.dataset.sellerId;
      if (!this.selectedSellers.includes(sellerId)) {
        const percentageInput = row.querySelector('.seller-percentage');
        percentageInput.value = 0;
      }
    });
  }

  saveSellers() {
    console.log('Saving sellers...');
    const sellers = this.selectedSellers.map(id => {
      const row = this.contentTarget.querySelector(`li[data-seller-id="${id}"]`);
      const percentage = row.querySelector('.seller-percentage').value.trim();

      return { id, percentage };
    });

    const totalPercentage = sellers.reduce((sum, seller) => sum + parseFloat(seller.percentage), 0);
    if (totalPercentage !== 100) {
      alert('El total de los porcentajes debe ser 100%.');
      return;
    }

    // Store the sellers data in a data attribute or local storage
    const sellersButton = document.querySelector('[data-action="click->pos--sellers-modal#open"]');
    sellersButton.dataset.sellers = JSON.stringify(sellers);
    sellersButton.innerHTML = `
      ${sellersButton.querySelector('svg').outerHTML} ${sellers.length} Vendedor${sellers.length > 1 ? 'es' : ''} Seleccionado${sellers.length > 1 ? 's' : ''}
    `;
    sellersButton.classList.add('bg-blue-500', 'text-white');

    this.close();
  }
}