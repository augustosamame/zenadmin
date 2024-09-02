import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["links", "commissionRangeTemplate", "selectedLocation"];

  connect() {
    this.wrapperClass = this.data.get("wrapperClass") || "nested-fields";
  }

  addAssociation(event) {
    event.preventDefault();

    const content = this.commissionRangeTemplateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      new Date().getTime()
    );
    this.linksTarget.insertAdjacentHTML("beforebegin", content);
  }

  removeAssociation(event) {
    console.log("removeAssociation");
    event.preventDefault();
    console.log("removeAssociation event: ", event);

    const wrapper = event.target.closest("." + this.wrapperClass);

    // New records are simply removed from the page
    if (wrapper.dataset.newRecord == "true") {
      wrapper.remove();
    } else {
      // Existing records are hidden and flagged for deletion
      wrapper.querySelector("input[name*='_destroy']").value = 1;
      wrapper.style.display = "none";
    }
  }

  locationChanged(event) {
    const locationId = event.target.value;
    const form = this.element.closest("form");

    if (locationId) {
      // Update the form action to point to the selected location
      form.action = `/admin/locations/${locationId}`;
      this.selectedLocationTarget.value = locationId;

      // Fetch new commission ranges for the selected location
      fetch(`/admin/locations/${locationId}/commission_ranges`, {
        headers: { "Accept": "application/json" }
      })
        .then(response => response.json())
        .then(data => {
          console.log("data: ", data);
          this.updateCommissionRanges(data);
        });
    }
  }

  updateCommissionRanges(data) {
    const commissionRangesContainer = document.getElementById('commission-ranges');
    commissionRangesContainer.innerHTML = '';

    // Sort data by min_sales in ascending order
    data.sort((a, b) => a.min_sales - b.min_sales);

    data.forEach((range, index) => {
      const template = document.querySelector('[data-commission-range-form-target="commissionRangeTemplate"]');
      if (template) {
        const commissionFormTemplate = template.innerHTML.replace(/NEW_RECORD/g, `new_${index}`);

        const newNode = document.createElement('div');
        newNode.innerHTML = commissionFormTemplate;

        const newRangeFields = newNode.querySelector('.nested-fields');

        newRangeFields.querySelector("input[name*='[min_sales]']").value = range.min_sales;
        newRangeFields.querySelector("input[name*='[max_sales]']").value = range.max_sales;
        newRangeFields.querySelector("input[name*='[commission_percentage]']").value = range.commission_percentage;

        commissionRangesContainer.appendChild(newRangeFields);
      } else {
        console.error("Template not found!");
      }
    });
  }
}