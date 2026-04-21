import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { readUrl: String }

  connect() {
    this.scrollToBottom()
    this.markRead()
    this.observer = new MutationObserver(() => {
      this.scrollToBottom()
      this.markRead()
    })
    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  async markRead() {
    if (!this.hasReadUrlValue) return

    const response = await fetch(this.readUrlValue, {
      method: "PATCH",
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })

    if (!response.ok) return

    Turbo.renderStreamMessage(await response.text())
  }
}
