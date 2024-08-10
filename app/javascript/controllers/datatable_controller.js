import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    languageCdn: { type: String, default: '//cdn.datatables.net/plug-ins/1.13.4/i18n/es-ES.json' },
    options: { type: String, default: '' }
  }

  connect() {
    if (typeof $.fn.dataTable.moment === 'function') {
      $.fn.dataTable.moment('DD/MM/YYYY | HH:mm');
    } else {
      console.error('Error: datetime-moment plugin is not loaded.');
    }

    const tableElement = this.element.querySelector('table');
    const dateColumnIndex = this.element.dataset.datatableDateColumn;

    const initialOptions = {
      stateSave: true,
      columnDefs: [
        { className: 'dt-body-nowrap', targets: -1 },
      ],
      language: {
        url: this.languageCdnValue,
      },
    };

    const allAdditionalOptions = this.optionsValue;
    if (allAdditionalOptions.length > 0) {
      allAdditionalOptions.split(';').forEach(additionalOption => {
        if (additionalOption.trim() === "select_single") {
          initialOptions.select = { style: 'single' };
        } else if (additionalOption.trim() === "select_multi") {
          initialOptions.select = { style: 'multi' };
        } else if (additionalOption.startsWith("sort_")) {
          const parts = additionalOption.split("_");
          const sortCol = parseInt(parts[1], 10);
          const sortDir = parts[2];
          initialOptions.order = [[sortCol, sortDir]];
          initialOptions.stateSave = false;
        } else {
          let [key, value] = additionalOption.split(':');
          key = key.trim();
          value = value.trim();
          if (value === "true") {
            value = true;
          } else if (value === "false") {
            value = false;
          }
          initialOptions[key] = value;
        }
      });
    }

    if (tableElement && !tableElement.classList.contains('dataTable-initialized')) {
      const dataTable = $(tableElement).DataTable(initialOptions);
      tableElement.classList.add('dataTable-initialized');

      // Apply Tailwind classes initially
      this.applyTailwindClasses();

      // Listen for the DataTable's draw event to reapply classes
      $(tableElement).on('draw.dt', () => {
        this.applyTailwindClasses();
      });

      // Observe for the wrapper to be added to the DOM
      this.observeWrapperAddition();
    }
  }

  observeWrapperAddition() {
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.addedNodes.length > 0) {
          mutation.addedNodes.forEach(node => {
            if (node.id === 'datatable-element_wrapper') {
              try {
                this.applyTailwindClasses();
              } catch (error) {
                console.error('Error during setTimeout or applying classes:', error);
              }
              observer.disconnect(); // Stop observing once the wrapper is found
            }
          });
        }
      });
    });

    // Observe the parent element of where the wrapper will be added
    observer.observe(document.body, { childList: true, subtree: true });
  }

  applyTailwindClasses() {

    const searchInput = $('.dt-search input');
    if (searchInput.length > 0) {
      searchInput
        .addClass('form-input block w-full lg:w-64 mt-2 sm:mt-0 rounded-md border-slate-300 focus:border-primary-500 focus:ring-primary-500')
        .attr('placeholder', 'Buscar...');
    }

    // Style the length menu (new structure)
    $('.dt-length select')
      .addClass('form-select block w-full lg:w-24 mt-2 sm:mt-0 rounded-md border-slate-300 focus:border-primary-500 focus:ring-primary-500');

    // Style the pagination (new structure)
    $('.pagination').addClass('mt-4 sm:mt-0 flex items-center justify-between');
    $('.pagination .dt-paging-button')
      .addClass('px-4 py-2 border rounded-md bg-white text-slate-700 hover:bg-slate-50 transition duration-200');
    $('.pagination .dt-paging-button.current')
      .addClass('bg-primary-500 text-white border-primary-500');

    // Style the info text (new structure)
    $('.dt-info').addClass('text-sm text-slate-600 mt-2 sm:mt-0');

    // Style the table header
    $('.dataTables_wrapper th')
      .addClass('px-4 py-2 text-left text-sm font-medium text-slate-500 bg-slate-100');
  }
}