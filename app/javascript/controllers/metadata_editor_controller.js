import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "notification"]
  static values = { documentId: Number }

  edit(event) {
    event.preventDefault()
    
    // Reload the component in edit mode
    const url = `/ged/documents/${this.documentIdValue}/edit_metadata`
    
    fetch(url, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content || ''
      }
    })
    .then(response => response.text())
    .then(html => {
      // Replace the component content
      this.element.innerHTML = html
      
      // Re-initialize any nested controllers
      const event = new Event('turbo:load', { bubbles: true })
      this.element.dispatchEvent(event)
    })
    .catch(error => {
      console.error('Error loading edit form:', error)
    })
  }

  cancel(event) {
    event.preventDefault()
    
    // Reload the component in view mode
    const url = `/ged/documents/${this.documentIdValue}/metadata`
    
    fetch(url, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content || ''
      }
    })
    .then(response => response.text())
    .then(html => {
      // Replace the component content
      this.element.innerHTML = html
      
      // Re-initialize any nested controllers
      const event = new Event('turbo:load', { bubbles: true })
      this.element.dispatchEvent(event)
    })
    .catch(error => {
      console.error('Error loading view:', error)
    })
  }

  async save(event) {
    event.preventDefault()
    
    const form = this.formTarget
    const formData = new FormData(form)
    
    try {
      const response = await fetch(form.action, {
        method: form.method || 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content || ''
        }
      })

      if (response.ok) {
        const result = await response.json()
        
        // Show success notification
        this.showNotification()
        
        // Reload in view mode after a short delay
        setTimeout(() => {
          this.cancel(event)
        }, 1000)
        
        // Dispatch custom event
        this.dispatch('saved', { 
          detail: { 
            documentId: this.documentIdValue,
            metadata: result.metadata 
          } 
        })
      } else {
        const error = await response.json()
        this.showError(error.message || 'Erreur lors de l\'enregistrement')
      }
    } catch (error) {
      console.error('Error saving metadata:', error)
      this.showError('Erreur lors de l\'enregistrement des métadonnées')
    }
  }

  showNotification() {
    if (this.hasNotificationTarget) {
      const notification = this.notificationTarget
      notification.classList.remove('hidden')
      
      // Hide after 3 seconds
      setTimeout(() => {
        notification.classList.add('opacity-0')
        setTimeout(() => {
          notification.classList.add('hidden')
          notification.classList.remove('opacity-0')
        }, 300)
      }, 3000)
    } else {
      // Create notification if target doesn't exist
      this.createNotification('Métadonnées enregistrées avec succès', 'success')
    }
  }

  showError(message) {
    this.createNotification(message, 'error')
  }

  createNotification(message, type = 'info') {
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg transition-all duration-300 ${
      type === 'success' ? 'bg-green-500 text-white' : 
      type === 'error' ? 'bg-red-500 text-white' : 
      'bg-blue-500 text-white'
    }`
    notification.textContent = message
    
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