import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timestamp: String
  }

  connect() {
    if (!this.hasTimestampValue) return

    const date = new Date(this.timestampValue)
    if (Number.isNaN(date.getTime())) return

    this.element.textContent = new Intl.DateTimeFormat(undefined, {
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit"
    }).format(date)
  }
}
