import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    documentId: Number,
    publicLinkUrl: String,
    moveUrl: String,
    requestValidationUrl: String
  }

  connect() {
    this.documentId = this.documentIdValue || this.element.dataset.documentId
  }

  move(event) {
    event.preventDefault()
    const modal = document.getElementById('move-document-modal')
    if (modal) {
      modal.classList.remove('hidden')
      modal.dispatchEvent(new Event('modal:open'))
    }
  }

  requestValidation(event) {
    event.preventDefault()
    const modal = document.getElementById('request-validation-modal')
    if (modal) {
      modal.classList.remove('hidden')
      modal.dispatchEvent(new Event('modal:open'))
    }
  }

  async generatePublicLink(event) {
    event.preventDefault()
    
    try {
      const response = await fetch(`/ged/documents/${this.documentId}/generate_public_link`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content || ''
        }
      })

      if (!response.ok) {
        throw new Error('Network response was not ok')
      }

      const data = await response.json()
      
      if (data.public_link) {
        // Copy to clipboard
        await navigator.clipboard.writeText(data.public_link)
        
        // Show success notification
        this.showNotification('Lien public copié dans le presse-papiers', 'success')
        
        // Dispatch custom event
        this.dispatch('public-link-generated', { 
          detail: { publicLink: data.public_link } 
        })
      }
    } catch (error) {
      console.error('Error generating public link:', error)
      this.showNotification('Erreur lors de la génération du lien public', 'error')
    }
  }

  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg transition-all duration-300 ${
      type === 'success' ? 'bg-green-500 text-white' : 
      type === 'error' ? 'bg-red-500 text-white' : 
      'bg-blue-500 text-white'
    }`
    notification.textContent = message
    
    // Add to DOM
    document.body.appendChild(notification)
    
    // Remove after 3 seconds
    setTimeout(() => {
      notification.classList.add('opacity-0')
      setTimeout(() => notification.remove(), 300)
    }, 3000)
  }

  dispatch(eventName, options = {}) {
    this.element.dispatchEvent(new CustomEvent(eventName, {
      bubbles: true,
      ...options
    }))
  }
}