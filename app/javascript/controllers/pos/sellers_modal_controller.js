import { Controller } from '@hotwired/stimulus';
import axios from 'axios';

export default class extends Controller {
  static targets = ['container', 'content', 'modalContainer', 'saveButton', 'remainingAmount'];

  connect() {
    console.log("SellersModalController connected");
    console.log("Content Target:", this.contentTarget);
    console.log("Modal Container Target:", this.modalContainerTarget);
    this.selectedSellers = [];
    this.manualUpdate = false;
    this.setupInputFields();
  }

  setupInputFields() {
    this.element.querySelectorAll('.seller-percentage, .seller-amount').forEach(input => {
      input.addEventListener('focus', this.handleInputFocus.bind(this));
      input.addEventListener('blur', this.handleInputBlur.bind(this));
    });
  }

  handleInputFocus(event) {
    event.target.select();
  }

  handleInputBlur(event) {
    const value = parseFloat(event.target.value) || 0;
    event.target.value = value.toFixed(2);
  }

  clearSelections() {
    this.selectedSellers = [];
    this.contentTarget.querySelectorAll('.seller-checkbox').forEach(checkbox => {
      checkbox.checked = false;
    });
    this.contentTarget.querySelectorAll('.seller-percentage').forEach(input => {
      input.value = '0';
    });
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
        this.modalContainerTarget.innerHTML = modalContent;

        // Restore selected sellers and their percentages
        this.restoreSavedSellers();
      })
      .catch(error => {
        console.error('Error fetching sellers:', error);
      });
  }

  buildModalContent(sellers) {
    const totalAmount = this.getTotalAmount();
    return `
      <div class="container p-4 mx-auto mt-6 bg-white border rounded-lg shadow border-slate-300/80 shadow-slate-100 dark:shadow-slate-950 dark:bg-slate-800 dark:border-slate-600/80">
        <div class="mb-4">
          <div class="text-lg font-semibold text-gray-700 dark:text-gray-300">
            Monto total: <span data-pos--sellers-modal-target="totalAmount">S/ ${totalAmount.toFixed(2)}</span>
          </div>
          <div class="text-lg font-semibold text-gray-700 dark:text-gray-300">
            Monto restante: <span data-pos--sellers-modal-target="remainingAmount">S/ ${totalAmount.toFixed(2)}</span>
          </div>
        </div>
        <table class="w-full">
          <thead>
            <tr class="text-left text-gray-600 dark:text-gray-300">
              <th class="py-2">Nombre</th>
              <th class="py-2 text-center">Seleccionado</th>
              <th class="py-2 text-center">%</th>
              <th class="py-2 text-center">S/</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-slate-600">
            ${sellers.map(seller => `
              <tr class="py-2" data-seller-id="${seller.id}">
                <td class="py-2">
                  <span class="text-gray-800 dark:text-gray-200 truncate">${seller.name}</span>
                </td>
                <td class="py-2 text-center">
                  <input type="checkbox" class="seller-checkbox h-6 w-6 text-green-500 bg-gray-100 border-gray-300 rounded focus:ring-green-400 focus:ring-opacity-25 dark:bg-slate-600 dark:border-slate-500 dark:focus:ring-slate-500" data-action="change->pos--sellers-modal#toggleSeller">
                </td>
                <td class="py-2 text-center">
                  <input type="number" class="seller-percentage w-24 text-center border border-gray-300 rounded dark:bg-slate-700 dark:border-slate-600 dark:text-white" value="0" min="0" max="100" step="1" data-action="input->pos--sellers-modal#handlePercentageUpdate">
                </td>
                <td class="py-2 text-center">
                  <input type="text" 
                         class="seller-amount w-28 text-center border border-gray-300 rounded dark:bg-slate-700 dark:border-slate-600 dark:text-white" 
                         value="0.00" 
                         inputmode="decimal"
                         pattern="[0-9]*[.]?[0-9]{0,2}"
                         data-action="input->pos--sellers-modal#handleAmountUpdate">
                </td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>
    `;
  }

  restoreSavedSellers() {
    const savedSellers = JSON.parse(document.querySelector('[data-action="click->pos--sellers-modal#open"]').dataset.sellers || '[]');
    this.selectedSellers = savedSellers.map(seller => seller.id);

    this.selectedSellers.forEach(id => {
      const row = this.modalContainerTarget.querySelector(`tr[data-seller-id="${id}"]`);
      const checkbox = row.querySelector('.seller-checkbox');
      checkbox.checked = true;
      const percentageInput = row.querySelector('.seller-percentage');
      const savedSeller = savedSellers.find(seller => seller.id === id);
      percentageInput.value = savedSeller.percentage;
      this.updateAmount(id, savedSeller.percentage);
    });

    this.updateCommission();
  }

  toggleSeller(event) {
    console.log("toggleSeller called");
    this.manualUpdate = false;

    const checkbox = event.target;
    console.log("Checkbox:", checkbox);

    const row = checkbox.closest('tr');
    console.log("Row:", row);

    if (!row) {
      console.error("Could not find parent row for checkbox");
      return;
    }

    const sellerId = row.dataset.sellerId;
    console.log("Seller ID:", sellerId);

    if (checkbox.checked) {
      this.selectedSellers.push(sellerId);
      this.initializeInputs(row);
    } else {
      this.selectedSellers = this.selectedSellers.filter(id => id !== sellerId);
      this.clearInputs(row);
    }

    this.updateCommission();
    this.updateRemainingAmount();
  }

  initializeInputs(row) {
    const percentageInput = row.querySelector('.seller-percentage');
    const amountInput = row.querySelector('.seller-amount');
    
    if (percentageInput && amountInput) {
      percentageInput.value = '0.00';
      amountInput.value = '0.00';
    }
  }

  clearInputs(row) {
    const percentageInput = row.querySelector('.seller-percentage');
    const amountInput = row.querySelector('.seller-amount');
    
    if (percentageInput && amountInput) {
      percentageInput.value = '0.00';
      amountInput.value = '0.00';
    }
  }

  updateCommission() {
    if (this.manualUpdate) return;

    const selectedCount = this.selectedSellers.length;
    const defaultPercentage = selectedCount > 0 ? (100 / selectedCount).toFixed(2) : 0;

    this.selectedSellers.forEach(id => {
      this.updateAmount(id, defaultPercentage);
    });

    this.modalContainerTarget.querySelectorAll('tr').forEach(row => {
      const sellerId = row.dataset.sellerId;
      if (!this.selectedSellers.includes(sellerId)) {
        const percentageInput = row.querySelector('.seller-percentage');
        const amountInput = row.querySelector('.seller-amount');
        if (percentageInput) percentageInput.value = '0';
        if (amountInput) amountInput.value = '0';
      }
    });
    this.updateRemainingAmount();
  }

saveSellers() {
  console.log('Saving sellers...');

  // Check if all sellers are deselected
  if (this.selectedSellers.length === 0) {
    console.log('No sellers selected. Resetting button.');
    this.resetSellersButton();
    this.close();
    return;
  }

  const sellers = this.selectedSellers.map(id => {
    const row = this.modalContainerTarget.querySelector(`tr[data-seller-id="${id}"]`);
    const percentage = parseFloat(row.querySelector('.seller-percentage').value) || 0;
    const amount = parseFloat(row.querySelector('.seller-amount').value) || 0;

    return { id, user_id: id, percentage, amount };
  });

  const totalPercentage = sellers.reduce((sum, seller) => sum + seller.percentage, 0);
  console.log('Total Percentage:', totalPercentage);
  if (totalPercentage < 99.99 || totalPercentage > 100.01) {
    alert('El total de los porcentajes debe ser 100%.');
    return;
  }

    // Store the sellers data in a data attribute or local storage
    const sellersButton = document.querySelector('[data-action="click->pos--sellers-modal#open"]');
    console.log('Sellers Button:', sellersButton);
    sellersButton.dataset.sellers = JSON.stringify(sellers);
    sellersButton.innerHTML = `
    ${sellersButton.querySelector('svg').outerHTML} ${sellers.length} Vendedor${sellers.length > 1 ? 'es' : ''} Seleccionado${sellers.length > 1 ? 's' : ''}
  `;
    sellersButton.classList.add('bg-primary-500', 'text-white');
    sellersButton.classList.remove('bg-white');
    console.log('Classes after update:', sellersButton.className);

    this.close();
  }

  updateAmount(sellerId, percentage) {
    const row = this.modalContainerTarget.querySelector(`tr[data-seller-id="${sellerId}"]`);
    if (row) {
      const percentageInput = row.querySelector('.seller-percentage');
      const amountInput = row.querySelector('.seller-amount');
      if (percentageInput && amountInput) {
        const totalAmount = this.getTotalAmount();
        const percentageValue = parseFloat(percentage) || 0;
        const amount = (totalAmount * percentageValue / 100).toFixed(2);
        if (!this.manualUpdate) {
          percentageInput.value = percentageValue.toFixed(2);
        }
        amountInput.value = amount;
        console.log(`Updating amount for seller ${sellerId}: ${amount} (${percentageValue}% of ${totalAmount})`);
      }
    }
  }

  updatePercentage(sellerId, amount) {
    const row = this.modalContainerTarget.querySelector(`tr[data-seller-id="${sellerId}"]`);
    if (row) {
      const percentageInput = row.querySelector('.seller-percentage');
      const amountInput = row.querySelector('.seller-amount');
      if (percentageInput && amountInput) {
        const totalAmount = this.getTotalAmount();
        const amountValue = parseFloat(amount) || 0;
        const percentage = totalAmount > 0 ? ((amountValue / totalAmount) * 100).toFixed(2) : 0;
        percentageInput.value = percentage;
        if (!this.manualUpdate) {
          amountInput.value = amountValue.toFixed(2);
        }
        console.log(`Updating percentage for seller ${sellerId}: ${percentage}% (${amountValue} of ${totalAmount})`);
      }
    }
  }

  resetSellersButton() {
    const sellersButton = document.querySelector('[data-action="click->pos--sellers-modal#open"]');
    sellersButton.dataset.sellers = '[]';
    sellersButton.innerHTML = `
    ${sellersButton.querySelector('svg').outerHTML} Vendedores
  `;
    sellersButton.classList.remove('bg-primary-500', 'text-white');
    sellersButton.classList.add('bg-white');
    console.log('Classes after reset:', sellersButton.className);
  }

  getTotalAmount() {
    const totalElement = document.querySelector('[data-pos--order-items-target="total"]');
    if (totalElement) {
      return parseFloat(totalElement.textContent.replace('S/ ', '')) || 0;
    }
    return 0;
  }

  handleManualUpdate(event) {
    const input = event.target;
    const sellerId = input.closest('tr').dataset.sellerId;

    if (!this.selectedSellers.includes(sellerId)) {
      this.selectedSellers.push(sellerId);
      const checkbox = input.closest('tr').querySelector('.seller-checkbox');
      if (checkbox) checkbox.checked = true;
    }

    this.updateAmount(sellerId, input.value);
    this.updateRemainingAmount();
    this.manualUpdate = true;
  }

  handlePercentageUpdate(event) {
    const input = event.target;
    const sellerId = input.closest('tr').dataset.sellerId;
    let percentage = input.value;

    // Remove any non-numeric characters except for the decimal point
    percentage = percentage.replace(/[^\d.]/g, '');

    // Ensure only one decimal point
    const parts = percentage.split('.');
    if (parts.length > 2) {
      percentage = parts[0] + '.' + parts.slice(1).join('');
    }

    // Update the input value
    input.value = percentage;

    this.updateSellerSelection(sellerId);
    this.updateAmount(sellerId, percentage);
    this.updateRemainingAmount();
    this.manualUpdate = true;
  }

  handleAmountUpdate(event) {
    const input = event.target;
    const sellerId = input.closest('tr').dataset.sellerId;
    const cursorPosition = input.selectionStart;
    let amount = input.value;

    // Allow decimal numbers with up to 2 decimal places
    if (!/^\d*\.?\d{0,2}$/.test(amount)) {
      // If invalid, revert to previous valid value
      amount = amount.replace(/[^\d.]/g, '');
      const parts = amount.split('.');
      if (parts.length > 2) {
        amount = parts[0] + '.' + parts.slice(1).join('');
      }
      if (parts[1]?.length > 2) {
        amount = parts[0] + '.' + parts[1].slice(0, 2);
      }
    }

    // Update the input value
    input.value = amount;
    
    // Restore cursor position
    input.setSelectionRange(cursorPosition, cursorPosition);

    this.updateSellerSelection(sellerId);
    this.updatePercentage(sellerId, amount);
    this.updateRemainingAmount();
    this.manualUpdate = true;
  }

  updateSellerSelection(sellerId) {
    if (!this.selectedSellers.includes(sellerId)) {
      this.selectedSellers.push(sellerId);
      const checkbox = this.modalContainerTarget.querySelector(`tr[data-seller-id="${sellerId}"] .seller-checkbox`);
      if (checkbox) checkbox.checked = true;
    }
  }

  updateRemainingAmount() {
    const totalAmount = this.getTotalAmount();
    const assignedAmount = this.selectedSellers.reduce((sum, id) => {
      const row = this.modalContainerTarget.querySelector(`tr[data-seller-id="${id}"]`);
      return sum + (parseFloat(row.querySelector('.seller-amount').value) || 0);
    }, 0);
    const remainingAmount = totalAmount - assignedAmount;
    this.remainingAmountTarget.textContent = `S/ ${remainingAmount.toFixed(2)}`;
  }
}
