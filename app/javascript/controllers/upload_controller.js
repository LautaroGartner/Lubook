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
    this.draggedEntry = null
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
    this.files.push(entry)
    entry.previewEl = this.renderPreview(entry)
    this.updatePreviewOrder()
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
    entry.hiddenInput = input
    this.syncHiddenInputs()
  }

  remove(event) {
    event.preventDefault()
    const idx = this.files.findIndex(f =>
      f.previewEl === event.currentTarget.closest("[data-preview]")
    )
    if (idx === -1) return

    const entry = this.files[idx]
    entry.previewEl.remove()
    if (entry.hiddenInput) entry.hiddenInput.remove()
    this.files.splice(idx, 1)
    this.updatePreviewOrder()
    this.updateLabel()
  }

  moveLeft(event) {
    event.preventDefault()
    this.move(event.currentTarget.closest("[data-preview]"), -1)
  }

  moveRight(event) {
    event.preventDefault()
    this.move(event.currentTarget.closest("[data-preview]"), 1)
  }

  dragStart(event) {
    const entry = this.entryForPreview(event.currentTarget)
    if (!entry) return
    this.draggedEntry = entry
    event.currentTarget.classList.add("opacity-30")
    event.dataTransfer.effectAllowed = "move"
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
  }

  drop(event) {
    event.preventDefault()
    if (!this.draggedEntry) return

    const targetEntry = this.entryForPreview(event.currentTarget)
    if (!targetEntry || targetEntry === this.draggedEntry) return

    const from = this.files.indexOf(this.draggedEntry)
    const to = this.files.indexOf(targetEntry)
    this.files.splice(from, 1)
    this.files.splice(to, 0, this.draggedEntry)
    this.syncPreviewOrder()
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-30")
    this.draggedEntry = null
  }

  move(previewEl, delta) {
    const idx = this.files.findIndex(f => f.previewEl === previewEl)
    const nextIdx = idx + delta
    if (idx === -1 || nextIdx < 0 || nextIdx >= this.files.length) return

    const [entry] = this.files.splice(idx, 1)
    this.files.splice(nextIdx, 0, entry)
    this.syncPreviewOrder()
  }

  entryForPreview(previewEl) {
    return this.files.find(f => f.previewEl === previewEl)
  }

  syncPreviewOrder() {
    this.files.forEach(entry => this.previewsTarget.appendChild(entry.previewEl))
    this.updatePreviewOrder()
    this.syncHiddenInputs()
  }

  syncHiddenInputs() {
    this.files.forEach(entry => {
      if (entry.hiddenInput) this.hiddenInputsTarget.appendChild(entry.hiddenInput)
    })
  }

  updatePreviewOrder() {
    this.files.forEach((entry, index) => {
      const position = entry.previewEl.querySelector("[data-position]")
      if (position) position.textContent = index + 1

      const leftBtn = entry.previewEl.querySelector("[data-move-left]")
      const rightBtn = entry.previewEl.querySelector("[data-move-right]")
      if (leftBtn) leftBtn.disabled = index === 0
      if (rightBtn) rightBtn.disabled = index === this.files.length - 1
    })
  }

  renderPreview(entry) {
    const wrapper = document.createElement("div")
    wrapper.dataset.preview = ""
    wrapper.className = "relative aspect-square rounded-lg overflow-hidden bg-stone-100 group"
    wrapper.draggable = true
    wrapper.dataset.action = [
      "dragstart->upload#dragStart",
      "dragover->upload#dragOver",
      "drop->upload#drop",
      "dragend->upload#dragEnd"
    ].join(" ")

    const img = document.createElement("img")
    img.className = "w-full h-full object-cover"
    img.src = URL.createObjectURL(entry.file)
    wrapper.appendChild(img)

    const overlay = document.createElement("div")
    overlay.dataset.overlay = ""
    overlay.className = "absolute inset-0 bg-black/40 flex items-end"
    overlay.innerHTML = `<div class="w-full h-1 bg-stone-700"><div data-progress class="h-full bg-white" style="width:0%"></div></div>`
    wrapper.appendChild(overlay)

    const position = document.createElement("div")
    position.dataset.position = ""
    position.className = "absolute top-1 left-1 min-w-5 h-5 rounded-full bg-black/70 px-1.5 text-[11px] font-semibold text-white flex items-center justify-center"
    wrapper.appendChild(position)

    const orderControls = document.createElement("div")
    orderControls.className = "absolute bottom-1 left-1 right-1 flex items-center justify-between gap-1"
    orderControls.innerHTML = `
      <button type="button" data-action="click->upload#moveLeft" data-move-left class="w-8 h-8 rounded-full bg-black/70 text-white text-base flex items-center justify-center disabled:opacity-30 disabled:cursor-not-allowed" aria-label="Move image earlier">‹</button>
      <button type="button" data-action="click->upload#moveRight" data-move-right class="w-8 h-8 rounded-full bg-black/70 text-white text-base flex items-center justify-center disabled:opacity-30 disabled:cursor-not-allowed" aria-label="Move image later">›</button>
    `
    wrapper.appendChild(orderControls)

    const removeBtn = document.createElement("button")
    removeBtn.type = "button"
    removeBtn.dataset.action = "click->upload#remove"
    removeBtn.className = "absolute top-1 right-1 w-6 h-6 rounded-full bg-black/60 text-white text-xs flex items-center justify-center"
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
