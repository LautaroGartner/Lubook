import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="carrousel"
export default class extends Controller {
  static targets = ["slide", "dot"]
  static values = { index: { type: Number, default: 0 } }

  next() {
    this.indexValue = (this.indexValue + 1) % this.slideTargets.length
  }

  prev() {
    this.indexValue = (this.indexValue - 1 + this.slideTargets.length) % this.slideTargets.length
  }

  goto(e) {
    this.indexValue = Number(e.params.index)
  }

  indexValueChanged() {
    this.slideTargets.forEach((s, i) => {
      s.classList.toggle("hidden", i !== this.indexValue)
    })
    this.dotTargets.forEach((d, i) => {
      const active = i === this.indexValue
      d.classList.toggle("bg-white", active)
      d.classList.toggle("bg-white/50", !active)
    })
  }
}