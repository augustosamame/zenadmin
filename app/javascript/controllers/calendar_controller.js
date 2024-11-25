import { Controller } from "@hotwired/stimulus"
import { Calendar } from '@fullcalendar/core'
import dayGridPlugin from '@fullcalendar/daygrid'
import interactionPlugin from '@fullcalendar/interaction'
import listPlugin from '@fullcalendar/list'

// Connects to data-controller="calendar"
export default class extends Controller {
  static values = {
    events: { type: Array, default: [] }
  }

  connect() {
    this.initializeCalendar()
  }

  initializeCalendar() {
    const calendar = new Calendar(this.element, {
      plugins: [dayGridPlugin, interactionPlugin, listPlugin],
      locale: 'es',
      initialView: 'dayGridMonth',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title',
        right: 'dayGridMonth,dayGridWeek,listWeek'
      },
      allDayText: 'Todo el día',
      buttonText: {
        today: 'Hoy',
        month: 'Mes',
        week: 'Semana',
        list: 'Lista'
      },
      listDayFormat: { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' },
      views: {
        listWeek: {
          listDayFormat: { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' },
          allDayText: 'Todo el día',
          noEventsText: 'No hay eventos para mostrar'
        }
      },
      events: this.eventsValue || [],
      eventClick: this.handleEventClick.bind(this),
      themeSystem: 'standard',
      eventContent: (arg) => {
        return {
          html: `
            <div class="p-1">
              <div class="text-sm font-medium">${arg.event.extendedProps.customer}</div>
              <div class="text-xs">S/ ${arg.event.extendedProps.amount.toFixed(2)}</div>
              <div class="text-xs">${this.translateStatus(arg.event.extendedProps.status)}</div>
            </div>
          `
        }
      },
    })

    calendar.render()
  }

  handleEventClick(info) {
    if (info.event.url) {
      window.location.href = info.event.url
      info.jsEvent.preventDefault() // prevent default action
    }
  }

  translateStatus(status) {
    const statusTranslations = {
      pending: 'Pendiente',
      overdue: 'Vencido',
      paid: 'Pagado'
    }
    return statusTranslations[status] || status
  }
}
