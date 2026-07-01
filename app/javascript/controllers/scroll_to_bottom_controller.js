import { Controller } from "@hotwired/stimulus"

// Keeps a scrollable log pinned to the newest message. Watches for appended or
// replaced children (immediate placeholder + the ActionCable reply) and scrolls
// to the bottom on each change.
export default class extends Controller {
  connect() {
    this.scroll()
    this.observer = new MutationObserver(() => this.scroll())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scroll() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
