import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyId", "replyPreview", "replyAuthor", "replyBody", "body"]

  submitOnEnter(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return
    if (window.matchMedia("(max-width: 767px), (pointer: coarse)").matches) return

    event.preventDefault()
    event.target.form?.requestSubmit()
  }

  reply(event) {
    const { messageId, messageAuthor, messagePreview } = event.currentTarget.dataset
    if (!messageId) return

    this.replyIdTarget.value = messageId
    this.replyAuthorTarget.textContent = messageAuthor || "Message"
    this.replyBodyTarget.textContent = messagePreview || ""
    this.replyPreviewTarget.classList.remove("hidden")
    this.bodyTarget.focus()
  }

  clearReply() {
    if (this.hasReplyIdTarget) this.replyIdTarget.value = ""
    if (this.hasReplyPreviewTarget) this.replyPreviewTarget.classList.add("hidden")
    if (this.hasReplyAuthorTarget) this.replyAuthorTarget.textContent = ""
    if (this.hasReplyBodyTarget) this.replyBodyTarget.textContent = ""
    if (this.hasBodyTarget) this.bodyTarget.focus()
  }
}
