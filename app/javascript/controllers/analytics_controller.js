import { Controller } from "@hotwired/stimulus"

// Tracks time engaged and (on pages with an [data-analytics-target="article"]
// element) scroll depth, and reports both to Ahoy as a single event when the
// visitor leaves. Time engaged only counts while the tab is visible.
export default class extends Controller {
  static targets = ["article"]
  static values = { postId: Number, postTitle: String }

  connect() {
    this.engagedMs = 0
    this.visibleSince = document.visibilityState === "visible" ? performance.now() : null
    this.maxScrollPercent = 0
    this.sent = false

    this.handleVisibilityChange = this.handleVisibilityChange.bind(this)
    this.flush = this.flush.bind(this)
    this.handleScroll = this.handleScroll.bind(this)

    document.addEventListener("visibilitychange", this.handleVisibilityChange)
    window.addEventListener("pagehide", this.flush)

    if (this.hasArticleTarget) {
      window.addEventListener("scroll", this.handleScroll, { passive: true })
      this.handleScroll()
    }
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
    window.removeEventListener("pagehide", this.flush)
    window.removeEventListener("scroll", this.handleScroll)
    this.flush()
  }

  handleVisibilityChange() {
    if (document.visibilityState === "hidden") {
      this.accumulateEngagedTime()
    } else {
      this.visibleSince = performance.now()
    }
  }

  accumulateEngagedTime() {
    if (this.visibleSince !== null) {
      this.engagedMs += performance.now() - this.visibleSince
      this.visibleSince = null
    }
  }

  handleScroll() {
    const rect = this.articleTarget.getBoundingClientRect()
    const articleTop = window.scrollY + rect.top
    const articleHeight = rect.height
    if (articleHeight <= 0) return

    const scrolledInto = window.scrollY + window.innerHeight - articleTop
    const percent = Math.max(0, Math.min(100, (scrolledInto / articleHeight) * 100))
    if (percent > this.maxScrollPercent) this.maxScrollPercent = percent
  }

  flush() {
    if (this.sent || typeof ahoy === "undefined") return

    this.accumulateEngagedTime()
    const secondsEngaged = Math.round(this.engagedMs / 1000)
    if (secondsEngaged < 1 && this.maxScrollPercent === 0) return

    this.sent = true

    const properties = { path: window.location.pathname, seconds_engaged: secondsEngaged }
    if (this.hasArticleTarget) properties.max_scroll_percent = Math.round(this.maxScrollPercent)
    if (this.postIdValue) properties.post_id = this.postIdValue
    if (this.postTitleValue) properties.post_title = this.postTitleValue

    ahoy.track("Page engagement", properties)
  }
}
