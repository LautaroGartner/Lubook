import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 5000 }
  }

  connect() {
    if (!this.hasUrlValue) return

    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  async refresh() {
    const response = await fetch(this.urlValue, {
      credentials: "same-origin",
      headers: { Accept: "text/vnd.turbo-stream.html" }
    })

    if (!response.ok) return

    Turbo.renderStreamMessage(await response.text())
  }
}
