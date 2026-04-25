import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const carousel = event.currentTarget.closest("[data-controller~='carrousel']")
    let urls = []
    let startIndex = 0

    if (carousel) {
      const slides = carousel.querySelectorAll("[data-carrousel-target='slide']")
      urls = Array.from(slides).map(s => s.dataset.lightboxFullUrlValue).filter(Boolean)
      startIndex = Array.from(slides).indexOf(event.currentTarget)
    } else {
      const url = event.currentTarget.dataset.lightboxFullUrlValue
      if (url) urls = [url]
    }

    if (urls.length === 0) return
    this.openOverlay(urls, startIndex)
  }

  openOverlay(urls, startIndex) {
    let currentIndex = startIndex

    const overlay = document.createElement("div")
    overlay.className = "fixed inset-0 bg-black/85 z-50 flex items-center justify-center p-3 sm:p-4 select-none"

    const row = document.createElement("div")
    row.className = "relative flex h-full w-full items-center justify-center"

    const prevBtn = document.createElement("button")
    prevBtn.type = "button"
    prevBtn.className = "absolute left-2 top-1/2 z-10 -translate-y-1/2 bg-black/55 hover:bg-black/75 disabled:opacity-30 disabled:cursor-not-allowed text-white rounded-full w-10 h-10 sm:w-12 sm:h-12 flex items-center justify-center text-2xl transition"
    prevBtn.textContent = "‹"

    const img = document.createElement("img")
    img.className = "max-h-[calc(100dvh-8rem)] max-w-[calc(100vw-1.5rem)] sm:max-h-[90vh] sm:max-w-[80vw] rounded shadow-2xl object-contain transition-opacity duration-150 ease-out"
    img.src = urls[currentIndex]

    const nextBtn = document.createElement("button")
    nextBtn.type = "button"
    nextBtn.className = "absolute right-2 top-1/2 z-10 -translate-y-1/2 bg-black/55 hover:bg-black/75 disabled:opacity-30 disabled:cursor-not-allowed text-white rounded-full w-10 h-10 sm:w-12 sm:h-12 flex items-center justify-center text-2xl transition"
    nextBtn.textContent = "›"

    const imgWrap = document.createElement("div")
    imgWrap.className = "relative inline-flex max-h-full max-w-full items-center justify-center"
    imgWrap.appendChild(img)

    if (urls.length > 1) {
      row.appendChild(prevBtn)
      row.appendChild(imgWrap)
      row.appendChild(nextBtn)
    } else {
      row.appendChild(imgWrap)
    }
    overlay.appendChild(row)

    let counter = null
    if (urls.length > 1) {
      counter = document.createElement("div")
      counter.className = "absolute top-3 right-3 bg-black/70 text-white text-xs px-2.5 py-1 rounded-full font-medium pointer-events-none"
      counter.textContent = `${currentIndex + 1} / ${urls.length}`
      imgWrap.appendChild(counter)
    }

    const updateButtons = () => {
      prevBtn.disabled = currentIndex === 0
      nextBtn.disabled = currentIndex === urls.length - 1
    }

    const close = () => {
      overlay.remove()
      document.removeEventListener("keydown", onKey)
    }

    const go = (delta) => {
      const target = currentIndex + delta
      if (target < 0 || target >= urls.length) return
      const nextImage = new Image()
      nextImage.onload = () => {
        currentIndex = target
        img.src = nextImage.src
        if (counter) counter.textContent = `${currentIndex + 1} / ${urls.length}`
        updateButtons()
      }
      nextImage.src = urls[target]
      updateButtons()
    }

    prevBtn.addEventListener("click", (e) => { e.stopPropagation(); go(-1) })
    nextBtn.addEventListener("click", (e) => { e.stopPropagation(); go(1) })

    const onKey = (e) => {
      if (e.key === "Escape") close()
      else if (e.key === "ArrowLeft" && urls.length > 1) go(-1)
      else if (e.key === "ArrowRight" && urls.length > 1) go(1)
    }

    let touchStartX = null, touchStartY = null
    overlay.addEventListener("touchstart", (e) => {
      const t = e.changedTouches[0]
      touchStartX = t.clientX
      touchStartY = t.clientY
    }, { passive: true })
    overlay.addEventListener("touchend", (e) => {
      if (touchStartX === null) return
      const t = e.changedTouches[0]
      const dx = t.clientX - touchStartX
      const dy = t.clientY - touchStartY
      if (Math.abs(dx) > 50 && Math.abs(dx) > Math.abs(dy) && urls.length > 1) {
        go(dx < 0 ? 1 : -1)
      }
      touchStartX = null
      touchStartY = null
    }, { passive: true })

    overlay.addEventListener("click", (e) => {
      if (e.target === overlay || e.target === row) close()
    })

    updateButtons()
    document.addEventListener("keydown", onKey)
    document.body.appendChild(overlay)
  }
}
