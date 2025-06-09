import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="bulk-actions"
export default class extends Controller {
  static targets = ["toolbar", "count", "markReadButton", "deleteButton", "selectAll", "checkbox"]
  static values = { notifications: Array }

  connect() {
    console.log("Bulk actions controller connected")
    this.selectedIds = new Set()
    this.updateToolbarVisibility()
  }

  // Toggle individual notification selection
  toggleNotification(event) {
    const checkbox = event.currentTarget
    const notificationId = checkbox.value
    
    if (checkbox.checked) {
      this.selectedIds.add(notificationId)
    } else {
      this.selectedIds.delete(notificationId)
    }
    
    this.updateUI()
  }

  // Toggle all notifications
  toggleAll(event) {
    const selectAllCheckbox = event.currentTarget
    const checkboxes = this.checkboxTargets
    
    checkboxes.forEach(checkbox => {
      checkbox.checked = selectAllCheckbox.checked
      
      if (selectAllCheckbox.checked) {
        this.selectedIds.add(checkbox.value)
      } else {
        this.selectedIds.delete(checkbox.value)
      }
    })
    
    this.updateUI()
  }

  // Mark selected notifications as read
  async markAsRead(event) {
    event.preventDefault()
    
    if (this.selectedIds.size === 0) {
      this.showToast('Aucune notification sélectionnée', 'warning')
      return
    }
    
    try {
      const response = await fetch('/notifications/bulk_mark_as_read', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken(),
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          notification_ids: Array.from(this.selectedIds)
        })
      })

      if (response.ok) {
        const data = await response.json()
        this.updateNotificationsAsRead()
        this.clearSelection()
        this.showToast(`${data.count} notifications marquées comme lues`, 'success')
      } else {
        throw new Error('Failed to mark notifications as read')
      }
    } catch (error) {
      console.error('Error marking notifications as read:', error)
      this.showToast('Erreur lors du marquage des notifications', 'error')
    }
  }

  // Delete selected notifications
  async delete(event) {
    event.preventDefault()
    
    if (this.selectedIds.size === 0) {
      this.showToast('Aucune notification sélectionnée', 'warning')
      return
    }
    
    if (!confirm(`Êtes-vous sûr de vouloir supprimer ${this.selectedIds.size} notifications ?`)) {
      return
    }
    
    try {
      const response = await fetch('/notifications/bulk_destroy', {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken(),
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          notification_ids: Array.from(this.selectedIds)
        })
      })

      if (response.ok) {
        const data = await response.json()
        this.removeSelectedNotifications()
        this.clearSelection()
        this.showToast(`${data.count} notifications supprimées`, 'success')
      } else {
        throw new Error('Failed to delete notifications')
      }
    } catch (error) {
      console.error('Error deleting notifications:', error)
      this.showToast('Erreur lors de la suppression des notifications', 'error')
    }
  }

  // Update UI based on selection
  updateUI() {
    this.updateToolbarVisibility()
    this.updateSelectAllState()
    this.updateCount()
    this.updateButtonStates()
  }

  // Update toolbar visibility
  updateToolbarVisibility() {
    if (this.hasToolbarTarget) {
      this.toolbarTarget.style.display = this.selectedIds.size > 0 ? 'flex' : 'none'
    }
  }

  // Update select all checkbox state
  updateSelectAllState() {
    if (this.hasSelectAllTarget) {
      const totalCheckboxes = this.checkboxTargets.length
      const selectedCount = this.selectedIds.size
      
      this.selectAllTarget.checked = selectedCount === totalCheckboxes && totalCheckboxes > 0
      this.selectAllTarget.indeterminate = selectedCount > 0 && selectedCount < totalCheckboxes
    }
  }

  // Update count display
  updateCount() {
    if (this.hasCountTarget) {
      this.countTarget.textContent = this.selectedIds.size
    }
  }

  // Update button states
  updateButtonStates() {
    const hasSelection = this.selectedIds.size > 0
    
    if (this.hasMarkReadButtonTarget) {
      this.markReadButtonTarget.disabled = !hasSelection
    }
    
    if (this.hasDeleteButtonTarget) {
      this.deleteButtonTarget.disabled = !hasSelection
    }
  }

  // Clear all selections
  clearSelection() {
    this.selectedIds.clear()
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    this.updateUI()
  }

  // Update notifications as read in the UI
  updateNotificationsAsRead() {
    this.selectedIds.forEach(id => {
      const notificationElement = document.querySelector(`[data-notification-id="${id}"]`)
      if (notificationElement) {
        // Update the notification controller if it exists
        const notificationController = this.application.getControllerForElementAndIdentifier(
          notificationElement, 
          'notification'
        )
        
        if (notificationController) {
          notificationController.readValue = true
        }
        
        // Update visual state
        notificationElement.classList.add('notification--read')
        notificationElement.classList.remove('notification--unread')
        
        // Hide mark as read button
        const markReadButton = notificationElement.querySelector('[data-notification-target="markReadButton"]')
        if (markReadButton) {
          markReadButton.style.display = 'none'
        }
        
        // Hide unread indicator
        const unreadIndicator = notificationElement.querySelector('[data-notification-target="unreadIndicator"]')
        if (unreadIndicator) {
          unreadIndicator.style.display = 'none'
        }
      }
    })
  }

  // Remove selected notifications from UI
  removeSelectedNotifications() {
    this.selectedIds.forEach(id => {
      const notificationElement = document.querySelector(`[data-notification-id="${id}"]`)
      if (notificationElement) {
        notificationElement.remove()
      }
    })
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
    toast.className = `bulk-action-toast bulk-action-toast--${type}`
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
}