import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]

  toggle() {
    const reveal = this.inputTarget.type === "password"

    this.inputTarget.type = reveal ? "text" : "password"
    this.buttonTarget.textContent = reveal ? "Hide" : "Show"
    this.buttonTarget.setAttribute("aria-label", reveal ? "Hide password" : "Show password")
    this.buttonTarget.setAttribute("aria-pressed", String(reveal))
    this.inputTarget.focus()
  }
}
