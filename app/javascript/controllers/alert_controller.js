import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    this.element.style.transition = 'opacity 150ms ease-in-out'
    this.element.style.opacity = '0'
    
    setTimeout(() => {
      this.element.remove()
    }, 150)
  }
}