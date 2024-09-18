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

  refresh() {
    console.log("auto refreshing every " + this.intervalValue + "ms")
    visit(window.location.href, { action: "replace" })
  }
}