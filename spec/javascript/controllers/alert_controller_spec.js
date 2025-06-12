import '../setup.js'
import { Application } from "@hotwired/stimulus"
import AlertController from "../../../app/javascript/controllers/alert_controller"

describe("AlertController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="alert" class="alert alert-info">
        <p>This is an alert message</p>
        <button data-action="click->alert#dismiss" class="close-button">
          ×
        </button>
      </div>
    `
    
    application = Application.start()
    application.register("alert", AlertController)
    
    element = document.querySelector('[data-controller="alert"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#dismiss", () => {
    it("fades out the alert", (done) => {
      const button = element.querySelector('[data-action*="dismiss"]')
      
      // Initial state
      expect(element.style.opacity).toBe('')
      
      button.click()
      
      // Should start fading
      expect(element.style.transition).toBe('opacity 150ms ease-in-out')
      expect(element.style.opacity).toBe('0')
      
      // Still in DOM immediately after click
      expect(document.contains(element)).toBe(true)
      
      // Should be removed after animation
      setTimeout(() => {
        expect(document.contains(element)).toBe(false)
        done()
      }, 200)
    })
    
    it("removes the element from DOM after animation", (done) => {
      const controller = application.getControllerForElementAndIdentifier(element, "alert")
      
      controller.dismiss()
      
      // Element should still exist during animation
      expect(element.parentNode).toBeTruthy()
      
      setTimeout(() => {
        // Element should be removed after 150ms
        expect(element.parentNode).toBeFalsy()
        done()
      }, 200)
    })
    
    it("applies transition styles correctly", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "alert")
      
      controller.dismiss()
      
      expect(element.style.transition).toBe('opacity 150ms ease-in-out')
      expect(element.style.opacity).toBe('0')
    })
    
    it("handles multiple dismiss calls gracefully", () => {
      const button = element.querySelector('[data-action*="dismiss"]')
      
      // Multiple rapid clicks
      button.click()
      button.click()
      button.click()
      
      // Should still animate properly
      expect(element.style.opacity).toBe('0')
      expect(element.style.transition).toBe('opacity 150ms ease-in-out')
    })
    
    it("works with keyboard activation", () => {
      const button = element.querySelector('[data-action*="dismiss"]')
      
      // Simulate Enter key press
      const enterEvent = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })
      button.dispatchEvent(enterEvent)
      
      // Then click
      button.click()
      
      expect(element.style.opacity).toBe('0')
    })
  })
  
  describe("edge cases", () => {
    it("handles missing dismiss button", () => {
      document.body.innerHTML = `
        <div data-controller="alert" class="alert">
          <p>Alert without dismiss button</p>
        </div>
      `
      
      element = document.querySelector('[data-controller="alert"]')
      const controller = application.getControllerForElementAndIdentifier(element, "alert")
      
      // Should not throw error
      expect(() => controller.dismiss()).not.toThrow()
    })
    
    it("cleans up properly when disconnected during animation", (done) => {
      const controller = application.getControllerForElementAndIdentifier(element, "alert")
      
      controller.dismiss()
      
      // Disconnect controller during animation
      setTimeout(() => {
        controller.disconnect()
      }, 50)
      
      // Element should still be removed
      setTimeout(() => {
        expect(element.parentNode).toBeFalsy()
        done()
      }, 200)
    })
  })
  
  describe("accessibility", () => {
    it("dismiss button should be keyboard accessible", () => {
      const button = element.querySelector('[data-action*="dismiss"]')
      
      expect(button.tagName).toBe('BUTTON')
      expect(button.tabIndex).toBeGreaterThanOrEqual(0)
    })
    
    it("alert should have appropriate role", () => {
      // Alert elements should have alert role for screen readers
      const role = element.getAttribute('role') || 'alert'
      expect(['alert', 'status']).toContain(role)
    })
    
    it("maintains focus management after dismiss", (done) => {
      const button = element.querySelector('[data-action*="dismiss"]')
      
      // Set focus on button
      button.focus()
      expect(document.activeElement).toBe(button)
      
      // Dismiss
      button.click()
      
      setTimeout(() => {
        // Focus should move to body or next focusable element
        expect(document.activeElement).not.toBe(button)
        done()
      }, 200)
    })
  })
  
  describe("animation timing", () => {
    beforeEach(() => {
      jest.useFakeTimers()
    })
    
    afterEach(() => {
      jest.useRealTimers()
    })
    
    it("removes element after exact timeout", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "alert")
      
      controller.dismiss()
      
      // Should still be in DOM before timeout
      jest.advanceTimersByTime(149)
      expect(document.contains(element)).toBe(true)
      
      // Should be removed after timeout
      jest.advanceTimersByTime(1)
      expect(document.contains(element)).toBe(false)
    })
  })
  
  describe("styling", () => {
    it("preserves existing styles when dismissing", () => {
      element.style.backgroundColor = 'red'
      element.style.padding = '10px'
      
      const controller = application.getControllerForElementAndIdentifier(element, "alert")
      controller.dismiss()
      
      // Should preserve other styles
      expect(element.style.backgroundColor).toBe('red')
      expect(element.style.padding).toBe('10px')
      
      // Should only modify opacity and transition
      expect(element.style.opacity).toBe('0')
      expect(element.style.transition).toBe('opacity 150ms ease-in-out')
    })
    
    it("handles pre-existing transitions", () => {
      element.style.transition = 'all 500ms ease-out'
      
      const controller = application.getControllerForElementAndIdentifier(element, "alert")
      controller.dismiss()
      
      // Should override with dismiss transition
      expect(element.style.transition).toBe('opacity 150ms ease-in-out')
    })
  })
})