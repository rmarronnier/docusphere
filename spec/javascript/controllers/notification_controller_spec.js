import '../setup.js'
import { Application } from "@hotwired/stimulus"
import NotificationController from "../../../app/javascript/controllers/notification_controller"

describe("NotificationController", () => {
  let application
  let element
  
  beforeEach(() => {
    // Add CSRF meta tag
    document.head.innerHTML = `
      <meta name="csrf-token" content="test-token-123">
    `
    
    document.body.innerHTML = `
      <div data-controller="notification"
           data-notification-read-value="false"
           data-notification-urgent-value="false"
           data-notification-id-value="123"
           data-notification-mark-read-url-value="/notifications/123/mark_as_read"
           data-notification-delete-url-value="/notifications/123"
           class="notification notification--unread">
        <div data-notification-target="unreadIndicator" class="unread-dot"></div>
        <div class="notification-content">
          <h4>New document uploaded</h4>
          <p>A new document has been uploaded to your space</p>
        </div>
        <div class="notification-actions">
          <button data-notification-target="markReadButton" 
                  data-action="click->notification#markAsRead">
            Mark as read
          </button>
          <button data-notification-target="deleteButton"
                  data-action="click->notification#delete">
            Delete
          </button>
        </div>
      </div>
      
      <div class="notification-badge">5</div>
    `
    
    // Reset fetch mock
    fetch.mock.mockClear()
    
    application = Application.start()
    application.register("notification", NotificationController)
    
    element = document.querySelector('[data-controller="notification"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    document.head.innerHTML = ""
    jest.clearAllTimers()
  })
  
  describe("connect", () => {
    it("logs connection and updates read state", () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation()
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      
      controller.connect()
      
      expect(consoleSpy).toHaveBeenCalledWith("Notification controller connected", element)
      expect(element.classList.contains('notification--unread')).toBe(true)
      expect(element.dataset.notificationRead).toBe('false')
      
      consoleSpy.mockRestore()
    })
    
    it("sets up auto-refresh on notification pages", () => {
      // Mock window.location
      delete window.location
      window.location = { pathname: '/notifications' }
      
      jest.useFakeTimers()
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      
      controller.connect()
      
      expect(controller.refreshInterval).toBeDefined()
      
      jest.useRealTimers()
      window.location = { pathname: '/' }
    })
  })
  
  describe("#markAsRead", () => {
    it("marks notification as read successfully", async () => {
      fetch.mock.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true })
      })
      
      const button = element.querySelector('[data-notification-target="markReadButton"]')
      const event = new Event('click')
      
      await button.dispatchEvent(event)
      
      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(fetch.mock.calls.length).toBe(1)
      expect(fetch.mock.calls[0][0]).toBe('/notifications/123/mark_as_read')
      expect(fetch.mock.calls[0][1]).toEqual({
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': 'test-token-123',
          'Accept': 'application/json'
        }
      })
      
      expect(element.classList.contains('notification--read')).toBe(true)
      expect(element.classList.contains('notification--unread')).toBe(false)
    })
    
    it("handles errors when marking as read", async () => {
      fetch.mock.mockRejectedValue(new Error('Network error'))
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()
      
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.markAsRead(event)
      
      expect(consoleSpy).toHaveBeenCalledWith('Error marking notification as read:', expect.any(Error))
      expect(element.classList.contains('notification--unread')).toBe(true)
      
      consoleSpy.mockRestore()
    })
    
    it("updates unread count when marking as read", async () => {
      fetch.mock.mockResolvedValue({ ok: true })
      const badge = document.querySelector('.notification-badge')
      
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.markAsRead(event)
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(badge.textContent).toBe('4')
    })
  })
  
  describe("#delete", () => {
    it("deletes notification after confirmation", async () => {
      window.confirm = jest.fn().mockReturnValue(true)
      fetch.mock.mockResolvedValue({ ok: true })
      
      const button = element.querySelector('[data-notification-target="deleteButton"]')
      
      await button.click()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(window.confirm).toHaveBeenCalledWith('Êtes-vous sûr de vouloir supprimer cette notification ?')
      expect(fetch.mock.calls.length).toBe(1)
      expect(fetch.mock.calls[0][0]).toBe('/notifications/123')
      expect(fetch.mock.calls[0][1].method).toBe('DELETE')
      
      expect(document.contains(element)).toBe(false)
    })
    
    it("cancels deletion when user declines", async () => {
      window.confirm = jest.fn().mockReturnValue(false)
      
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.delete(event)
      
      expect(fetch.mock.calls.length).toBe(0)
      expect(document.contains(element)).toBe(true)
    })
    
    it("handles deletion errors", async () => {
      window.confirm = jest.fn().mockReturnValue(true)
      fetch.mock.mockResolvedValue({ ok: false })
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()
      
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.delete(event)
      
      expect(consoleSpy).toHaveBeenCalled()
      expect(document.contains(element)).toBe(true)
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#navigate", () => {
    it("marks as read when clicking notification content", async () => {
      fetch.mock.mockResolvedValue({ ok: true })
      
      const content = element.querySelector('.notification-content')
      const event = new Event('click', { bubbles: true })
      
      content.dispatchEvent(event)
      
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(fetch.mock.calls.length).toBe(1)
      expect(fetch.mock.calls[0][0]).toContain('mark_as_read')
    })
    
    it("does not navigate when clicking action buttons", () => {
      const markReadButton = element.querySelector('[data-notification-target="markReadButton"]')
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      
      const spy = jest.spyOn(controller, 'markAsRead')
      
      const event = new Event('click', { bubbles: true })
      Object.defineProperty(event, 'target', { value: markReadButton, enumerable: true })
      
      controller.navigate(event)
      
      expect(spy).not.toHaveBeenCalled()
    })
    
    it("does not mark as read if already read", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      controller.readValue = true
      
      const spy = jest.spyOn(controller, 'markAsRead')
      const event = new Event('click')
      
      controller.navigate(event)
      
      expect(spy).not.toHaveBeenCalled()
    })
  })
  
  describe("#updateReadState", () => {
    it("updates visual state for unread notification", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      controller.readValue = false
      
      controller.updateReadState()
      
      expect(element.dataset.notificationRead).toBe('false')
      expect(element.classList.contains('notification--unread')).toBe(true)
      expect(element.classList.contains('notification--read')).toBe(false)
      
      const indicator = element.querySelector('[data-notification-target="unreadIndicator"]')
      expect(indicator.style.display).toBe('block')
    })
    
    it("updates visual state for read notification", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      controller.readValue = true
      
      controller.updateReadState()
      
      expect(element.dataset.notificationRead).toBe('true')
      expect(element.classList.contains('notification--read')).toBe(true)
      expect(element.classList.contains('notification--unread')).toBe(false)
      
      const indicator = element.querySelector('[data-notification-target="unreadIndicator"]')
      expect(indicator.style.display).toBe('none')
    })
  })
  
  describe("#showToast", () => {
    beforeEach(() => {
      jest.useFakeTimers()
    })
    
    afterEach(() => {
      jest.useRealTimers()
    })
    
    it("creates and displays toast notification", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      
      controller.showToast('Test message', 'success')
      
      const toast = document.querySelector('.notification-toast--success')
      expect(toast).toBeTruthy()
      expect(toast.textContent).toBe('Test message')
      expect(toast.style.backgroundColor).toBe('#10B981')
    })
    
    it("removes toast after timeout", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      
      controller.showToast('Test message', 'error')
      
      const toast = document.querySelector('.notification-toast--error')
      expect(toast).toBeTruthy()
      
      // Fast-forward time
      jest.advanceTimersByTime(3500)
      
      expect(document.querySelector('.notification-toast--error')).toBeFalsy()
    })
  })
  
  describe("#updateUnreadCount", () => {
    it("decrements badge count", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      const badge = document.querySelector('.notification-badge')
      
      controller.updateUnreadCount(-1)
      
      expect(badge.textContent).toBe('4')
      expect(badge.style.display).toBe('flex')
    })
    
    it("hides badge when count reaches zero", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      const badge = document.querySelector('.notification-badge')
      badge.textContent = '1'
      
      controller.updateUnreadCount(-1)
      
      expect(badge.textContent).toBe('0')
      expect(badge.style.display).toBe('none')
    })
    
    it("shows 9+ for counts above 9", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      const badge = document.querySelector('.notification-badge')
      badge.textContent = '9'
      
      controller.updateUnreadCount(1)
      
      expect(badge.textContent).toBe('9+')
    })
  })
  
  describe("disconnect", () => {
    it("clears refresh interval", () => {
      jest.useFakeTimers()
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      controller.refreshInterval = setInterval(() => {}, 1000)
      
      const clearSpy = jest.spyOn(global, 'clearInterval')
      
      controller.disconnect()
      
      expect(clearSpy).toHaveBeenCalledWith(controller.refreshInterval)
      
      jest.useRealTimers()
    })
  })
  
  describe("URL building", () => {
    it("builds correct mark read URL", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      controller.idValue = 456
      
      expect(controller.buildMarkReadUrl()).toBe('/notifications/456/mark_as_read')
    })
    
    it("builds correct delete URL", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      controller.idValue = 789
      
      expect(controller.buildDeleteUrl()).toBe('/notifications/789')
    })
  })
  
  describe("value changes", () => {
    it("updates state when read value changes", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "notification")
      const spy = jest.spyOn(controller, 'updateReadState')
      
      controller.readValue = true
      controller.readValueChanged()
      
      expect(spy).toHaveBeenCalled()
    })
  })
})