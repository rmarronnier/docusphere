import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="character-count"
export default class extends Controller {
  static targets = ["counter"]

  connect() {
    this.update()
  }

  update() {
    const currentLength = this.element.value.length
    const maxLength = this.maxLength
    
    // Find or create the counter element
    let counter = this.counterTarget || this.findOrCreateCounter()
    
    if (maxLength) {
      const remaining = maxLength - currentLength
      counter.textContent = `${currentLength}/${maxLength}`
      
      // Update color based on remaining characters
      if (remaining < 10) {
        counter.className = counter.className.replace(/text-\w+-\d+/g, 'text-red-500')
      } else if (remaining < 50) {
        counter.className = counter.className.replace(/text-\w+-\d+/g, 'text-yellow-500')
      } else {
        counter.className = counter.className.replace(/text-\w+-\d+/g, 'text-gray-500')
      }
    } else {
      counter.textContent = `${currentLength} characters`
    }
  }

  findOrCreateCounter() {
    // Look for existing counter in the parent container
    const container = this.element.closest('.relative')
    let counter = container?.querySelector('.character-counter')
    
    if (!counter) {
      // Create new counter element
      counter = document.createElement('div')
      counter.className = 'character-counter absolute bottom-2 right-2 text-xs text-gray-500'
      counter.setAttribute('data-character-count-target', 'counter')
      
      // Insert into the relative container
      if (container) {
        container.appendChild(counter)
      } else {
        this.element.parentElement.appendChild(counter)
      }
    }
    
    return counter
  }

  get maxLength() {
    return parseInt(this.element.getAttribute('maxlength'))
  }

  get hasCounterTarget() {
    return this.targets.has('counter')
  }
}