import { Application } from "@hotwired/stimulus"
import NotificationBellController from "../../../app/javascript/controllers/notification_bell_controller"
import { createConsumer } from "@rails/actioncable"

// Mock ActionCable
jest.mock("@rails/actioncable", () => ({
  createConsumer: jest.fn(() => ({
    subscriptions: {
      create: jest.fn((channel, handlers) => ({
        unsubscribe: jest.fn(),
        ...handlers
      }))
    }
  }))
}))

// Mock Audio
global.Audio = jest.fn(() => ({
  play: jest.fn().mockResolvedValue(undefined),
  volume: 0.3
}))

// Mock Notification API
global.Notification = {
  permission: "default",
  requestPermission: jest.fn().mockResolvedValue("granted")
}

describe("NotificationBellController", () => {
  let application
  let element
  let mockSubscription
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="notification-bell" 
           data-notification-bell-user-id-value="123"
           data-notification-bell-channel-value="NotificationChannel">
        <button>
          <span data-notification-bell-target="badge" class="hidden">0</span>
        </button>
        <div data-notification-bell-target="list">
          <div class="empty-state">No notifications</div>
        </div>
        <turbo-frame data-notification-bell-target="turboFrame"></turbo-frame>
      </div>
    `
    
    // Add CSRF token
    const csrfMeta = document.createElement('meta')
    csrfMeta.name = 'csrf-token'
    csrfMeta.content = 'test-csrf-token'
    document.head.appendChild(csrfMeta)
    
    application = Application.start()
    application.register("notification-bell", NotificationBellController)
    
    element = document.querySelector('[data-controller="notification-bell"]')
    
    // Get the mock subscription
    const consumer = createConsumer()
    mockSubscription = consumer.subscriptions.create()
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    document.head.innerHTML = ""
    jest.clearAllMocks()
  })
  
  describe("#connect", () => {
    it("sets up ActionCable subscription", () => {
      const consumer = createConsumer()
      expect(consumer.subscriptions.create).toHaveBeenCalledWith(
        {
          channel: "NotificationChannel",
          user_id: 123
        },
        expect.any(Object)
      )
    })
    
    it("creates notification sound", () => {
      expect(global.Audio).toHaveBeenCalledWith('/sounds/notification.mp3')
    })
    
    it("sets notification sound volume", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
      expect(controller.notificationSound.volume).toBe(0.3)
    })
  })
  
  describe("#disconnect", () => {
    it("unsubscribes from ActionCable channel", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
      controller.disconnect()
      
      expect(mockSubscription.unsubscribe).toHaveBeenCalled()
    })
  })
  
  describe("ActionCable callbacks", () => {
    it("logs connection status", () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation()
      
      mockSubscription.connected()
      expect(consoleSpy).toHaveBeenCalledWith("Connected to NotificationChannel")
      
      mockSubscription.disconnected()
      expect(consoleSpy).toHaveBeenCalledWith("Disconnected from NotificationChannel")
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#handleNotificationReceived", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    describe("new_notification action", () => {
      it("adds new notification to list", () => {
        const notification = {
          id: 1,
          title: "New Document",
          message: "A new document has been uploaded",
          notification_type: "document_shared",
          priority: "normal",
          created_at: new Date().toISOString(),
          path: "/documents/1"
        }
        
        mockSubscription.received({
          action: 'new_notification',
          notification: notification,
          unread_count: 1
        })
        
        const notificationElement = element.querySelector('#notification-item-1')
        expect(notificationElement).toBeTruthy()
        expect(notificationElement.textContent).toContain("New Document")
        expect(notificationElement.textContent).toContain("A new document has been uploaded")
      })
      
      it("removes empty state when adding first notification", () => {
        const emptyState = element.querySelector('.empty-state')
        expect(emptyState).toBeTruthy()
        
        mockSubscription.received({
          action: 'new_notification',
          notification: {
            id: 1,
            title: "Test",
            message: "Test message",
            created_at: new Date().toISOString(),
            path: "/test"
          },
          unread_count: 1
        })
        
        expect(element.querySelector('.empty-state')).toBeFalsy()
      })
      
      it("limits displayed notifications to 5", () => {
        // Add 6 notifications
        for (let i = 1; i <= 6; i++) {
          mockSubscription.received({
            action: 'new_notification',
            notification: {
              id: i,
              title: `Notification ${i}`,
              message: `Message ${i}`,
              created_at: new Date().toISOString(),
              path: `/test/${i}`
            },
            unread_count: i
          })
        }
        
        const notifications = element.querySelectorAll('[id^="notification-item-"]')
        expect(notifications.length).toBe(5)
        // First notification should be removed
        expect(element.querySelector('#notification-item-1')).toBeFalsy()
        // Last notification should be present
        expect(element.querySelector('#notification-item-6')).toBeTruthy()
      })
      
      it("updates badge count", () => {
        const badge = element.querySelector('[data-notification-bell-target="badge"]')
        
        mockSubscription.received({
          action: 'new_notification',
          notification: { id: 1, title: "Test", message: "Test", created_at: new Date().toISOString(), path: "/test" },
          unread_count: 5
        })
        
        expect(badge.textContent).toBe("5")
        expect(badge.classList.contains('hidden')).toBe(false)
      })
      
      it("plays notification sound", () => {
        mockSubscription.received({
          action: 'new_notification',
          notification: { id: 1, title: "Test", message: "Test", created_at: new Date().toISOString(), path: "/test" },
          unread_count: 1
        })
        
        expect(controller.notificationSound.play).toHaveBeenCalled()
      })
      
      it("shows desktop notification", () => {
        const createNotificationSpy = jest.spyOn(controller, 'showDesktopNotification')
        
        const notification = { id: 1, title: "Test", message: "Test", created_at: new Date().toISOString(), path: "/test" }
        mockSubscription.received({
          action: 'new_notification',
          notification: notification,
          unread_count: 1
        })
        
        expect(createNotificationSpy).toHaveBeenCalledWith(notification)
      })
    })
    
    describe("mark_as_read action", () => {
      beforeEach(() => {
        // Add a notification first
        mockSubscription.received({
          action: 'new_notification',
          notification: {
            id: 1,
            title: "Test",
            message: "Test message",
            created_at: new Date().toISOString(),
            path: "/test"
          },
          unread_count: 1
        })
      })
      
      it("marks notification as read", () => {
        mockSubscription.received({
          action: 'mark_as_read',
          notification_id: 1,
          unread_count: 0
        })
        
        const notificationElement = element.querySelector('#notification-item-1')
        expect(notificationElement.classList.contains('bg-blue-50')).toBe(false)
        expect(notificationElement.querySelector('.bg-blue-600')).toBeFalsy()
      })
      
      it("updates badge count", () => {
        const badge = element.querySelector('[data-notification-bell-target="badge"]')
        
        mockSubscription.received({
          action: 'mark_as_read',
          notification_id: 1,
          unread_count: 0
        })
        
        expect(badge.classList.contains('hidden')).toBe(true)
      })
    })
    
    describe("mark_all_as_read action", () => {
      beforeEach(() => {
        // Add multiple notifications
        for (let i = 1; i <= 3; i++) {
          mockSubscription.received({
            action: 'new_notification',
            notification: {
              id: i,
              title: `Notification ${i}`,
              message: `Message ${i}`,
              created_at: new Date().toISOString(),
              path: `/test/${i}`
            },
            unread_count: i
          })
        }
      })
      
      it("marks all notifications as read", () => {
        mockSubscription.received({
          action: 'mark_all_as_read'
        })
        
        const notifications = element.querySelectorAll('[id^="notification-item-"]')
        notifications.forEach(notification => {
          expect(notification.classList.contains('bg-blue-50')).toBe(false)
          expect(notification.querySelector('.bg-blue-600')).toBeFalsy()
        })
      })
      
      it("hides badge", () => {
        const badge = element.querySelector('[data-notification-bell-target="badge"]')
        
        mockSubscription.received({
          action: 'mark_all_as_read'
        })
        
        expect(badge.classList.contains('hidden')).toBe(true)
      })
    })
    
    describe("update_count action", () => {
      it("updates badge count only", () => {
        const badge = element.querySelector('[data-notification-bell-target="badge"]')
        
        mockSubscription.received({
          action: 'update_count',
          unread_count: 10
        })
        
        expect(badge.textContent).toBe("10")
        expect(badge.classList.contains('hidden')).toBe(false)
      })
    })
  })
  
  describe("#buildNotificationHtml", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    it("builds correct HTML structure", () => {
      const notification = {
        id: 1,
        title: "Test Notification",
        message: "This is a test message",
        notification_type: "validation_request",
        priority: "high",
        created_at: new Date().toISOString(),
        path: "/test/1"
      }
      
      const html = controller.buildNotificationHtml(notification)
      const div = document.createElement('div')
      div.innerHTML = html
      
      expect(div.querySelector('#notification-item-1')).toBeTruthy()
      expect(div.querySelector('a[href="/test/1"]')).toBeTruthy()
      expect(div.querySelector('a[data-notification-id="1"]')).toBeTruthy()
      expect(div.textContent).toContain("Test Notification")
      expect(div.textContent).toContain("This is a test message")
    })
  })
  
  describe("#getNotificationIcon", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    it("returns correct icon for validation_request", () => {
      const icon = controller.getNotificationIcon('validation_request')
      expect(icon).toContain('m-6 9l2 2 4-4')
    })
    
    it("returns correct icon for document_shared", () => {
      const icon = controller.getNotificationIcon('document_shared')
      expect(icon).toContain('M21 12a9 9 0 11-18 0')
    })
    
    it("returns correct icon for deadline_approaching", () => {
      const icon = controller.getNotificationIcon('deadline_approaching')
      expect(icon).toContain('M12 8v4l3 3m6-3a9')
    })
    
    it("returns default icon for unknown type", () => {
      const icon = controller.getNotificationIcon('unknown_type')
      expect(icon).toContain('M15 17h5l-1.405-1.405')
    })
  })
  
  describe("#getNotificationColor", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    it("returns red for urgent priority", () => {
      expect(controller.getNotificationColor('urgent')).toBe('red')
    })
    
    it("returns red for high priority", () => {
      expect(controller.getNotificationColor('high')).toBe('red')
    })
    
    it("returns yellow for normal priority", () => {
      expect(controller.getNotificationColor('normal')).toBe('yellow')
    })
    
    it("returns yellow for medium priority", () => {
      expect(controller.getNotificationColor('medium')).toBe('yellow')
    })
    
    it("returns green for low priority", () => {
      expect(controller.getNotificationColor('low')).toBe('green')
    })
    
    it("returns gray for unknown priority", () => {
      expect(controller.getNotificationColor('unknown')).toBe('gray')
    })
  })
  
  describe("#formatNotificationTime", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    it("formats time less than a minute ago", () => {
      const now = new Date()
      const result = controller.formatNotificationTime(now.toISOString())
      expect(result).toBe("À l'instant")
    })
    
    it("formats time in minutes", () => {
      const date = new Date(Date.now() - 5 * 60 * 1000) // 5 minutes ago
      const result = controller.formatNotificationTime(date.toISOString())
      expect(result).toBe("il y a 5 minutes")
    })
    
    it("formats time in hours", () => {
      const date = new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
      const result = controller.formatNotificationTime(date.toISOString())
      expect(result).toBe("il y a 2 heures")
    })
    
    it("formats older dates as date string", () => {
      const date = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) // 2 days ago
      const result = controller.formatNotificationTime(date.toISOString())
      expect(result).toMatch(/\d{2}\/\d{2}\/\d{4}/)
    })
  })
  
  describe("#updateBadge", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    it("shows badge with count when greater than 0", () => {
      const badge = element.querySelector('[data-notification-bell-target="badge"]')
      controller.updateBadge(5)
      
      expect(badge.textContent).toBe("5")
      expect(badge.classList.contains('hidden')).toBe(false)
    })
    
    it("shows 99+ for counts over 99", () => {
      const badge = element.querySelector('[data-notification-bell-target="badge"]')
      controller.updateBadge(150)
      
      expect(badge.textContent).toBe("99+")
    })
    
    it("hides badge when count is 0", () => {
      const badge = element.querySelector('[data-notification-bell-target="badge"]')
      controller.updateBadge(0)
      
      expect(badge.classList.contains('hidden')).toBe(true)
    })
    
    it("adds pulse animation for new notifications", () => {
      const badge = element.querySelector('[data-notification-bell-target="badge"]')
      controller.previousCount = 3
      controller.updateBadge(5)
      
      expect(badge.classList.contains('animate-pulse')).toBe(true)
    })
  })
  
  describe("#markAsRead", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
      global.fetch = jest.fn().mockResolvedValue({ ok: true })
      
      // Add a notification
      mockSubscription.received({
        action: 'new_notification',
        notification: {
          id: 1,
          title: "Test",
          message: "Test",
          created_at: new Date().toISOString(),
          path: "/test"
        },
        unread_count: 1
      })
    })
    
    afterEach(() => {
      delete global.fetch
    })
    
    it("sends POST request to mark as read", () => {
      const link = element.querySelector('a[data-notification-id="1"]')
      link.click()
      
      expect(global.fetch).toHaveBeenCalledWith(
        '/notifications/1/mark_as_read',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
            'X-CSRF-Token': 'test-csrf-token'
          })
        })
      )
    })
    
    it("updates UI immediately", () => {
      const link = element.querySelector('a[data-notification-id="1"]')
      const notificationElement = element.querySelector('#notification-item-1')
      
      link.click()
      
      expect(notificationElement.classList.contains('bg-blue-50')).toBe(false)
    })
  })
  
  describe("#playNotificationSound", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    it("plays sound when document is visible", () => {
      Object.defineProperty(document, 'hidden', {
        configurable: true,
        get: () => false
      })
      
      controller.playNotificationSound()
      
      expect(controller.notificationSound.play).toHaveBeenCalled()
    })
    
    it("does not play sound when document is hidden", () => {
      Object.defineProperty(document, 'hidden', {
        configurable: true,
        get: () => true
      })
      
      controller.playNotificationSound()
      
      expect(controller.notificationSound.play).not.toHaveBeenCalled()
    })
    
    it("handles play errors gracefully", () => {
      controller.notificationSound.play = jest.fn().mockRejectedValue(new Error('Autoplay blocked'))
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation()
      
      controller.playNotificationSound()
      
      // Wait for promise to reject
      setTimeout(() => {
        expect(consoleSpy).toHaveBeenCalledWith('Could not play notification sound:', expect.any(Error))
        consoleSpy.mockRestore()
      }, 0)
    })
  })
  
  describe("#showDesktopNotification", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    it("creates desktop notification when permission granted", () => {
      global.Notification.permission = "granted"
      const NotificationConstructor = jest.fn()
      global.Notification = NotificationConstructor
      global.Notification.permission = "granted"
      
      const notification = {
        id: 1,
        title: "Test Title",
        message: "Test Message",
        priority: "normal",
        path: "/test"
      }
      
      controller.showDesktopNotification(notification)
      
      expect(NotificationConstructor).toHaveBeenCalledWith(
        "Test Title",
        expect.objectContaining({
          body: "Test Message",
          icon: '/icon-192.png',
          badge: '/icon-72.png',
          tag: 'notification-1',
          renotify: true,
          requireInteraction: false
        })
      )
    })
    
    it("requests permission when not granted", () => {
      global.Notification.permission = "default"
      global.Notification.requestPermission = jest.fn().mockResolvedValue("granted")
      
      const notification = {
        id: 1,
        title: "Test",
        message: "Test",
        priority: "normal",
        path: "/test"
      }
      
      controller.showDesktopNotification(notification)
      
      expect(global.Notification.requestPermission).toHaveBeenCalled()
    })
    
    it("does not show notification when permission denied", () => {
      global.Notification.permission = "denied"
      const NotificationConstructor = jest.fn()
      global.Notification = NotificationConstructor
      global.Notification.permission = "denied"
      
      const notification = {
        id: 1,
        title: "Test",
        message: "Test",
        priority: "normal",
        path: "/test"
      }
      
      controller.showDesktopNotification(notification)
      
      expect(NotificationConstructor).not.toHaveBeenCalled()
    })
    
    it("sets requireInteraction for urgent notifications", () => {
      global.Notification.permission = "granted"
      const NotificationConstructor = jest.fn()
      global.Notification = NotificationConstructor
      global.Notification.permission = "granted"
      
      const notification = {
        id: 1,
        title: "Urgent",
        message: "Urgent message",
        priority: "urgent",
        path: "/test"
      }
      
      controller.showDesktopNotification(notification)
      
      expect(NotificationConstructor).toHaveBeenCalledWith(
        "Urgent",
        expect.objectContaining({
          requireInteraction: true
        })
      )
    })
    
    it("handles missing Notification API", () => {
      const originalNotification = global.Notification
      delete global.Notification
      
      const notification = {
        id: 1,
        title: "Test",
        message: "Test",
        priority: "normal",
        path: "/test"
      }
      
      // Should not throw
      expect(() => controller.showDesktopNotification(notification)).not.toThrow()
      
      global.Notification = originalNotification
    })
  })
  
  describe("#hasUnreadNotifications", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "notification-bell")
    })
    
    it("returns true when badge is visible", () => {
      const badge = element.querySelector('[data-notification-bell-target="badge"]')
      badge.classList.remove('hidden')
      
      expect(controller.hasUnreadNotifications()).toBe(true)
    })
    
    it("returns false when badge is hidden", () => {
      const badge = element.querySelector('[data-notification-bell-target="badge"]')
      badge.classList.add('hidden')
      
      expect(controller.hasUnreadNotifications()).toBe(false)
    })
  })
})