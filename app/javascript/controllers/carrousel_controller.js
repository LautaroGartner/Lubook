import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot", "counter", "prevBtn", "nextBtn"]
  static values = { index: { type: Number, default: 0 } }
  static instances = new Set()

  connect() {
    this.touchStartX = null
    this.touchStartY = null
    this.touchMoved = false
    this.suppressClick = false
    this.constructor.instances.add(this)
    this.element.addEventListener("touchstart", this.onTouchStart, { passive: true })
    this.element.addEventListener("touchmove", this.onTouchMove, { passive: true })
    this.element.addEventListener("touchend", this.onTouchEnd)
  }

  disconnect() {
    this.constructor.instances.delete(this)
    this.element.removeEventListener("touchstart", this.onTouchStart)
    this.element.removeEventListener("touchmove", this.onTouchMove)
    this.element.removeEventListener("touchend", this.onTouchEnd)
    if (this.constructor.activeCarousel === this) {
      this.constructor.activeCarousel = null
    }
  }

  onTouchStart = (e) => {
    const t = e.changedTouches[0]
    this.touchStartX = t.clientX
    this.touchStartY = t.clientY
  }

  onTouchMove = (e) => {
    if (this.touchStartX === null) return

    const t = e.changedTouches[0]
    const dx = t.clientX - this.touchStartX
    const dy = t.clientY - this.touchStartY
    this.touchMoved = Math.abs(dx) > 12 || Math.abs(dy) > 12
  }

  onTouchEnd = (e) => {
    if (this.touchStartX === null) return
    this.activate()
    const t = e.changedTouches[0]
    const dx = t.clientX - this.touchStartX
    const dy = t.clientY - this.touchStartY
    if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy)) {
      e.preventDefault()
      this.suppressClick = true
      clearTimeout(this.suppressClickTimeout)
      this.suppressClickTimeout = setTimeout(() => {
        this.suppressClick = false
      }, 350)
      if (dx < 0) this.next()
      else this.prev()
    }
    this.touchStartX = null
    this.touchStartY = null
    this.touchMoved = false
  }

  activate() {
    this.constructor.activeCarousel = this
  }

  next(event) {
    if (!this.shouldHandle(event)) return
    if (event?.type === "keydown") event.preventDefault()
    if (this.indexValue >= this.slideTargets.length - 1) return
    this.indexValue = this.indexValue + 1
  }

  prev(event) {
    if (!this.shouldHandle(event)) return
    if (event?.type === "keydown") event.preventDefault()
    if (this.indexValue <= 0) return
    this.indexValue = this.indexValue - 1
  }

  open(event) {
    this.activate()
    if (this.touchMoved || this.suppressClick) {
      event.preventDefault()
      return
    }

    const lightboxController = this.application.getControllerForElementAndIdentifier(
      this.element.closest("[data-controller~='lightbox']"),
      "lightbox"
    )
    lightboxController?.open(event)
  }

  goto(e) {
    this.activate()
    this.indexValue = Number(e.params.index)
  }

  shouldHandle(event) {
    if (event?.type !== "keydown") {
      this.activate()
      return true
    }

    return this.constructor.currentViewedCarousel() === this
  }

  static currentViewedCarousel() {
    let best = null
    let bestScore = -Infinity
    const viewportHeight = window.innerHeight || document.documentElement.clientHeight
    const viewportCenterY = viewportHeight / 2

    this.instances.forEach((controller) => {
      const rect = controller.element.getBoundingClientRect()
      if (rect.bottom <= 0 || rect.top >= viewportHeight) return

      const visibleTop = Math.max(rect.top, 0)
      const visibleBottom = Math.min(rect.bottom, viewportHeight)
      const visibleHeight = Math.max(0, visibleBottom - visibleTop)
      const distanceFromCenter = Math.abs((rect.top + rect.bottom) / 2 - viewportCenterY)
      const containsCenter = rect.top <= viewportCenterY && rect.bottom >= viewportCenterY ? viewportHeight : 0
      const score = containsCenter + visibleHeight - distanceFromCenter * 0.25

      if (score > bestScore) {
        bestScore = score
        best = controller
      }
    })

    return best
  }

  indexValueChanged() {
    this.slideTargets.forEach((s, i) => {
      const active = i === this.indexValue
      s.classList.toggle("hidden", !active)
      s.classList.toggle("block", active)
    })
    this.dotTargets.forEach((d, i) => {
      const active = i === this.indexValue
      d.classList.toggle("bg-white", active)
      d.classList.toggle("bg-white/60", !active)
    })
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.indexValue + 1
    }
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.classList.toggle("opacity-30", this.indexValue === 0)
      this.prevBtnTarget.classList.toggle("cursor-not-allowed", this.indexValue === 0)
    }
    if (this.hasNextBtnTarget) {
      const atEnd = this.indexValue === this.slideTargets.length - 1
      this.nextBtnTarget.classList.toggle("opacity-30", atEnd)
      this.nextBtnTarget.classList.toggle("cursor-not-allowed", atEnd)
    }
  }
}
