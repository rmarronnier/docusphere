import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge"]
  static values = { collapsed: Boolean }
  
  connect() {
    // Load saved state from localStorage
    const savedState = localStorage.getItem('actions-panel-collapsed')
    if (savedState !== null) {
      this.collapsedValue = savedState === 'true'
    }
  }
  
  toggle() {
    this.collapsedValue = !this.collapsedValue
  }
  
  collapsedValueChanged() {
    const panel = this.element.querySelector('.actions-panel')
    const content = this.element.querySelector('.p-4.space-y-3')
    const header = this.element.querySelector('.text-lg')
    const icon = this.element.querySelector('svg')
    const button = this.element.querySelector('[data-action*="toggle"]')
    
    if (this.collapsedValue) {
      panel?.classList.add('collapsed')
      content?.classList.add('hidden')
      header?.classList.add('hidden')
      icon?.classList.add('rotate-180')
      
      // Show badge if it exists
      if (this.hasBadgeTarget) {
        this.badgeTarget.classList.remove('hidden')
      }
    } else {
      panel?.classList.remove('collapsed')
      content?.classList.remove('hidden')
      header?.classList.remove('hidden')
      icon?.classList.remove('rotate-180')
      
      // Hide badge if it exists
      if (this.hasBadgeTarget) {
        this.badgeTarget.classList.add('hidden')
      }
    }
    
    // Update accessibility attributes
    if (button) {
      button.setAttribute('aria-expanded', !this.collapsedValue)
    }
    
    // Save state to localStorage
    localStorage.setItem('actions-panel-collapsed', String(this.collapsedValue))
    
    // Dispatch event for other components
    this.dispatch('toggled', { 
      detail: { collapsed: this.collapsedValue }
    })
  }
}