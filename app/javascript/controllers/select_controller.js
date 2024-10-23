import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

export default class extends Controller {
  static values = {
    model: String,           // Model name for dynamic behavior
    multiSelect: Boolean,    // Toggle multi-select functionality
    placeholder: String      // Placeholder text for the select input
  };

  connect() {
    console.log("Select controller connected");
    this.initializeTomSelect();
  }

  initializeTomSelect() {
    // Set up options for Tom Select based on controller values
    const options = {
      placeholder: this.hasPlaceholderValue ? this.placeholderValue : "Selecciona una opción...",
      maxItems: this.multiSelectValue ? null : 1, // If multiSelect is true, allow multiple; otherwise, single select
      plugins: this.multiSelectValue ? ["remove_button"] : [], // Add remove button plugin for multi-select
      create: false,  // Disable tag creation by default
      valueField: "id",
      labelField: "name",
      searchField: "name",
      optgroupField: 'class',
      optgroupLabelField: 'label',
      optgroupValueField: 'value',
      lockOptgroupOrder: true,
      render: {
        optgroup_header: function (data, escape) {
          return '<div class="optgroup-header custom-optgroup-header">' + escape(data.label) + '</div>';
        }
      }
    };

    // Initialize Tom Select only if not already initialized
    if (!this.element.tomSelect) {
      this.tomSelect = new TomSelect(this.element, options);
    }
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy();
      this.tomSelect = null;
    }
  }

  refreshTomSelect() {
    if (this.tomSelect) {
      this.tomSelect.destroy();
      this.tomSelect = null;
    }
    this.initializeTomSelect();
  }
}