import { Controller } from "@hotwired/stimulus";
import { resourceMappings } from "./datatable_resource_mappings";

export default class extends Controller {
  static values = {
    languageCdn: { type: String, default: '/datatables/i18n/es-ES.json' },
    options: { type: String, default: '' }
  }

  static resourceMappings = resourceMappings;

  connect() {
    this.initializeMoment();
    this.initializeDataTable();
  }

  initializeMoment() {
    if (typeof $.fn.dataTable.moment === 'function') {
      $.fn.dataTable.moment('DD/MM/YYYY | HH:mm');
    } else {
      console.error('Error: datetime-moment plugin is not loaded.');
    }
  }

  initializeDataTable() {
    const tableElement = this.element.querySelector('table');
    if (!tableElement || tableElement.classList.contains('dataTable-initialized')) return;

    const options = this.buildDataTableOptions();
    const dataTable = $(tableElement).DataTable(options);
    tableElement.classList.add('dataTable-initialized');

    this.setupEventListeners(tableElement);
    this.observeWrapperAddition();
    this.observePagination();
  }

  buildDataTableOptions() {
    const initialOptions = this.getInitialOptions();
    const additionalOptions = this.parseAdditionalOptions();
    return { ...initialOptions, ...additionalOptions };
  }

  getInitialOptions() {
    const languageUrl = this.languageCdnValue;
    return {
      stateSave: true,
      ordering: true,
      fixedHeader: true,
      responsive: true,
      processing: true,
      columnDefs: [],
      language: { url: languageUrl },
      pagingType: 'simple_numbers',
      pageLength: 10,
      lengthMenu: [10, 25, 100],
      layout: {
        top2Start: { buttons: [] },
        top2End: { buttons: ['csv', 'print'] }
      },
      order: []
    };
  }

  parseAdditionalOptions() {
    const allAdditionalOptions = this.optionsValue;
    const options = this.getInitialOptions();

    if (!allAdditionalOptions) return options;

    const resourceNameMatch = allAdditionalOptions.match(/resource_name:'([^']+)'/);
    if (!resourceNameMatch) {
      console.error('Error: resource_name option is missing.');
      return options;
    }

    const resourceName = resourceNameMatch[1];
    const resourceMapping = this.constructor.resourceMappings[resourceName];

    if (!resourceMapping) {
      console.error(`Error: No mapping found for resource ${resourceName}`);
      return options;
    }

    if (!allAdditionalOptions.includes("create_button:false")) {
      const createButton = this.createResourceButton(resourceMapping);
      options.layout.top2Start.buttons.unshift(createButton);
    }

    options.paging = !allAdditionalOptions.includes("paging:false");

    if (allAdditionalOptions.includes("server_side:true")) {
      options.serverSide = true;
      options.ajax = {
        url: resourceMapping.ajaxUrl,
        type: "GET",
      };
    }

    allAdditionalOptions.split(';').forEach(option => {
      if (option && option.trim()) {
        this.parseOption(option.trim(), options);
      }
    });
    console.log("Options:", options);
    return options;
  }

  createResourceButton(resourceMapping) {
    console.log("Creating resource button for resource:", resourceMapping);
    return {
      text: resourceMapping.buttonText,
      action: () => {
        window.location.href = resourceMapping.buttonUrl;
      },
      className: 'dt-button bg-green-500 text-white hover:bg-green-400'
    };
  }

  parseOption(option, options) {
    if (option === "no_buttons") {
      options.buttons = [];
    } else if (option === "select_single") {
      options.select = { style: 'single', info: false };
    } else if (option === "select_multi") {
      options.select = { style: 'multi', info: false };
    } else if (option.startsWith("sort_")) {
      this.parseSortOption(option, options);
    } else {
      let [key, value] = option.split(':');
      if (key && value) {
        options[key.trim()] = this.parseValue(value.trim());
      }
    }
  }

  parseSortOption(option, options) {
    const [, col, dir] = option.split("_");
    if (!options.order) options.order = [];
    options.order.push([parseInt(col, 10), dir]);
    options.stateSave = false;
  }

  parseValue(value) {
    if (value === "true") return true;
    if (value === "false") return false;
    return value;
  }

  setupEventListeners(tableElement) {
    $(tableElement).on('draw.dt', () => {
      this.applyTailwindClasses();
      setTimeout(() => this.applyPaginationStyles(), 100);
    });

    $(tableElement).on('xhr.dt', () => {
      setTimeout(() => this.applyCellTailwindClasses(), 50);
    });
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
        const observer = new MutationObserver(() => {
          this.applyPaginationStyles();
        });
        observer.observe(paginationContainer, { childList: true, subtree: true });
      } else {
        console.log('Pagination container not found');
      }
    }, 200);
  }

  applyTailwindClasses() {
    this.applyPaginationStyles();

    $('.dt-button').addClass('rounded-md px-4 py-2 bg-primary-500 text-white border-primary-500 hover:text-primary-300 transition duration-200');
    $('.dt-layout-row').addClass('flex flex-col mt-2 pt-2 sm:flex-row justify-between');

    document.querySelectorAll('#datatable-element th').forEach((th) => {
      th.classList.add('px-4', 'py-2', 'text-left', 'border-b', 'border-slate-300', 'dark:border-slate-600');
    });

    this.applyLengthMenuStyles();
    this.applySearchInputStyles();

    $('.dt-info').addClass('text-sm text-slate-400 mt-2 sm:mt-0');
  }

  applyLengthMenuStyles() {
    const dtLength = document.querySelector('.dt-length');
    if (dtLength) {
      dtLength.classList.add('flex', 'items-center', 'space-x-2');
      const label = dtLength.querySelector('label');
      const select = dtLength.querySelector('select');
      if (label) label.classList.add('flex', 'items-center', 'space-x-2');
      if (select) select.classList.add('ml-2', 'mr-2', 'form-select', 'block', 'w-full', 'lg:w-24', 'mt-2', 'sm:mt-0', 'rounded-md', 'border-slate-300', 'focus:border-primary-500', 'focus:ring-primary-500', 'min-w-[70px]');
    }
  }

  applySearchInputStyles() {
    $('.dt-search').addClass('flex direction-row items-center');
    $('.dt-search label').addClass('pr-2');
    const searchInput = $('.dt-search input');
    if (searchInput.length > 0) {
      searchInput.addClass('form-input block w-full lg:w-64 mt-2 sm:mt-0 rounded-md border-slate-300 focus:border-primary-500 focus:ring-primary-500 max-w-[200px]')
        .attr('placeholder', 'Texto a Buscar...');
    }
  }

  applyCellTailwindClasses() {
    $('.dtr-control').addClass('px-4 py-2');
    $('td').addClass('px-4 py-2 text-gray-700 dark:text-gray-300');
    $('th').addClass('px-4 py-2 text-left border-b border-slate-300 dark:border-slate-600');
  }

  applyPaginationStyles() {
    $('.dt-paging-button').addClass('px-4 py-2 rounded-md text-white-700 hover:text-primary-500 transition duration-200');
    $('.dt-paging-button.current').addClass('bg-primary-500 text-white border-primary-500 hover:text-primary-200 transition duration-200');
  }
}