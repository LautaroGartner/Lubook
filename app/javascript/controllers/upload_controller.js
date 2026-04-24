import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["input", "filename", "previews", "hiddenInputs"]
  static values = {
    max: { type: Number, default: 10 },
    directUploadUrl: String
  }

  connect() {
    this.files = []
  }

  picked(event) {
    const newFiles = Array.from(event.target.files)
    event.target.value = ""  // reset so the same file can be re-picked after removal

    for (const file of newFiles) {
      if (this.files.length >= this.maxValue) {
        alert(`Max ${this.maxValue} images per post`)
        break
      }
      this.addFile(file)
    }

    this.updateLabel()
  }

  addFile(file) {
    const entry = { file, signedId: null, status: "uploading" }
    entry.previewEl = this.renderPreview(entry)
    this.files.push(entry)
    this.uploadFile(entry)
  }

  uploadFile(entry) {
    const upload = new DirectUpload(entry.file, this.directUploadUrlValue, {
      directUploadWillStoreFileWithXHR: (xhr) => {
        xhr.upload.addEventListener("progress", (e) => {
          if (e.lengthComputable) {
            const pct = Math.round((e.loaded / e.total) * 100)
            const bar = entry.previewEl.querySelector("[data-progress]")
            if (bar) bar.style.width = `${pct}%`
          }
        })
      }
    })

    upload.create((error, blob) => {
      if (error) {
        entry.status = "error"
        entry.previewEl.querySelector("[data-overlay]").textContent = "Failed"
        return
      }
      entry.signedId = blob.signed_id
      entry.status = "ready"
      this.appendHiddenInput(entry)
      const overlay = entry.previewEl.querySelector("[data-overlay]")
      if (overlay) overlay.remove()
    })
  }

  appendHiddenInput(entry) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = "post[images][]"
    input.value = entry.signedId
    input.dataset.signedId = entry.signedId
    this.hiddenInputsTarget.appendChild(input)
    entry.hiddenInput = input
  }

  remove(event) {
    event.preventDefault()
    const signedId = event.currentTarget.dataset.signedId
    const idx = this.files.findIndex(f =>
      f.previewEl === event.currentTarget.closest("[data-preview]")
    )
    if (idx === -1) return

    const entry = this.files[idx]
    entry.previewEl.remove()
    if (entry.hiddenInput) entry.hiddenInput.remove()
    this.files.splice(idx, 1)
    this.updateLabel()
  }

  renderPreview(entry) {
    const wrapper = document.createElement("div")
    wrapper.dataset.preview = ""
    wrapper.className = "relative aspect-square rounded-lg overflow-hidden bg-stone-100 group"

    const img = document.createElement("img")
    img.className = "w-full h-full object-cover"
    img.src = URL.createObjectURL(entry.file)
    wrapper.appendChild(img)

    const overlay = document.createElement("div")
    overlay.dataset.overlay = ""
    overlay.className = "absolute inset-0 bg-black/40 flex items-end"
    overlay.innerHTML = `<div class="w-full h-1 bg-stone-700"><div data-progress class="h-full bg-white" style="width:0%"></div></div>`
    wrapper.appendChild(overlay)

    const removeBtn = document.createElement("button")
    removeBtn.type = "button"
    removeBtn.dataset.action = "click->upload#remove"
    removeBtn.className = "absolute top-1 right-1 w-6 h-6 rounded-full bg-black/60 text-white text-xs flex items-center justify-center opacity-0 group-hover:opacity-100 transition"
    removeBtn.textContent = "×"
    wrapper.appendChild(removeBtn)

    this.previewsTarget.appendChild(wrapper)
    return wrapper
  }

  updateLabel() {
    if (!this.hasFilenameTarget) return
    const count = this.files.length
    this.filenameTarget.textContent = count === 0
      ? "No images selected"
      : `${count} image${count === 1 ? "" : "s"} selected`
    this.filenameTarget.classList.toggle("text-stone-500", count === 0)
    this.filenameTarget.classList.toggle("text-rose-600", count > 0)
  }
}