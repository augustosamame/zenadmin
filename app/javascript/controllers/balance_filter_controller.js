import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ["debt", "credit", "row"];

  connect() {
    console.log("Balance filter connected");
    // Attach event listeners
    this.debtTarget.addEventListener("change", () => this.filterRows());
    this.creditTarget.addEventListener("change", () => this.filterRows());
  }

  filterRows() {
    const showDebt = this.debtTarget.checked;
    const showCredit = this.creditTarget.checked;

    // Only allow one checkbox to be checked at a time
    if (showDebt && showCredit) {
      // Uncheck the other
      // Prefer the one just checked (event order)
      // We'll use last checked
      if (event.target === this.debtTarget) {
        this.creditTarget.checked = false;
      } else {
        this.debtTarget.checked = false;
      }
    }

    // Re-evaluate after enforcing single selection
    const finalShowDebt = this.debtTarget.checked;
    const finalShowCredit = this.creditTarget.checked;

    this.rowTargets.forEach(row => {
      const balance = parseFloat(row.dataset.balance);
      if (finalShowDebt) {
        row.style.display = balance > 0 ? "" : "none";
      } else if (finalShowCredit) {
        row.style.display = balance < 0 ? "" : "none";
      } else {
        row.style.display = "";
      }
    });
  }
}
