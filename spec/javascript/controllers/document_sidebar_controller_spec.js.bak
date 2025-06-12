import { Application } from "@hotwired/stimulus"
import DocumentSidebarController from "../../../app/javascript/controllers/document_sidebar_controller"

describe("DocumentSidebarController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="document-sidebar" class="w-80">
        <nav>
          <button data-action="click->document-sidebar#showTab" 
                  data-document-sidebar-tab-param="info"
                  class="text-blue-600 border-blue-600 bg-white">
            Info
          </button>
          <button data-action="click->document-sidebar#showTab" 
                  data-document-sidebar-tab-param="metadata"
                  class="text-gray-600 border-transparent">
            Metadata
          </button>
          <button data-action="click->document-sidebar#showTab" 
                  data-document-sidebar-tab-param="activity"
                  class="text-gray-600 border-transparent">
            Activity
          </button>
          <button data-action="click->document-sidebar#showTab" 
                  data-document-sidebar-tab-param="versions"
                  class="text-gray-600 border-transparent">
            Versions
          </button>
        </nav>
        
        <div data-document-sidebar-target="infoTab" class="">
          <h3>Document Information</h3>
          <p>File details here</p>
        </div>
        
        <div data-document-sidebar-target="metadataTab" class="hidden">
          <h3>Metadata</h3>
          <p>Metadata details here</p>
        </div>
        
        <div data-document-sidebar-target="activityTab" class="hidden">
          <h3>Activity Log</h3>
          <p>Activity details here</p>
        </div>
        
        <div data-document-sidebar-target="versionsTab" class="hidden">
          <h3>Version History</h3>
          <p>Version details here</p>
        </div>
        
        <button data-action="click->document-sidebar#toggleSidebar">Toggle</button>
      </div>
    `
    
    application = Application.start()
    application.register("document-sidebar", DocumentSidebarController)
    
    element = document.querySelector('[data-controller="document-sidebar"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#connect", () => {
    it("sets initial active tab to info", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      expect(controller.activeTab).toBe('info')
    })
  })
  
  describe("#showTab", () => {
    it("shows the selected tab content", () => {
      const metadataButton = element.querySelector('[data-document-sidebar-tab-param="metadata"]')
      const metadataTab = element.querySelector('[data-document-sidebar-target="metadataTab"]')
      
      metadataButton.click()
      
      expect(metadataTab.classList.contains('hidden')).toBe(false)
    })
    
    it("hides other tab content", () => {
      const metadataButton = element.querySelector('[data-document-sidebar-tab-param="metadata"]')
      const infoTab = element.querySelector('[data-document-sidebar-target="infoTab"]')
      const activityTab = element.querySelector('[data-document-sidebar-target="activityTab"]')
      const versionsTab = element.querySelector('[data-document-sidebar-target="versionsTab"]')
      
      metadataButton.click()
      
      expect(infoTab.classList.contains('hidden')).toBe(true)
      expect(activityTab.classList.contains('hidden')).toBe(true)
      expect(versionsTab.classList.contains('hidden')).toBe(true)
    })
    
    it("updates button styles for active tab", () => {
      const metadataButton = element.querySelector('[data-document-sidebar-tab-param="metadata"]')
      const infoButton = element.querySelector('[data-document-sidebar-tab-param="info"]')
      
      metadataButton.click()
      
      // Active button styles
      expect(metadataButton.classList.contains('text-blue-600')).toBe(true)
      expect(metadataButton.classList.contains('border-blue-600')).toBe(true)
      expect(metadataButton.classList.contains('bg-white')).toBe(true)
      expect(metadataButton.classList.contains('text-gray-600')).toBe(false)
      
      // Inactive button styles
      expect(infoButton.classList.contains('text-blue-600')).toBe(false)
      expect(infoButton.classList.contains('text-gray-600')).toBe(true)
      expect(infoButton.classList.contains('border-transparent')).toBe(true)
    })
    
    it("updates activeTab property", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      const versionsButton = element.querySelector('[data-document-sidebar-tab-param="versions"]')
      
      versionsButton.click()
      
      expect(controller.activeTab).toBe('versions')
    })
    
    it("loads activity content on first show", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      const activityButton = element.querySelector('[data-document-sidebar-tab-param="activity"]')
      const activityTab = element.querySelector('[data-document-sidebar-target="activityTab"]')
      
      // Spy on loadActivityContent
      const loadSpy = jest.spyOn(controller, 'loadActivityContent')
      
      // First click - should load
      activityButton.click()
      expect(loadSpy).toHaveBeenCalled()
      expect(activityTab.dataset.loaded).toBe('true')
      
      // Reset spy
      loadSpy.mockClear()
      
      // Switch to another tab
      const infoButton = element.querySelector('[data-document-sidebar-tab-param="info"]')
      infoButton.click()
      
      // Second click - should not load again
      activityButton.click()
      expect(loadSpy).not.toHaveBeenCalled()
    })
  })
  
  describe("#hideAllTabs", () => {
    it("hides all tab targets", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      
      // Make some tabs visible first
      element.querySelector('[data-document-sidebar-target="metadataTab"]').classList.remove('hidden')
      element.querySelector('[data-document-sidebar-target="activityTab"]').classList.remove('hidden')
      
      controller.hideAllTabs()
      
      expect(element.querySelector('[data-document-sidebar-target="infoTab"]').classList.contains('hidden')).toBe(true)
      expect(element.querySelector('[data-document-sidebar-target="metadataTab"]').classList.contains('hidden')).toBe(true)
      expect(element.querySelector('[data-document-sidebar-target="activityTab"]').classList.contains('hidden')).toBe(true)
      expect(element.querySelector('[data-document-sidebar-target="versionsTab"]').classList.contains('hidden')).toBe(true)
    })
  })
  
  describe("#showTabContent", () => {
    it("shows the specified tab content", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      const metadataTab = element.querySelector('[data-document-sidebar-target="metadataTab"]')
      
      controller.showTabContent('metadata')
      
      expect(metadataTab.classList.contains('hidden')).toBe(false)
    })
    
    it("handles non-existent tabs gracefully", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      
      // Should not throw
      expect(() => controller.showTabContent('nonexistent')).not.toThrow()
    })
  })
  
  describe("#loadActivityContent", () => {
    it("marks activity tab as loaded", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      const activityTab = element.querySelector('[data-document-sidebar-target="activityTab"]')
      
      controller.loadActivityContent()
      
      expect(activityTab.dataset.loaded).toBe('true')
    })
  })
  
  describe("#toggleSidebar", () => {
    it("toggles sidebar visibility classes", () => {
      const toggleButton = element.querySelector('[data-action*="toggleSidebar"]')
      
      // Initial state
      expect(element.classList.contains('w-80')).toBe(true)
      expect(element.classList.contains('w-0')).toBe(false)
      expect(element.classList.contains('hidden')).toBe(false)
      
      // First toggle - hide
      toggleButton.click()
      expect(element.classList.contains('w-80')).toBe(false)
      expect(element.classList.contains('w-0')).toBe(true)
      expect(element.classList.contains('hidden')).toBe(true)
      
      // Second toggle - show
      toggleButton.click()
      expect(element.classList.contains('w-80')).toBe(true)
      expect(element.classList.contains('w-0')).toBe(false)
      expect(element.classList.contains('hidden')).toBe(false)
    })
    
    it("dispatches sidebar:toggled event", () => {
      const toggleButton = element.querySelector('[data-action*="toggleSidebar"]')
      let eventDetail = null
      
      element.addEventListener('sidebar:toggled', (event) => {
        eventDetail = event.detail
      })
      
      // Hide sidebar
      toggleButton.click()
      expect(eventDetail).toEqual({ visible: false })
      
      // Show sidebar
      toggleButton.click()
      expect(eventDetail).toEqual({ visible: true })
    })
    
    it("event bubbles up", () => {
      const toggleButton = element.querySelector('[data-action*="toggleSidebar"]')
      let eventCaught = false
      
      document.body.addEventListener('sidebar:toggled', () => {
        eventCaught = true
      })
      
      toggleButton.click()
      
      expect(eventCaught).toBe(true)
    })
  })
  
  describe("edge cases", () => {
    it("handles missing tab targets gracefully", () => {
      // Remove some targets
      element.querySelector('[data-document-sidebar-target="activityTab"]').remove()
      element.querySelector('[data-document-sidebar-target="versionsTab"]').remove()
      
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      const activityButton = element.querySelector('[data-document-sidebar-tab-param="activity"]')
      
      // Should not throw when trying to show missing tab
      expect(() => activityButton.click()).not.toThrow()
      
      // Should still update active tab
      expect(controller.activeTab).toBe('activity')
    })
    
    it("handles multiple rapid tab switches", () => {
      const buttons = element.querySelectorAll('nav button')
      const controller = application.getControllerForElementAndIdentifier(element, "document-sidebar")
      
      // Rapidly click all buttons
      buttons.forEach(button => button.click())
      
      // Should end on the last clicked tab
      expect(controller.activeTab).toBe('versions')
      
      // Only versions tab should be visible
      const visibleTabs = element.querySelectorAll('div[data-document-sidebar-target]:not(.hidden)')
      expect(visibleTabs.length).toBe(1)
      expect(visibleTabs[0]).toBe(element.querySelector('[data-document-sidebar-target="versionsTab"]'))
    })
  })
  
  describe("button styling edge cases", () => {
    it("handles buttons without all expected classes", () => {
      // Create a button with minimal classes
      const customButton = document.createElement('button')
      customButton.dataset.action = 'click->document-sidebar#showTab'
      customButton.dataset.documentSidebarTabParam = 'custom'
      element.querySelector('nav').appendChild(customButton)
      
      // Should not throw when clicking
      expect(() => customButton.click()).not.toThrow()
    })
    
    it("handles buttons with additional custom classes", () => {
      const infoButton = element.querySelector('[data-document-sidebar-tab-param="info"]')
      infoButton.classList.add('custom-class', 'another-custom-class')
      
      const metadataButton = element.querySelector('[data-document-sidebar-tab-param="metadata"]')
      metadataButton.click()
      
      // Custom classes should be preserved
      expect(infoButton.classList.contains('custom-class')).toBe(true)
      expect(infoButton.classList.contains('another-custom-class')).toBe(true)
    })
  })
  
  describe("initialization states", () => {
    it("respects initial tab visibility states", () => {
      // Before any interaction
      expect(element.querySelector('[data-document-sidebar-target="infoTab"]').classList.contains('hidden')).toBe(false)
      expect(element.querySelector('[data-document-sidebar-target="metadataTab"]').classList.contains('hidden')).toBe(true)
      expect(element.querySelector('[data-document-sidebar-target="activityTab"]').classList.contains('hidden')).toBe(true)
      expect(element.querySelector('[data-document-sidebar-target="versionsTab"]').classList.contains('hidden')).toBe(true)
    })
    
    it("respects initial button states", () => {
      const infoButton = element.querySelector('[data-document-sidebar-tab-param="info"]')
      const otherButtons = element.querySelectorAll('nav button:not([data-document-sidebar-tab-param="info"])')
      
      // Info button should have active styles
      expect(infoButton.classList.contains('text-blue-600')).toBe(true)
      expect(infoButton.classList.contains('border-blue-600')).toBe(true)
      expect(infoButton.classList.contains('bg-white')).toBe(true)
      
      // Other buttons should have inactive styles
      otherButtons.forEach(button => {
        expect(button.classList.contains('text-gray-600')).toBe(true)
        expect(button.classList.contains('border-transparent')).toBe(true)
      })
    })
  })
})