import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    languageCdn: { type: String, default: '/datatables/i18n/es-ES.json' },
    options: { type: String, default: '' }
  }

  connect() {
    console.log('datatable controller connected');
    if (typeof $.fn.dataTable.moment === 'function') {
      $.fn.dataTable.moment('DD/MM/YYYY | HH:mm');
    } else {
      console.error('Error: datetime-moment plugin is not loaded.');
    }

    const tableElement = this.element.querySelector('table');
    const dateColumnIndex = this.element.dataset.datatableDateColumn;
    const languageUrl = this.languageCdnValue || '/datatables/i18n/es-ES.json';


    const initialOptions = {
      stateSave: true,
      ordering: true,
      fixedHeader: true,
      responsive: true,
      processing: true, // Show processing indicator only when server-side processing
      columnDefs: [
        // { className: 'dt-body-nowrap', targets: -1 },
      ],
      language: {
        url: languageUrl
      },
      pagingType: 'simple_numbers',
      pageLength: 10,             // Show 10 rows per page by default
      lengthMenu: [10, 25, 100],
      layout: {
        top2Start: {
          buttons: []
        },
        top2End: {
          buttons: [
            'csv', 'print'
          ]
        }
      },
      order: []
    };

    const allAdditionalOptions = this.optionsValue;

    console.log('allAdditionalOptions', allAdditionalOptions);

    const resourceNameMatch = allAdditionalOptions.match(/resource_name:'([^']+)'/);
    if (!resourceNameMatch) {
      console.error('Error: resource_name option is missing.');
      return;
    }

    const resourceName = resourceNameMatch ? resourceNameMatch[1] : null;
    const snakeCaseName = resourceName.replace(/([a-z0-9])([A-Z])/g, '$1_$2').toLowerCase();
    const resourceNamePlural = snakeCaseName.endsWith('s') ? snakeCaseName : snakeCaseName + 's';

    // Add custom "Crear" button if resourceName is provided and create_button is not false
    if (resourceName && !allAdditionalOptions.includes("create_button:false")) {
      const capitalizedResourceName = resourceName.charAt(0).toUpperCase() + resourceName.slice(1);
      const createButton = {
        text: `Crear ${capitalizedResourceName}`,
        action: () => {
          window.location.href = `/admin/${resourceNamePlural}/new`;
        },
        className: 'dt-button bg-green-500 text-white hover:bg-green-400'
      };
      initialOptions.layout.top2Start.buttons.push(createButton);
    }

    // Check if the table is set for server-side processing
    if (allAdditionalOptions.includes("server_side:true")) {
      initialOptions.serverSide = true;
      initialOptions.ajax = {
        url: `/admin/${resourceNamePlural}.json`,
        type: "GET",
      }
    }

    if (allAdditionalOptions.length > 0) {
      allAdditionalOptions.split(';').forEach(additionalOption => {
        if (additionalOption && additionalOption.trim()) { // Check if additionalOption is not empty or undefined
          additionalOption = additionalOption.trim();

          if (additionalOption === "no_buttons") {
            initialOptions.layout.top2End.buttons = [];
          } else if (additionalOption === "select_single") {
            initialOptions.select = { style: 'single', info: false };
          } else if (additionalOption === "select_multi") {
            initialOptions.select = { style: 'multi', info: false };
          } else if (additionalOption.startsWith("sort_")) {
            const parts = additionalOption.split("_");
            const sortCol = parseInt(parts[1], 10);
            const sortDir = parts[2];
            initialOptions.order = [[sortCol, sortDir]];
            initialOptions.stateSave = false;
          } else {
            let [key, value] = additionalOption.split(':');
            if (key && value) {
              key = key.trim();
              value = value.trim();
              if (value === "true") {
                value = true;
              } else if (value === "false") {
                value = false;
              }
              initialOptions[key] = value;
            }
          }
        }
      });
    }

    if (tableElement && !tableElement.classList.contains('dataTable-initialized')) {
      const dataTable = $(tableElement).DataTable(initialOptions);
      tableElement.classList.add('dataTable-initialized');

      // Apply Tailwind classes initially
      // this.applyTailwindClasses();

      // Listen for the DataTable's draw event to reapply classes
      $(tableElement).on('draw.dt', () => {
        this.applyTailwindClasses();

        setTimeout(() => {
          this.applyPaginationStyles();
        }, 100);
      });

      $(tableElement).on('xhr.dt', () => {
        console.log('xhr.dt event triggered');
        
        setTimeout(() => {
          this.applyCellTailwindClasses();
        }, 50)
      });

      // Observe for the wrapper to be added to the DOM
      this.observeWrapperAddition();

      // Observe pagination container for changes
      this.observePagination();
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
              observer.disconnect();
            }
          });
        }
      });
    });

    observer.observe(document.body, { childList: true, subtree: true });
  }

  observePagination() {
    setTimeout(() => {
      const paginationContainer = document.querySelector('.dt-paging nav');

      if (paginationContainer) {
        const observer = new MutationObserver((mutations) => {
          mutations.forEach((mutation) => {
            if (mutation.type === 'childList') {
              this.applyPaginationStyles();
            }
          });
        });

        observer.observe(paginationContainer, {
          childList: true,
          subtree: true
        });
      } else {
        console.log('Pagination container not found');
      }
    }, 200);
  }

  applyTailwindClasses() {
    this.applyPaginationStyles();

    $('.dt-button')
      .addClass('rounded-md px-4 py-2 bg-primary-500 text-white border-primary-500 hover:text-primary-300 transition duration-200');

    $('.dt-layout-row').addClass('flex flex-col mt-2 pt-2 sm:flex-row justify-between');

    const tableHeaders = document.querySelectorAll('#datatable-element th');
    tableHeaders.forEach((th) => {
      th.classList.add('px-4', 'py-2', 'text-left', 'border-b', 'border-slate-300', 'dark:border-slate-600');
    });

    const dtLength = document.querySelector('.dt-length');
    if (dtLength) {
      dtLength.classList.add('flex', 'items-center', 'space-x-2');

      const label = dtLength.querySelector('label');
      const select = dtLength.querySelector('select');

      if (label) {
        label.classList.add('flex', 'items-center', 'space-x-2');
      }

      if (select) {
        select.classList.add('ml-2', 'mr-2', 'form-select', 'block', 'w-full', 'lg:w-24', 'mt-2', 'sm:mt-0', 'rounded-md', 'border-slate-300', 'focus:border-primary-500', 'focus:ring-primary-500', 'min-w-[70px]');
      }
    }

    $('.dt-search')
      .addClass('flex direction-row items-center');

    $('.dt-search label')
      .addClass('pr-2');

    const searchInput = $('.dt-search input');
    if (searchInput.length > 0) {
      searchInput
        .addClass('form-input block w-full lg:w-64 mt-2 sm:mt-0 rounded-md border-slate-300 focus:border-primary-500 focus:ring-primary-500 max-w-[200px]')
        .attr('placeholder', 'Texto a Buscar...');
    }

    $('.dt-info').addClass('text-sm text-slate-400 mt-2 sm:mt-0');
  }

  applyCellTailwindClasses() {
    $('.dtr-control').addClass('px-4 py-2');
    $('td').addClass('px-4 py-2 text-gray-700 dark:text-gray-300');
    $('th').addClass('px-4 py-2 text-left border-b border-slate-300 dark:border-slate-600');
  }

  applyPaginationStyles() {
    $('.dt-paging-button')
      .addClass('px-4 py-2 rounded-md text-white-700 hover:text-primary-500 transition duration-200');
    $('.dt-paging-button.current')
      .addClass('bg-primary-500 text-white border-primary-500 hover:text-primary-200 transition duration-200');
  }
}