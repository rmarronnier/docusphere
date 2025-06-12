import '../setup.js'
import { Application } from "@hotwired/stimulus"
import PreferencesController from "../../../app/javascript/controllers/preferences_controller"

describe("PreferencesController", () => {
  let application
  let element
  
  beforeEach(() => {
    // Add CSRF meta tag
    document.head.innerHTML = `
      <meta name="csrf-token" content="test-token-123">
    `
    
    document.body.innerHTML = `
      <div data-controller="preferences">
        <div data-preferences-target="modal" id="preview-modal" class="hidden">
          <div id="preview-content" data-preferences-target="previewContent"></div>
        </div>
        
        <div class="notification-preferences">
          <!-- Quick actions -->
          <button data-action="click->preferences#enableAll">Enable All</button>
          <button data-action="click->preferences#essentialOnly">Essential Only</button>
          <button data-action="click->preferences#disableAll">Disable All</button>
          
          <!-- Category toggles -->
          <button class="category-toggle" data-category="documents" data-action="click->preferences#toggleCategory">
            <span class="toggle-thumb translate-x-0"></span>
          </button>
          
          <button class="category-toggle category-enabled bg-blue-600" data-category="validations" data-action="click->preferences#toggleCategory">
            <span class="toggle-thumb translate-x-5"></span>
          </button>
          
          <!-- Notification types -->
          <div data-notification-type="document_upload" data-category="documents">
            <span class="bg-red-100">Urgent</span>
            <input type="checkbox" class="preference-enabled" checked>
            <select name="preferences[document_upload][delivery_method]">
              <option value="disabled">Disabled</option>
              <option value="in_app" selected>In App</option>
              <option value="email">Email</option>
              <option value="both">Both</option>
            </select>
            <select name="preferences[document_upload][frequency]">
              <option value="disabled_frequency">Disabled</option>
              <option value="immediate" selected>Immediate</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
            </select>
            <button data-notification-type="document_upload" data-action="click->preferences#showPreview">Preview</button>
          </div>
          
          <div data-notification-type="document_share" data-category="documents">
            <input type="checkbox" class="preference-enabled">
            <select name="preferences[document_share][delivery_method]">
              <option value="disabled" selected>Disabled</option>
              <option value="in_app">In App</option>
              <option value="email">Email</option>
              <option value="both">Both</option>
            </select>
            <select name="preferences[document_share][frequency]">
              <option value="disabled_frequency" selected>Disabled</option>
              <option value="immediate">Immediate</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
            </select>
          </div>
          
          <div data-notification-type="validation_request" data-category="validations">
            <span class="bg-red-100">Urgent</span>
            <input type="checkbox" class="preference-enabled" checked>
            <select name="preferences[validation_request][delivery_method]">
              <option value="disabled">Disabled</option>
              <option value="in_app">In App</option>
              <option value="email" selected>Email</option>
              <option value="both">Both</option>
            </select>
            <select name="preferences[validation_request][frequency]">
              <option value="disabled_frequency">Disabled</option>
              <option value="immediate" selected>Immediate</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
            </select>
          </div>
          
          <form>
            <!-- Form fields would be here -->
          </form>
        </div>
      </div>
    `
    
    // Reset fetch mock
    fetch.mock.mockClear()
    
    application = Application.start()
    application.register("preferences", PreferencesController)
    
    element = document.querySelector('[data-controller="preferences"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    document.head.innerHTML = ""
    jest.clearAllTimers()
  })
  
  describe("connect", () => {
    it("logs connection and updates category toggles", () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation()
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      controller.connect()
      
      expect(consoleSpy).toHaveBeenCalledWith("Preferences controller connected")
      
      // Check that category toggles are updated
      const documentsToggle = element.querySelector('[data-category="documents"]')
      expect(documentsToggle.classList.contains('category-enabled')).toBe(true)
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#enableAll", () => {
    it("enables all preferences and shows success toast", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toastSpy = jest.spyOn(controller, 'showToast')
      
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      controller.enableAll(event)
      
      // Check all checkboxes are checked
      const checkboxes = element.querySelectorAll('.preference-enabled')
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(true)
      })
      
      // Check all delivery methods are set to 'both'
      const deliverySelects = element.querySelectorAll('select[name*="[delivery_method]"]')
      deliverySelects.forEach(select => {
        expect(select.value).toBe('both')
      })
      
      // Check all frequencies are set to 'immediate'
      const frequencySelects = element.querySelectorAll('select[name*="[frequency]"]')
      frequencySelects.forEach(select => {
        expect(select.value).toBe('immediate')
      })
      
      expect(toastSpy).toHaveBeenCalledWith('Toutes les notifications ont été activées', 'success')
      expect(event.preventDefault).toHaveBeenCalled()
    })
  })
  
  describe("#essentialOnly", () => {
    it("enables only urgent notifications", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toastSpy = jest.spyOn(controller, 'showToast')
      
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      controller.essentialOnly(event)
      
      // Check urgent notifications are enabled
      const urgentElements = element.querySelectorAll('[data-notification-type]')
      urgentElements.forEach(el => {
        const hasUrgentBadge = el.querySelector('.bg-red-100')
        const checkbox = el.querySelector('.preference-enabled')
        const deliverySelect = el.querySelector('select[name*="[delivery_method]"]')
        
        if (hasUrgentBadge) {
          expect(checkbox.checked).toBe(true)
          expect(deliverySelect.value).toBe('both')
        } else {
          expect(checkbox.checked).toBe(false)
          expect(deliverySelect.value).toBe('disabled')
        }
      })
      
      expect(toastSpy).toHaveBeenCalledWith('Seules les notifications essentielles sont activées', 'info')
    })
  })
  
  describe("#disableAll", () => {
    it("disables all preferences and shows warning toast", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toastSpy = jest.spyOn(controller, 'showToast')
      
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      controller.disableAll(event)
      
      // Check all checkboxes are unchecked
      const checkboxes = element.querySelectorAll('.preference-enabled')
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(false)
      })
      
      // Check all delivery methods are set to 'disabled'
      const deliverySelects = element.querySelectorAll('select[name*="[delivery_method]"]')
      deliverySelects.forEach(select => {
        expect(select.value).toBe('disabled')
      })
      
      expect(toastSpy).toHaveBeenCalledWith('Toutes les notifications ont été désactivées', 'warning')
    })
  })
  
  describe("#toggleCategory", () => {
    it("toggles category on when disabled", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toastSpy = jest.spyOn(controller, 'showToast')
      
      const button = element.querySelector('[data-category="documents"]')
      const event = new Event('click')
      Object.defineProperty(event, 'currentTarget', { value: button, enumerable: true })
      
      controller.toggleCategory(event)
      
      // Check that documents category is enabled
      const documentsElements = element.querySelectorAll('[data-category="documents"] .preference-enabled')
      documentsElements.forEach(checkbox => {
        expect(checkbox.checked).toBe(true)
      })
      
      expect(button.classList.contains('category-enabled')).toBe(true)
      expect(toastSpy).toHaveBeenCalled()
    })
    
    it("toggles category off when enabled", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      const button = element.querySelector('[data-category="validations"]')
      const event = new Event('click')
      Object.defineProperty(event, 'currentTarget', { value: button, enumerable: true })
      
      controller.toggleCategory(event)
      
      // Check that validations category is disabled
      const validationElements = element.querySelectorAll('[data-category="validations"] .preference-enabled')
      validationElements.forEach(checkbox => {
        expect(checkbox.checked).toBe(false)
      })
      
      expect(button.classList.contains('category-enabled')).toBe(false)
    })
  })
  
  describe("#updatePreference", () => {
    it("updates category toggle when individual preference changes", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const updateSpy = jest.spyOn(controller, 'updateCategoryToggleForCategory')
      
      const checkbox = element.querySelector('[data-category="documents"] .preference-enabled')
      const event = new Event('change')
      Object.defineProperty(event, 'currentTarget', { 
        value: checkbox.parentElement, 
        enumerable: true 
      })
      
      controller.updatePreference(event)
      
      expect(updateSpy).toHaveBeenCalledWith('documents')
    })
    
    it("calls autoSave if enabled", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      jest.spyOn(controller, 'shouldAutoSave').mockReturnValue(true)
      const autoSaveSpy = jest.spyOn(controller, 'autoSave')
      
      const checkbox = element.querySelector('[data-category="documents"] .preference-enabled')
      const event = new Event('change')
      Object.defineProperty(event, 'currentTarget', { 
        value: checkbox.parentElement, 
        enumerable: true 
      })
      
      controller.updatePreference(event)
      
      expect(autoSaveSpy).toHaveBeenCalled()
    })
  })
  
  describe("#showPreview", () => {
    it("fetches and displays preview successfully", async () => {
      const previewHTML = '<div>Preview content</div>'
      fetch.mock.mockResolvedValue({
        ok: true,
        text: async () => previewHTML
      })
      
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const showModalSpy = jest.spyOn(controller, 'showPreviewModal')
      
      const button = element.querySelector('[data-notification-type="document_upload"]')
      const event = new Event('click')
      event.preventDefault = jest.fn()
      Object.defineProperty(event, 'currentTarget', { value: button, enumerable: true })
      
      await controller.showPreview(event)
      
      expect(fetch.mock.calls.length).toBe(1)
      expect(fetch.mock.calls[0][0]).toBe('/notification_preferences/preview?notification_type=document_upload')
      expect(showModalSpy).toHaveBeenCalledWith(previewHTML)
    })
    
    it("handles preview fetch errors", async () => {
      fetch.mock.mockResolvedValue({
        ok: false
      })
      
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toastSpy = jest.spyOn(controller, 'showToast')
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()
      
      const button = element.querySelector('[data-notification-type="document_upload"]')
      const event = new Event('click')
      event.preventDefault = jest.fn()
      Object.defineProperty(event, 'currentTarget', { value: button, enumerable: true })
      
      await controller.showPreview(event)
      
      expect(consoleSpy).toHaveBeenCalled()
      expect(toastSpy).toHaveBeenCalledWith("Erreur lors du chargement de l'aperçu", 'error')
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#closePreview", () => {
    it("hides preview modal", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const hideSpy = jest.spyOn(controller, 'hidePreviewModal')
      
      const event = new Event('click')
      event.preventDefault = jest.fn()
      
      controller.closePreview(event)
      
      expect(hideSpy).toHaveBeenCalled()
      expect(event.preventDefault).toHaveBeenCalled()
    })
  })
  
  describe("#showPreviewModal", () => {
    it("displays modal with content", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const content = '<div>Test preview</div>'
      
      controller.showPreviewModal(content)
      
      const modal = document.getElementById('preview-modal')
      const previewContent = document.getElementById('preview-content')
      
      expect(modal.classList.contains('hidden')).toBe(false)
      expect(previewContent.innerHTML).toBe(content)
      expect(document.body.classList.contains('overflow-hidden')).toBe(true)
    })
  })
  
  describe("#hidePreviewModal", () => {
    it("hides modal", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const modal = document.getElementById('preview-modal')
      modal.classList.remove('hidden')
      document.body.classList.add('overflow-hidden')
      
      controller.hidePreviewModal()
      
      expect(modal.classList.contains('hidden')).toBe(true)
      expect(document.body.classList.contains('overflow-hidden')).toBe(false)
    })
  })
  
  describe("#isCategoryEnabled", () => {
    it("returns true when at least one preference is enabled", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      expect(controller.isCategoryEnabled('documents')).toBe(true)
      expect(controller.isCategoryEnabled('validations')).toBe(true)
    })
    
    it("returns false when no preferences are enabled", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      // Uncheck all documents checkboxes
      const checkboxes = element.querySelectorAll('[data-category="documents"] .preference-enabled')
      checkboxes.forEach(cb => cb.checked = false)
      
      expect(controller.isCategoryEnabled('documents')).toBe(false)
    })
  })
  
  describe("#updateCategoryToggle", () => {
    it("updates toggle appearance when enabled", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toggle = element.querySelector('[data-category="documents"]')
      const thumb = toggle.querySelector('.toggle-thumb')
      
      controller.updateCategoryToggle(toggle, true)
      
      expect(toggle.classList.contains('category-enabled')).toBe(true)
      expect(toggle.classList.contains('bg-blue-600')).toBe(true)
      expect(toggle.classList.contains('bg-gray-200')).toBe(false)
      expect(thumb.classList.contains('translate-x-5')).toBe(true)
      expect(thumb.classList.contains('translate-x-0')).toBe(false)
    })
    
    it("updates toggle appearance when disabled", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toggle = element.querySelector('[data-category="validations"]')
      const thumb = toggle.querySelector('.toggle-thumb')
      
      controller.updateCategoryToggle(toggle, false)
      
      expect(toggle.classList.contains('category-enabled')).toBe(false)
      expect(toggle.classList.contains('bg-blue-600')).toBe(false)
      expect(toggle.classList.contains('bg-gray-200')).toBe(true)
      expect(thumb.classList.contains('translate-x-5')).toBe(false)
      expect(thumb.classList.contains('translate-x-0')).toBe(true)
    })
  })
  
  describe("#autoSave", () => {
    it("saves preferences successfully", async () => {
      fetch.mock.mockResolvedValue({
        ok: true
      })
      
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toastSpy = jest.spyOn(controller, 'showToast')
      
      await controller.autoSave()
      
      expect(fetch.mock.calls.length).toBe(1)
      expect(fetch.mock.calls[0][0]).toBe('/notification_preferences/bulk_update')
      expect(fetch.mock.calls[0][1].method).toBe('PATCH')
      expect(toastSpy).toHaveBeenCalledWith('Préférences sauvegardées automatiquement', 'success')
    })
    
    it("handles save errors gracefully", async () => {
      fetch.mock.mockRejectedValue(new Error('Network error'))
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()
      
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      await controller.autoSave()
      
      expect(consoleSpy).toHaveBeenCalledWith('Auto-save failed:', expect.any(Error))
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#showToast", () => {
    beforeEach(() => {
      jest.useFakeTimers()
    })
    
    afterEach(() => {
      jest.useRealTimers()
    })
    
    it("creates and displays toast with correct styling", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      controller.showToast('Test message', 'success')
      
      const toast = document.querySelector('.preferences-toast--success')
      expect(toast).toBeTruthy()
      expect(toast.textContent).toBe('Test message')
      expect(toast.style.backgroundColor).toBe('#10B981')
    })
    
    it("removes toast after timeout", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      controller.showToast('Test message', 'error')
      
      const toast = document.querySelector('.preferences-toast--error')
      expect(toast).toBeTruthy()
      
      // Fast-forward time
      jest.advanceTimersByTime(3500)
      
      expect(document.querySelector('.preferences-toast--error')).toBeFalsy()
    })
    
    it("uses correct colors for different types", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      const types = {
        success: '#10B981',
        error: '#EF4444',
        warning: '#F59E0B',
        info: '#3B82F6'
      }
      
      Object.entries(types).forEach(([type, color]) => {
        controller.showToast(`${type} message`, type)
        const toast = document.querySelector(`.preferences-toast--${type}`)
        expect(toast.style.backgroundColor).toBe(color)
        toast.remove()
      })
    })
  })
  
  describe("#getCsrfToken", () => {
    it("returns CSRF token from meta tag", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      expect(controller.getCsrfToken()).toBe('test-token-123')
    })
    
    it("returns empty string when no token found", () => {
      document.head.innerHTML = ''
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      
      expect(controller.getCsrfToken()).toBe('')
    })
  })
  
  describe("String.prototype.humanize", () => {
    it("humanizes category names in toast messages", () => {
      // Mock String.prototype.humanize if needed
      if (!String.prototype.humanize) {
        String.prototype.humanize = function() {
          return this.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
        }
      }
      
      const controller = application.getControllerForElementAndIdentifier(element, "preferences")
      const toastSpy = jest.spyOn(controller, 'showToast')
      
      const button = element.querySelector('[data-category="documents"]')
      button.classList.add('category-enabled')
      const event = new Event('click')
      Object.defineProperty(event, 'currentTarget', { value: button, enumerable: true })
      
      controller.toggleCategory(event)
      
      expect(toastSpy).toHaveBeenCalledWith(expect.stringContaining('désactivées'), 'info')
    })
  })
})