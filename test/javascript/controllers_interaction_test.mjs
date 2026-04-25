import assert from "node:assert/strict"
import fs from "node:fs"

class FakeElement {
  constructor({ rect = null, dataset = {} } = {}) {
    this.children = []
    this.classList = new FakeClassList()
    this.dataset = dataset
    this.disabled = false
    this.parentNode = null
    this.rect = rect || { top: 0, bottom: 0 }
    this.style = {}
    this.textContent = ""
  }

  appendChild(child) {
    if (child.parentNode) child.parentNode.children = child.parentNode.children.filter((c) => c !== child)
    this.children.push(child)
    child.parentNode = this
    return child
  }

  addEventListener() {}
  removeEventListener() {}

  closest(selector) {
    let current = this
    while (current) {
      if (selector === "[data-preview]" && Object.hasOwn(current.dataset, "preview")) return current
      if (selector === "[data-controller~='lightbox']" && current.dataset.controller?.split(" ").includes("lightbox")) return current
      current = current.parentNode
    }
    return null
  }

  getBoundingClientRect() {
    return this.rect
  }

  querySelector(selector) {
    return findChild(this, selector)
  }
}

class FakeClassList {
  constructor() {
    this.values = new Set()
  }

  add(value) {
    this.values.add(value)
  }

  remove(value) {
    this.values.delete(value)
  }

  toggle(value, force) {
    if (force === undefined) {
      if (this.values.has(value)) this.values.delete(value)
      else this.values.add(value)
      return
    }

    if (force) this.values.add(value)
    else this.values.delete(value)
  }

  contains(value) {
    return this.values.has(value)
  }
}

function findChild(root, selector) {
  for (const child of root.children) {
    if (matches(child, selector)) return child
    const nested = findChild(child, selector)
    if (nested) return nested
  }
  return null
}

function matches(element, selector) {
  if (selector === "[data-position]") return Object.hasOwn(element.dataset, "position")
  if (selector === "[data-move-left]") return Object.hasOwn(element.dataset, "moveLeft")
  if (selector === "[data-move-right]") return Object.hasOwn(element.dataset, "moveRight")
  return false
}

function loadController(path, extraGlobals = "") {
  const source = fs.readFileSync(path, "utf8")
    .replace('import { Controller } from "@hotwired/stimulus"\n', "const Controller = class {}\n")
    .replace('import { DirectUpload } from "@rails/activestorage"\n', `${extraGlobals}\n`)
    .replace("export default class extends Controller", "return class extends Controller")

  return new Function(source)()
}

function previewEntry(name) {
  const previewEl = new FakeElement({ dataset: { preview: "" } })
  const position = new FakeElement({ dataset: { position: "" } })
  const left = new FakeElement({ dataset: { moveLeft: "" } })
  const right = new FakeElement({ dataset: { moveRight: "" } })
  const hiddenInput = new FakeElement()
  hiddenInput.value = name
  previewEl.appendChild(position)
  previewEl.appendChild(left)
  previewEl.appendChild(right)
  return { name, previewEl, hiddenInput, left, right, position }
}

function createCarouselController(Carousel, rect) {
  const controller = new Carousel()
  controller.element = new FakeElement({ rect })
  controller.indexValue = 0
  controller.trackTarget = new FakeElement()
  controller.slideTargets = [new FakeElement(), new FakeElement()]
  controller.dotTargets = []
  return controller
}

function testCarouselKeyboardTargetsViewedPost() {
  globalThis.window = { innerHeight: 800 }
  globalThis.document = { documentElement: { clientHeight: 800 } }

  const Carousel = loadController("app/javascript/controllers/carrousel_controller.js")
  Carousel.instances = new Set()

  const aboveCenter = createCarouselController(Carousel, { top: 0, bottom: 250 })
  const centered = createCarouselController(Carousel, { top: 280, bottom: 780 })
  aboveCenter.connect()
  centered.connect()

  let prevented = 0
  const keydown = { type: "keydown", preventDefault: () => prevented++ }
  aboveCenter.next(keydown)
  centered.next(keydown)

  assert.equal(aboveCenter.indexValue, 0)
  assert.equal(centered.indexValue, 1)
  assert.equal(centered.trackTarget.style.transform, "translateX(-100%)")
  assert.equal(prevented, 1)
}

function testCarouselSwipeDoesNotOpenLightbox() {
  globalThis.window = { innerHeight: 800 }
  globalThis.document = { documentElement: { clientHeight: 800 } }

  const Carousel = loadController("app/javascript/controllers/carrousel_controller.js")
  Carousel.instances = new Set()

  const controller = createCarouselController(Carousel, { top: 100, bottom: 700 })
  controller.application = {
    getControllerForElementAndIdentifier: () => ({
      open: () => {
        throw new Error("lightbox should not open after a swipe")
      }
    })
  }
  controller.connect()
  controller.onTouchStart({ changedTouches: [{ clientX: 200, clientY: 120 }] })

  let touchPrevented = false
  controller.onTouchEnd({
    changedTouches: [{ clientX: 120, clientY: 124 }],
    preventDefault: () => {
      touchPrevented = true
    }
  })

  let clickPrevented = false
  controller.open({
    currentTarget: new FakeElement(),
    preventDefault: () => {
      clickPrevented = true
    }
  })

  assert.equal(controller.indexValue, 1)
  assert.equal(touchPrevented, true)
  assert.equal(clickPrevented, true)
}

function testUploadMoveButtonsSyncPreviewAndSubmitOrder() {
  const Upload = loadController("app/javascript/controllers/upload_controller.js", "const DirectUpload = class {}")
  const controller = new Upload()
  controller.previewsTarget = new FakeElement()
  controller.hiddenInputsTarget = new FakeElement()

  const first = previewEntry("first")
  const second = previewEntry("second")
  const third = previewEntry("third")
  controller.files = [first, second, third]
  controller.files.forEach((entry) => {
    controller.previewsTarget.appendChild(entry.previewEl)
    controller.hiddenInputsTarget.appendChild(entry.hiddenInput)
  })
  controller.updatePreviewOrder()

  let prevented = false
  controller.moveRight({
    currentTarget: first.right,
    preventDefault: () => {
      prevented = true
    }
  })

  assert.equal(prevented, true)
  assert.deepEqual(controller.files.map((entry) => entry.name), ["second", "first", "third"])
  assert.deepEqual(controller.previewsTarget.children.map((child) => controller.files.find((entry) => entry.previewEl === child).name), ["second", "first", "third"])
  assert.deepEqual(controller.hiddenInputsTarget.children.map((child) => child.value), ["second", "first", "third"])
  assert.equal(second.left.disabled, true)
  assert.equal(third.right.disabled, true)
}

testCarouselKeyboardTargetsViewedPost()
testCarouselSwipeDoesNotOpenLightbox()
testUploadMoveButtonsSyncPreviewAndSubmitOrder()

console.log("JavaScript controller interaction tests passed")
