import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const url = event.currentTarget.dataset.lightboxFullUrlValue
    if (!url) return

    const overlay = document.createElement("div")
    overlay.className = "fixed inset-0 bg-black/90 z-50 flex items-center justify-center cursor-zoom-out p-4"
    overlay.innerHTML = `<img src="${url}" class="max-h-full max-w-full rounded shadow-2xl" />`
    overlay.addEventListener("click", () => overlay.remove())
    document.addEventListener("keydown", function onEsc(e) {
      if (e.key === "Escape") {
        overlay.remove()
        document.removeEventListener("keydown", onEsc)
      }
    })
    document.body.appendChild(overlay)
  }
}