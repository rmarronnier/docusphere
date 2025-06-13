import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Dropdown controller connected", this.element)
    console.log("Has menu target:", this.hasMenuTarget)
    this.close = this.close.bind(this)
  }

  toggle() {
    console.log("Dropdown toggle clicked")
    if (this.hasMenuTarget) {
      if (this.menuTarget.classList.contains("hidden")) {
        this.open()
      } else {
        this.close()
      }
    } else {
      console.error("No menu target found")
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.close)
  }

  close(event) {
    if (!event || !this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
      document.removeEventListener("click", this.close)
    }
  }
}