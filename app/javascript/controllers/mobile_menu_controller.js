import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Mobile menu controller connected", this.element)
    console.log("Has menu target:", this.hasMenuTarget)
  }

  toggle() {
    console.log("Toggle mobile menu")
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("hidden")
    } else {
      console.error("No menu target found")
    }
  }

  close() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
    }
  }
}