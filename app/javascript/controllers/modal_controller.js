import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  connect() {
    // Add event listener for ESC key globally when modal is open
    this.handleEscape = this.handleEscape.bind(this)
  }

  open(event) {
    event.preventDefault()
    
    const modalId = this.targetValue || event.currentTarget.dataset.modalTargetValue
    const modal = document.getElementById(modalId)
    
    if (modal) {
      modal.classList.remove('hidden')
      document.addEventListener('keydown', this.handleEscape)
      
      // Focus first input if available
      const firstInput = modal.querySelector('input:not([type="hidden"]), textarea, select')
      if (firstInput) {
        setTimeout(() => firstInput.focus(), 100)
      }
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    
    // Find the closest modal parent
    const modal = this.element.closest('.share-modal, [role="dialog"]') || this.element
    
    if (modal) {
      modal.classList.add('hidden')
      document.removeEventListener('keydown', this.handleEscape)
    }
  }

  closeOnBackdrop(event) {
    // Only close if clicking directly on the backdrop
    if (event.target === event.currentTarget) {
      this.close(event)
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  handleEscape(event) {
    if (event.key === 'Escape' || event.keyCode === 27) {
      this.close(event)
    }
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleEscape)
  }
}