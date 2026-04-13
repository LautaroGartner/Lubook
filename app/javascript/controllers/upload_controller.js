import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  preview(event) {
    const file = event.target.files[0]
    if (!file) return

    const label = event.target.closest("label").querySelector("[data-upload-label]")
    if (label) {
      label.textContent = file.name.length > 30
        ? file.name.slice(0, 27) + "..."
        : file.name
    }
  }
}