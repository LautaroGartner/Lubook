import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyForm", "replyInput", "hiddenReplies", "showRepliesButton", "hideRepliesButton"]

  toggleReply(event) {
    event.preventDefault()

    this.replyFormTarget.classList.toggle("hidden")

    if (!this.replyFormTarget.classList.contains("hidden")) {
      requestAnimationFrame(() => {
        this.centerReplyForm()
        window.setTimeout(() => this.centerReplyForm(), 180)
        this.replyInputTarget.focus()
        this.replyInputTarget.setSelectionRange(
          this.replyInputTarget.value.length,
          this.replyInputTarget.value.length
        )
      })
    }
  }

  expandReplies(event) {
    event.preventDefault()
    this.hiddenRepliesTarget.classList.remove("hidden")
    this.showRepliesButtonTarget.classList.add("hidden")
    if (this.hasHideRepliesButtonTarget) {
      this.hideRepliesButtonTarget.classList.remove("hidden")
    }
  }

  collapseReplies(event) {
    event.preventDefault()
    this.hiddenRepliesTarget.classList.add("hidden")
    this.showRepliesButtonTarget.classList.remove("hidden")
    if (this.hasHideRepliesButtonTarget) {
      this.hideRepliesButtonTarget.classList.add("hidden")
    }
  }

  centerReplyForm() {
    const rect = this.replyFormTarget.getBoundingClientRect()
    const top = window.scrollY + rect.top - (window.innerHeight / 2) + (rect.height / 2)

    window.scrollTo({
      top: Math.max(top, 0),
      behavior: "smooth"
    })
  }
}
