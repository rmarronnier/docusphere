import '../setup.js'
import { Application } from "@hotwired/stimulus"
import BulkActionsController from "../../../app/javascript/controllers/bulk_actions_controller"

describe("BulkActionsController", () => {
  let application
  let element
  
  beforeEach(() => {
    // Add CSRF meta tag
    document.head.innerHTML = `
      <meta name="csrf-token" content="test-token-123">
    `
    
    document.body.innerHTML = `
      <div data-controller="bulk-actions"
           data-bulk-actions-notifications-value='["1", "2", "3"]'>
        
        <!-- Bulk actions toolbar -->
        <div data-bulk-actions-target="toolbar" style="display: none;">
          <span data-bulk-actions-target="count">0</span> selected
          <button data-bulk-actions-target="markReadButton" 
                  data-action="click->bulk-actions#markAsRead"
                  disabled>
            Mark as Read
          </button>
          <button data-bulk-actions-target="deleteButton"
                  data-action="click->bulk-actions#delete"
                  disabled>
            Delete
          </button>
        </div>
        
        <!-- Select all checkbox -->
        <input type="checkbox" 
               data-bulk-actions-target="selectAll"
               data-action="change->bulk-actions#toggleAll">
        
        <!-- Individual notifications -->
        <div data-notification-id="1" class="notification notification--unread">
          <input type="checkbox" 
                 value="1" 
                 data-bulk-actions-target="checkbox"
                 data-action="change->bulk-actions#toggleNotification">
          <div data-notification-target="markReadButton">Mark Read</div>
          <div data-notification-target="unreadIndicator">•</div>
        </div>
        
        <div data-notification-id="2" class="notification notification--unread">
          <input type="checkbox" 
                 value="2" 
                 data-bulk-actions-target="checkbox"
                 data-action="change->bulk-actions#toggleNotification">
          <div data-notification-target="markReadButton">Mark Read</div>
          <div data-notification-target="unreadIndicator">•</div>
        </div>
        
        <div data-notification-id="3" class="notification notification--read">
          <input type="checkbox" 
                 value="3" 
                 data-bulk-actions-target="checkbox"
                 data-action="change->bulk-actions#toggleNotification">
        </div>
      </div>
    `
    
    // Reset fetch mock
    fetch.mock.mockClear()
    
    application = Application.start()
    application.register("bulk-actions", BulkActionsController)
    
    // Mock notification controller
    const MockNotificationController = class {
      constructor() {
        this.readValue = false
      }
    }
    application.register("notification", MockNotificationController)
    
    element = document.querySelector('[data-controller="bulk-actions"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    document.head.innerHTML = ""
    window.confirm = undefined
    jest.clearAllTimers()
  })
  
  describe("connect", () => {
    it("initializes with empty selection and hidden toolbar", () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation()
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      
      controller.connect()
      
      expect(consoleSpy).toHaveBeenCalledWith("Bulk actions controller connected")
      expect(controller.selectedIds.size).toBe(0)
      expect(controller.toolbarTarget.style.display).toBe('none')
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#toggleNotification", () => {
    it("adds notification to selection when checked", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      const checkbox = element.querySelector('input[value="1"]')
      
      checkbox.checked = true
      const event = new Event('change')
      Object.defineProperty(event, 'currentTarget', { value: checkbox, enumerable: true })
      
      controller.toggleNotification(event)
      
      expect(controller.selectedIds.has('1')).toBe(true)
      expect(controller.selectedIds.size).toBe(1)
      expect(controller.toolbarTarget.style.display).toBe('flex')
      expect(controller.countTarget.textContent).toBe('1')
    })
    
    it("removes notification from selection when unchecked", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      
      const checkbox = element.querySelector('input[value="1"]')
      checkbox.checked = false
      const event = new Event('change')
      Object.defineProperty(event, 'currentTarget', { value: checkbox, enumerable: true })
      
      controller.toggleNotification(event)
      
      expect(controller.selectedIds.has('1')).toBe(false)
      expect(controller.selectedIds.size).toBe(0)
      expect(controller.toolbarTarget.style.display).toBe('none')
    })
  })
  
  describe("#toggleAll", () => {
    it("selects all notifications when checked", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      const selectAll = element.querySelector('[data-bulk-actions-target="selectAll"]')
      
      selectAll.checked = true
      const event = new Event('change')
      Object.defineProperty(event, 'currentTarget', { value: selectAll, enumerable: true })
      
      controller.toggleAll(event)
      
      const checkboxes = element.querySelectorAll('[data-bulk-actions-target="checkbox"]')
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(true)
      })
      
      expect(controller.selectedIds.size).toBe(3)
      expect(controller.toolbarTarget.style.display).toBe('flex')
      expect(controller.countTarget.textContent).toBe('3')
    })
    
    it("deselects all notifications when unchecked", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      controller.selectedIds.add('2')
      
      const selectAll = element.querySelector('[data-bulk-actions-target="selectAll"]')
      selectAll.checked = false
      const event = new Event('change')
      Object.defineProperty(event, 'currentTarget', { value: selectAll, enumerable: true })
      
      controller.toggleAll(event)
      
      const checkboxes = element.querySelectorAll('[data-bulk-actions-target="checkbox"]')
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(false)
      })
      
      expect(controller.selectedIds.size).toBe(0)
      expect(controller.toolbarTarget.style.display).toBe('none')
    })
  })
  
  describe("#markAsRead", () => {
    it("marks selected notifications as read successfully", async () => {
      fetch.mock.mockResolvedValue({
        ok: true,
        json: async () => ({ count: 2 })
      })
      
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      controller.selectedIds.add('2')
      
      const toastSpy = jest.spyOn(controller, 'showToast')
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.markAsRead(event)
      
      expect(fetch.mock.calls.length).toBe(1)
      expect(fetch.mock.calls[0][0]).toBe('/notifications/bulk_mark_as_read')
      expect(fetch.mock.calls[0][1].method).toBe('PATCH')
      expect(JSON.parse(fetch.mock.calls[0][1].body)).toEqual({
        notification_ids: ['1', '2']
      })
      
      expect(toastSpy).toHaveBeenCalledWith('2 notifications marquées comme lues', 'success')
      expect(controller.selectedIds.size).toBe(0)
    })
    
    it("shows warning when no notifications selected", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      const toastSpy = jest.spyOn(controller, 'showToast')
      
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.markAsRead(event)
      
      expect(fetch.mock.calls.length).toBe(0)
      expect(toastSpy).toHaveBeenCalledWith('Aucune notification sélectionnée', 'warning')
    })
    
    it("handles errors when marking as read", async () => {
      fetch.mock.mockResolvedValue({
        ok: false
      })
      
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      
      const toastSpy = jest.spyOn(controller, 'showToast')
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.markAsRead(event)
      
      expect(consoleSpy).toHaveBeenCalled()
      expect(toastSpy).toHaveBeenCalledWith('Erreur lors du marquage des notifications', 'error')
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#delete", () => {
    it("deletes selected notifications after confirmation", async () => {
      window.confirm = jest.fn().mockReturnValue(true)
      fetch.mock.mockResolvedValue({
        ok: true,
        json: async () => ({ count: 2 })
      })
      
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      controller.selectedIds.add('2')
      
      const toastSpy = jest.spyOn(controller, 'showToast')
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.delete(event)
      
      expect(window.confirm).toHaveBeenCalledWith('Êtes-vous sûr de vouloir supprimer 2 notifications ?')
      expect(fetch.mock.calls.length).toBe(1)
      expect(fetch.mock.calls[0][0]).toBe('/notifications/bulk_destroy')
      expect(fetch.mock.calls[0][1].method).toBe('DELETE')
      
      expect(toastSpy).toHaveBeenCalledWith('2 notifications supprimées', 'success')
      expect(controller.selectedIds.size).toBe(0)
    })
    
    it("cancels deletion when user declines", async () => {
      window.confirm = jest.fn().mockReturnValue(false)
      
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.delete(event)
      
      expect(fetch.mock.calls.length).toBe(0)
      expect(controller.selectedIds.size).toBe(1)
    })
    
    it("shows warning when no notifications selected", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      const toastSpy = jest.spyOn(controller, 'showToast')
      
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.delete(event)
      
      expect(toastSpy).toHaveBeenCalledWith('Aucune notification sélectionnée', 'warning')
      expect(window.confirm).toBeUndefined()
    })
    
    it("handles deletion errors", async () => {
      window.confirm = jest.fn().mockReturnValue(true)
      fetch.mock.mockRejectedValue(new Error('Network error'))
      
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      
      const toastSpy = jest.spyOn(controller, 'showToast')
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      await controller.delete(event)
      
      expect(consoleSpy).toHaveBeenCalled()
      expect(toastSpy).toHaveBeenCalledWith('Erreur lors de la suppression des notifications', 'error')
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#updateSelectAllState", () => {
    it("checks select all when all items selected", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      controller.selectedIds.add('2')
      controller.selectedIds.add('3')
      
      controller.updateSelectAllState()
      
      expect(controller.selectAllTarget.checked).toBe(true)
      expect(controller.selectAllTarget.indeterminate).toBe(false)
    })
    
    it("sets indeterminate when some items selected", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      controller.selectedIds.add('2')
      
      controller.updateSelectAllState()
      
      expect(controller.selectAllTarget.checked).toBe(false)
      expect(controller.selectAllTarget.indeterminate).toBe(true)
    })
    
    it("unchecks when no items selected", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      
      controller.updateSelectAllState()
      
      expect(controller.selectAllTarget.checked).toBe(false)
      expect(controller.selectAllTarget.indeterminate).toBe(false)
    })
  })
  
  describe("#updateButtonStates", () => {
    it("enables buttons when items selected", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      
      controller.updateButtonStates()
      
      expect(controller.markReadButtonTarget.disabled).toBe(false)
      expect(controller.deleteButtonTarget.disabled).toBe(false)
    })
    
    it("disables buttons when no items selected", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      
      controller.updateButtonStates()
      
      expect(controller.markReadButtonTarget.disabled).toBe(true)
      expect(controller.deleteButtonTarget.disabled).toBe(true)
    })
  })
  
  describe("#clearSelection", () => {
    it("clears all selections and updates UI", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      controller.selectedIds.add('2')
      
      // Check some boxes
      const checkboxes = element.querySelectorAll('[data-bulk-actions-target="checkbox"]')
      checkboxes[0].checked = true
      checkboxes[1].checked = true
      
      controller.clearSelection()
      
      expect(controller.selectedIds.size).toBe(0)
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(false)
      })
      expect(controller.toolbarTarget.style.display).toBe('none')
    })
  })
  
  describe("#updateNotificationsAsRead", () => {
    it("updates notification UI elements", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      controller.selectedIds.add('2')
      
      controller.updateNotificationsAsRead()
      
      controller.selectedIds.forEach(id => {
        const notification = document.querySelector(`[data-notification-id="${id}"]`)
        expect(notification.classList.contains('notification--read')).toBe(true)
        expect(notification.classList.contains('notification--unread')).toBe(false)
        
        const markReadButton = notification.querySelector('[data-notification-target="markReadButton"]')
        if (markReadButton) {
          expect(markReadButton.style.display).toBe('none')
        }
        
        const unreadIndicator = notification.querySelector('[data-notification-target="unreadIndicator"]')
        if (unreadIndicator) {
          expect(unreadIndicator.style.display).toBe('none')
        }
      })
    })
    
    it("updates notification controller if exists", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      
      // Add notification controller to element
      const notification = document.querySelector('[data-notification-id="1"]')
      notification.setAttribute('data-controller', 'notification')
      
      const notificationController = application.getControllerForElementAndIdentifier(notification, "notification")
      
      controller.updateNotificationsAsRead()
      
      expect(notificationController.readValue).toBe(true)
    })
  })
  
  describe("#removeSelectedNotifications", () => {
    it("removes selected notification elements from DOM", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      controller.selectedIds.add('1')
      controller.selectedIds.add('2')
      
      controller.removeSelectedNotifications()
      
      expect(document.querySelector('[data-notification-id="1"]')).toBeFalsy()
      expect(document.querySelector('[data-notification-id="2"]')).toBeFalsy()
      expect(document.querySelector('[data-notification-id="3"]')).toBeTruthy()
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
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      
      controller.showToast('Test message', 'success')
      
      const toast = document.querySelector('.bulk-action-toast--success')
      expect(toast).toBeTruthy()
      expect(toast.textContent).toBe('Test message')
      expect(toast.style.backgroundColor).toBe('#10B981')
    })
    
    it("animates toast in and out", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      
      controller.showToast('Test message', 'info')
      
      const toast = document.querySelector('.bulk-action-toast--info')
      
      // Should start off-screen
      expect(toast.style.transform).toBe('translateX(100%)')
      
      // Animate in after 10ms
      jest.advanceTimersByTime(10)
      expect(toast.style.transform).toBe('translateX(0)')
      
      // Animate out after 3 seconds
      jest.advanceTimersByTime(3000)
      expect(toast.style.transform).toBe('translateX(100%)')
      
      // Remove from DOM after animation
      jest.advanceTimersByTime(300)
      expect(document.querySelector('.bulk-action-toast--info')).toBeFalsy()
    })
  })
  
  describe("#getCsrfToken", () => {
    it("returns CSRF token from meta tag", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      
      expect(controller.getCsrfToken()).toBe('test-token-123')
    })
    
    it("returns empty string when no token found", () => {
      document.head.innerHTML = ''
      const controller = application.getControllerForElementAndIdentifier(element, "bulk-actions")
      
      expect(controller.getCsrfToken()).toBe('')
    })
  })
})