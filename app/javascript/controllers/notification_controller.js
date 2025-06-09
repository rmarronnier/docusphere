import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static targets = ["markReadButton", "deleteButton", "unreadIndicator"]
  static values = { 
    read: Boolean, 
    urgent: Boolean,
    id: Number,
    markReadUrl: String,
    deleteUrl: String 
  }

  connect() {
    console.log("Notification controller connected", this.element)
    
    // Set initial state based on read status
    this.updateReadState()
    
    // Auto-refresh notifications periodically (optional)
    if (this.shouldAutoRefresh()) {
      this.startAutoRefresh()
    }
  }

  disconnect() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  // Mark notification as read
  async markAsRead(event) {
    event.preventDefault()
    
    try {
      const response = await fetch(this.markReadUrlValue || this.buildMarkReadUrl(), {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken(),
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        this.readValue = true
        this.updateReadState()
        this.showToast('Notification marquée comme lue', 'success')
        this.updateUnreadCount(-1)
      } else {
        throw new Error('Failed to mark notification as read')
      }
    } catch (error) {
      console.error('Error marking notification as read:', error)
      this.showToast('Erreur lors du marquage de la notification', 'error')
    }
  }

  // Delete notification
  async delete(event) {
    event.preventDefault()
    
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette notification ?')) {
      return
    }
    
    try {
      const response = await fetch(this.deleteUrlValue || this.buildDeleteUrl(), {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken(),
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        this.element.remove()
        this.showToast('Notification supprimée', 'success')
        this.updateUnreadCount(this.readValue ? 0 : -1)
      } else {
        throw new Error('Failed to delete notification')
      }
    } catch (error) {
      console.error('Error deleting notification:', error)
      this.showToast('Erreur lors de la suppression de la notification', 'error')
    }
  }

  // Handle click on notification (for navigation)
  navigate(event) {
    // If clicking on action buttons, don't navigate
    if (event.target.closest('[data-notification-target="markReadButton"]') ||
        event.target.closest('[data-notification-target="deleteButton"]')) {
      return
    }

    // Mark as read when navigating (if not already read)
    if (!this.readValue) {
      this.markAsRead(event)
    }
  }

  // Update visual state based on read status
  updateReadState() {
    this.element.dataset.notificationRead = this.readValue
    
    // Update visual indicators
    if (this.hasUnreadIndicatorTarget) {
      this.unreadIndicatorTarget.style.display = this.readValue ? 'none' : 'block'
    }
    
    // Update mark read button
    if (this.hasMarkReadButtonTarget) {
      this.markReadButtonTarget.style.display = this.readValue ? 'none' : 'block'
    }
    
    // Update element classes
    this.element.classList.toggle('notification--read', this.readValue)
    this.element.classList.toggle('notification--unread', !this.readValue)
  }

  // Build URLs if not provided as values
  buildMarkReadUrl() {
    return `/notifications/${this.idValue}/mark_as_read`
  }

  buildDeleteUrl() {
    return `/notifications/${this.idValue}`
  }

  // Get CSRF token
  getCsrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  // Show toast notification
  showToast(message, type = 'info') {
    // Create a simple toast notification
    const toast = document.createElement('div')
    toast.className = `notification-toast notification-toast--${type}`
    toast.textContent = message
    
    // Style the toast
    Object.assign(toast.style, {
      position: 'fixed',
      top: '20px',
      right: '20px',
      padding: '12px 20px',
      borderRadius: '6px',
      color: 'white',
      fontWeight: '500',
      zIndex: '1000',
      transform: 'translateX(100%)',
      transition: 'transform 0.3s ease-in-out'
    })
    
    // Set background color based on type
    const colors = {
      success: '#10B981',
      error: '#EF4444',
      warning: '#F59E0B',
      info: '#3B82F6'
    }
    toast.style.backgroundColor = colors[type] || colors.info
    
    // Add to page
    document.body.appendChild(toast)
    
    // Animate in
    setTimeout(() => {
      toast.style.transform = 'translateX(0)'
    }, 10)
    
    // Remove after delay
    setTimeout(() => {
      toast.style.transform = 'translateX(100%)'
      setTimeout(() => {
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast)
        }
      }, 300)
    }, 3000)
  }

  // Update unread count in navigation
  updateUnreadCount(delta) {
    const badge = document.querySelector('.notification-badge, [data-notification-count]')
    if (!badge) return
    
    const currentCount = parseInt(badge.textContent) || 0
    const newCount = Math.max(0, currentCount + delta)
    
    badge.textContent = newCount > 9 ? '9+' : newCount.toString()
    badge.style.display = newCount > 0 ? 'flex' : 'none'
  }

  // Check if should auto-refresh (only on notification pages)
  shouldAutoRefresh() {
    return window.location.pathname.includes('/notifications')
  }

  // Start auto-refresh interval
  startAutoRefresh() {
    this.refreshInterval = setInterval(() => {
      this.refreshNotifications()
    }, 30000) // Refresh every 30 seconds
  }

  // Refresh notifications (simple implementation)
  async refreshNotifications() {
    try {
      const response = await fetch(window.location.pathname, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        // This is a simple implementation
        // In a real app, you might want to update only changed notifications
        // or use ActionCable for real-time updates
        console.log('Notifications refreshed')
      }
    } catch (error) {
      console.error('Error refreshing notifications:', error)
    }
  }

  // Handle value changes
  readValueChanged() {
    this.updateReadState()
  }
}