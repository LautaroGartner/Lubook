import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "filename"]

  preview(event) {
    const file = event.target.files[0]
    if (!file) return

    const name = file.name.length > 30
      ? file.name.slice(0, 27) + "..."
      : file.name

    if (this.hasFilenameTarget) {
      this.filenameTarget.textContent = name
      this.filenameTarget.classList.remove("text-stone-500")
      this.filenameTarget.classList.add("text-rose-600")
    }
  }
}