import { Controller } from "@hotwired/stimulus"
import { visit } from "@hotwired/turbo"

export default class extends Controller {
  static values = { interval: Number }

  connect() {
    this.startRefreshing()
  }

  disconnect() {
    this.stopRefreshing()
  }

  startRefreshing() {
    this.refreshInterval = setInterval(() => {
      this.refresh()
    }, this.intervalValue)
  }

  stopRefreshing() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  dispatchRefreshEvent() {
    console.log("Dispatching dashboardRefreshed event")
    document.dispatchEvent(new CustomEvent('dashboardRefreshed'))
  }

  refresh() {
    console.log("auto refreshing every " + this.intervalValue + "ms")

    const visitResult = visit(window.location.href, { action: "replace" })

    if (visitResult && typeof visitResult.then === 'function') {
      visitResult.then(() => {
        this.dispatchRefreshEvent()
      })
    } else {
      // If visit doesn't return a Promise, wait a short time before dispatching the event
      setTimeout(() => {
        this.dispatchRefreshEvent()
      }, 200)
    }
  }
}