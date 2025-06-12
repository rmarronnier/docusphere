import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["badge", "list", "turboFrame"]
  static values = { 
    userId: Number,
    channel: String
  }

  connect() {
    this.setupActionCable()
    this.setupNotificationSounds()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  setupActionCable() {
    // Create ActionCable consumer if not exists
    if (!window.App) {
      window.App = {}
    }
    
    if (!window.App.cable) {
      window.App.cable = createConsumer()
    }

    // Subscribe to notification channel
    this.subscription = window.App.cable.subscriptions.create(
      {
        channel: "NotificationChannel",
        user_id: this.userIdValue
      },
      {
        connected: () => {
          console.log("Connected to NotificationChannel")
        },

        disconnected: () => {
          console.log("Disconnected from NotificationChannel")
        },

        received: (data) => {
          this.handleNotificationReceived(data)
        }
      }
    )
  }

  setupNotificationSounds() {
    // Create audio element for notification sound
    this.notificationSound = new Audio('/sounds/notification.mp3')
    this.notificationSound.volume = 0.3
  }

  handleNotificationReceived(data) {
    switch(data.action) {
      case 'new_notification':
        this.addNewNotification(data.notification)
        this.updateBadge(data.unread_count)
        this.playNotificationSound()
        this.showDesktopNotification(data.notification)
        break
      case 'mark_as_read':
        this.markNotificationAsRead(data.notification_id)
        this.updateBadge(data.unread_count)
        break
      case 'mark_all_as_read':
        this.markAllAsRead()
        this.updateBadge(0)
        break
      case 'update_count':
        this.updateBadge(data.unread_count)
        break
    }
  }

  addNewNotification(notification) {
    // Insert new notification at the top of the list
    if (this.hasListTarget) {
      const notificationHtml = this.buildNotificationHtml(notification)
      this.listTarget.insertAdjacentHTML('afterbegin', notificationHtml)
      
      // Remove empty state if exists
      const emptyState = this.listTarget.querySelector('.empty-state')
      if (emptyState) {
        emptyState.remove()
      }
      
      // Limit displayed notifications
      const notifications = this.listTarget.querySelectorAll('[id^="notification-item-"]')
      if (notifications.length > 5) {
        notifications[notifications.length - 1].remove()
      }
    }
  }

  buildNotificationHtml(notification) {
    const iconHtml = this.getNotificationIcon(notification.notification_type)
    const colorClass = this.getNotificationColor(notification.priority)
    const timeText = this.formatNotificationTime(notification.created_at)
    
    return `
      <div id="notification-item-${notification.id}" class="bg-blue-50">
        <a href="${notification.path}" 
           class="block px-4 py-3 hover:bg-gray-50 transition-colors"
           data-notification-id="${notification.id}"
           data-action="click->notification-bell#markAsRead">
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <div class="w-8 h-8 bg-${colorClass}-100 rounded-full flex items-center justify-center">
                <svg class="w-5 h-5 text-${colorClass}-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  ${iconHtml}
                </svg>
              </div>
            </div>
            <div class="ml-3 flex-1">
              <div class="flex items-center justify-between">
                <p class="text-sm font-semibold text-gray-900">
                  ${notification.title}
                </p>
                <span class="w-2 h-2 bg-blue-600 rounded-full flex-shrink-0 ml-2"></span>
              </div>
              <p class="mt-1 text-sm text-gray-600 line-clamp-2">
                ${notification.message}
              </p>
              <p class="mt-1 text-xs text-gray-500">
                ${timeText}
              </p>
            </div>
          </div>
        </a>
      </div>
    `
  }

  getNotificationIcon(type) {
    const icons = {
      'validation_request': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />',
      'document_shared': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m9.032 4.026a3 3 0 10-5.464 0m5.464 0a3 3 0 01-5.464 0M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />',
      'deadline_approaching': '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />'
    }
    
    return icons[type] || '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />'
  }

  getNotificationColor(priority) {
    const colors = {
      'urgent': 'red',
      'high': 'red',
      'normal': 'yellow',
      'medium': 'yellow',
      'low': 'green'
    }
    
    return colors[priority] || 'gray'
  }

  formatNotificationTime(timestamp) {
    const date = new Date(timestamp)
    const now = new Date()
    const diffInSeconds = Math.floor((now - date) / 1000)
    
    if (diffInSeconds < 60) {
      return 'À l\'instant'
    } else if (diffInSeconds < 3600) {
      const minutes = Math.floor(diffInSeconds / 60)
      return `il y a ${minutes} minute${minutes > 1 ? 's' : ''}`
    } else if (diffInSeconds < 86400) {
      const hours = Math.floor(diffInSeconds / 3600)
      return `il y a ${hours} heure${hours > 1 ? 's' : ''}`
    } else {
      return date.toLocaleDateString('fr-FR')
    }
  }

  updateBadge(count) {
    if (this.hasBadgeTarget) {
      if (count > 0) {
        this.badgeTarget.textContent = count > 99 ? '99+' : count
        this.badgeTarget.classList.remove('hidden')
        
        // Add pulse animation for urgent notifications
        if (count > this.previousCount) {
          this.badgeTarget.classList.add('animate-pulse')
          setTimeout(() => {
            this.badgeTarget.classList.remove('animate-pulse')
          }, 3000)
        }
      } else {
        this.badgeTarget.classList.add('hidden')
      }
      
      this.previousCount = count
    }
  }

  markAsRead(event) {
    const notificationId = event.currentTarget.dataset.notificationId
    
    if (notificationId) {
      // Send request to mark as read
      fetch(`/notifications/${notificationId}/mark_as_read`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })
      
      // Update UI immediately
      this.markNotificationAsRead(notificationId)
    }
  }

  markNotificationAsRead(notificationId) {
    const notificationElement = document.getElementById(`notification-item-${notificationId}`)
    if (notificationElement) {
      notificationElement.classList.remove('bg-blue-50')
      
      const unreadDot = notificationElement.querySelector('.bg-blue-600')
      if (unreadDot) {
        unreadDot.remove()
      }
      
      const title = notificationElement.querySelector('.font-semibold')
      if (title) {
        title.classList.remove('font-semibold')
        title.classList.add('font-medium')
      }
    }
  }

  markAllAsRead() {
    const notifications = this.listTarget.querySelectorAll('[id^="notification-item-"]')
    notifications.forEach(notification => {
      notification.classList.remove('bg-blue-50')
      
      const unreadDot = notification.querySelector('.bg-blue-600')
      if (unreadDot) {
        unreadDot.remove()
      }
      
      const title = notification.querySelector('.font-semibold')
      if (title) {
        title.classList.remove('font-semibold')
        title.classList.add('font-medium')
      }
    })
  }

  markAsViewed() {
    // Track when dropdown is opened
    if (this.hasUnreadNotifications()) {
      // Could send analytics event here
    }
  }

  hasUnreadNotifications() {
    return this.hasBadgeTarget && !this.badgeTarget.classList.contains('hidden')
  }

  playNotificationSound() {
    if (this.notificationSound && !document.hidden) {
      this.notificationSound.play().catch(e => {
        // Ignore errors if autoplay is blocked
        console.log('Could not play notification sound:', e)
      })
    }
  }

  showDesktopNotification(notification) {
    // Check if browser supports notifications
    if (!("Notification" in window)) {
      return
    }

    // Check permission
    if (Notification.permission === "granted") {
      this.createDesktopNotification(notification)
    } else if (Notification.permission !== "denied") {
      // Request permission
      Notification.requestPermission().then((permission) => {
        if (permission === "granted") {
          this.createDesktopNotification(notification)
        }
      })
    }
  }

  createDesktopNotification(notification) {
    const desktopNotification = new Notification(notification.title, {
      body: notification.message,
      icon: '/icon-192.png',
      badge: '/icon-72.png',
      tag: `notification-${notification.id}`,
      renotify: true,
      requireInteraction: notification.priority === 'urgent'
    })

    desktopNotification.onclick = () => {
      window.focus()
      window.location.href = notification.path
      desktopNotification.close()
    }

    // Auto close after 10 seconds for non-urgent
    if (notification.priority !== 'urgent') {
      setTimeout(() => {
        desktopNotification.close()
      }, 10000)
    }
  }
}