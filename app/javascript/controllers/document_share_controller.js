import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["emailInput", "permissionSelect", "messageInput", "submitButton"]

  connect() {
    this.validateEmail()
  }

  validateEmail() {
    const email = this.emailInputTarget.value
    const isValid = this.isValidEmail(email)
    
    this.submitButtonTarget.disabled = !isValid
    
    if (email && !isValid) {
      this.emailInputTarget.classList.add("border-red-300")
      this.emailInputTarget.classList.remove("border-gray-300")
    } else {
      this.emailInputTarget.classList.remove("border-red-300")
      this.emailInputTarget.classList.add("border-gray-300")
    }
  }

  selectUser(event) {
    event.preventDefault()
    const email = event.currentTarget.dataset.email
    
    if (email) {
      this.emailInputTarget.value = email
      this.validateEmail()
      this.emailInputTarget.focus()
    }
  }

  onSuccess(event) {
    const [data, status, xhr] = event.detail
    
    // Close the modal
    const modal = this.element.closest('.share-modal')
    if (modal) {
      modal.classList.add('hidden')
    }
    
    // Show success notification
    const notification = document.getElementById('share-success-notification')
    if (notification) {
      notification.classList.remove('hidden')
      
      // Auto-hide after delay
      const delay = parseInt(notification.dataset.notificationDelayValue || 3000)
      setTimeout(() => {
        notification.classList.add('hidden')
      }, delay)
    }
    
    // Reset form
    this.element.reset()
    
    // Dispatch custom event for other components to listen to
    this.dispatch('shared', { 
      detail: { 
        email: this.emailInputTarget.value,
        permission: this.permissionSelectTarget.value,
        message: this.messageInputTarget.value
      } 
    })
  }

  onError(event) {
    const [data, status, xhr] = event.detail
    
    // Show error message
    let errorMessage = 'Une erreur est survenue lors du partage.'
    
    if (data && data.error) {
      errorMessage = data.error
    } else if (xhr && xhr.responseJSON && xhr.responseJSON.error) {
      errorMessage = xhr.responseJSON.error
    }
    
    // You could show an error notification here
    // For now, we'll use alert
    alert(errorMessage)
    
    // Re-enable submit button
    this.submitButtonTarget.disabled = false
  }

  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }
}