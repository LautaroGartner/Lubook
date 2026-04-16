import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.classList.toggle("hidden")
  }

  // Close menu when user navigates away
  disconnect() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.add("hidden")
    }
  }
}