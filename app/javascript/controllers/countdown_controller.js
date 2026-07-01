import { Controller } from "@hotwired/stimulus"

// Live countdown to a deadline. When it hits zero it reloads the page so the
// server re-renders the new sale status (opens the buy button, or shows ended).
export default class extends Controller {
  static targets = ["display"]
  static values = { deadline: String }

  connect() {
    this.deadline = new Date(this.deadlineValue).getTime()
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const remaining = this.deadline - Date.now()
    if (remaining <= 0) {
      clearInterval(this.timer)
      window.location.reload()
      return
    }
    this.displayTarget.textContent = this.format(remaining)
  }

  format(ms) {
    const total = Math.floor(ms / 1000)
    const days = Math.floor(total / 86400)
    const h = String(Math.floor((total % 86400) / 3600)).padStart(2, "0")
    const m = String(Math.floor((total % 3600) / 60)).padStart(2, "0")
    const s = String(total % 60).padStart(2, "0")
    return days > 0 ? `${days}d ${h}:${m}:${s}` : `${h}:${m}:${s}`
  }
}
