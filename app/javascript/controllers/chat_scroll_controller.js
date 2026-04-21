import { Controller } from "@hotwired/stimulus"

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

  markRead() {
    if (!this.hasReadUrlValue) return

    fetch(this.readUrlValue, {
      method: "PATCH",
      credentials: "same-origin",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content,
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
      }
    })
  }
}
