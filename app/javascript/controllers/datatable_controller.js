import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    languageCdn: { type: String, default: '/datatables/i18n/es-ES.json' },
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
    };

    const allAdditionalOptions = this.optionsValue;

    // Check if the table is set for server-side processing
    if (allAdditionalOptions.includes("server_side:true")) {
      initialOptions.serverSide = true;
      initialOptions.ajax = {
        url: "/admin/products.json",
        type: "GET",
      }
    }

    if (allAdditionalOptions.length > 0) {
      allAdditionalOptions.split(';').forEach(additionalOption => {
        if (additionalOption.trim() === "select_single") {
          initialOptions.select = { style: 'single', info: false };
        } else if (additionalOption.trim() === "select_multi") {
          initialOptions.select = { style: 'multi', info: false };
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
      // this.applyTailwindClasses();

      // Listen for the DataTable's draw event to reapply classes
      $(tableElement).on('draw.dt', () => {
        // console.log('draw.dt event triggered');
        this.applyTailwindClasses();

        setTimeout(() => {
          this.applyPaginationStyles();
        }, 100);
      });

      $(tableElement).on('xhr.dt', () => {
        console.log('xhr.dt event triggered');
        
        setTimeout(() => {
          // Add Tailwind classes to the cells (required for JSON response)
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
              observer.disconnect(); // Stop observing once the wrapper is found
            }
          });
        }
      });
    });

    // Observe the parent element of where the wrapper will be added
    observer.observe(document.body, { childList: true, subtree: true });
  }

  observePagination() {
    setTimeout(() => {
      const paginationContainer = document.querySelector('.dt-paging nav');

      if (paginationContainer) {
        const observer = new MutationObserver((mutations) => {
          mutations.forEach((mutation) => {
            if (mutation.type === 'childList') {
              // console.log('Pagination changed or elements added/removed');
              this.applyPaginationStyles(); // Reapply pagination styles when pagination is updated
            }
          });
        });

        // Observe both direct children and deeper nested changes
        observer.observe(paginationContainer, {
          childList: true, // Detect when children are added or removed
          subtree: true    // Include all descendant nodes
        });

        // console.log('Observer attached to pagination container');
      } else {
        console.log('Pagination container not found');
      }
    }, 200); // Delay to ensure the DOM elements are available
  }

  applyTailwindClasses() {
    // Apply pagination styles initially
    this.applyPaginationStyles();

    // common dt classes that will be converted to Tailwind classes
    $('.dt-button')
      .addClass('rounded-md px-4 py-2 bg-primary-500 text-white border-primary-500 hover:text-primary-300 transition duration-200');

    // Add Tailwind classes to the layout rows
    $('.dt-layout-row').addClass('flex flex-col mt-2 pt-2 sm:flex-row justify-between');

    const tableHeaders = document.querySelectorAll('#datatable-element th');
    tableHeaders.forEach((th) => {
      th.classList.add('px-4', 'py-2', 'text-left', 'border-b', 'border-slate-300', 'dark:border-slate-600');
    });

    // Style dt-length to ensure label, select, and text are side by side
    const dtLength = document.querySelector('.dt-length');
    if (dtLength) {
      dtLength.classList.add('flex', 'items-center', 'space-x-2'); // Use flexbox to align items horizontally

      const label = dtLength.querySelector('label');
      const select = dtLength.querySelector('select');

      if (label) {
        label.classList.add('flex', 'items-center', 'space-x-2'); // Ensure the label and its children are aligned
      }

      if (select) {
        select.classList.add('ml-2', 'mr-2', 'form-select', 'block', 'w-full', 'lg:w-24', 'mt-2', 'sm:mt-0', 'rounded-md', 'border-slate-300', 'focus:border-primary-500', 'focus:ring-primary-500', 'min-w-[70px]'); // Add margin between select and the preceding text
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

    // Style the info text (new structure)
    $('.dt-info').addClass('text-sm text-slate-400 mt-2 sm:mt-0');
  }

  applyCellTailwindClasses() {
    // Apply Tailwind classes to cells
    $('.dtr-control').addClass('px-4 py-2');
    $('td').addClass('px-4 py-2 text-gray-700 dark:text-gray-300');  // Add classes for all table cells
    $('th').addClass('px-4 py-2 text-left border-b border-slate-300 dark:border-slate-600');
  }

  applyPaginationStyles() {
    // console.log('Applying pagination styles');
    // Apply custom styles to pagination buttons
    $('.dt-paging-button')
      .addClass('px-4 py-2 rounded-md text-white-700 hover:text-primary-500 transition duration-200');
    $('.dt-paging-button.current')
      .addClass('bg-primary-500 text-white border-primary-500 hover:text-primary-200 transition duration-200');
  }
}