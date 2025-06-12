import { Application } from "@hotwired/stimulus"
import RippleController from "../../../app/javascript/controllers/ripple_controller"

describe("RippleController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <button data-controller="ripple" style="width: 100px; height: 40px;">
        Click me
      </button>
    `
    
    application = Application.start()
    application.register("ripple", RippleController)
    
    element = document.querySelector('[data-controller="ripple"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#connect", () => {
    it("adds click event listener on connect", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "ripple")
      const spy = jest.spyOn(controller, 'createRipple')
      
      // Re-connect to ensure event listener is added
      controller.disconnect()
      controller.connect()
      
      element.click()
      
      expect(spy).toHaveBeenCalled()
    })
  })
  
  describe("#createRipple", () => {
    it("creates ripple effect element on click", () => {
      element.click()
      
      const ripple = element.querySelector('.ripple-effect')
      expect(ripple).toBeTruthy()
      expect(ripple.tagName).toBe('SPAN')
    })
    
    it("sets correct ripple size based on element dimensions", () => {
      // Mock getBoundingClientRect
      element.getBoundingClientRect = jest.fn().mockReturnValue({
        width: 100,
        height: 40,
        left: 10,
        top: 20
      })
      
      element.click()
      
      const ripple = element.querySelector('.ripple-effect')
      expect(ripple.style.width).toBe('100px')
      expect(ripple.style.height).toBe('100px')
    })
    
    it("positions ripple at click location", () => {
      element.getBoundingClientRect = jest.fn().mockReturnValue({
        width: 100,
        height: 40,
        left: 10,
        top: 20
      })
      
      const clickEvent = new MouseEvent('click', {
        clientX: 60,
        clientY: 40
      })
      
      element.dispatchEvent(clickEvent)
      
      const ripple = element.querySelector('.ripple-effect')
      // Ripple should be centered at click position
      // x = 60 - 10 (left) - 50 (half of size 100) = 0
      // y = 40 - 20 (top) - 50 (half of size 100) = -30
      expect(ripple.style.left).toBe('0px')
      expect(ripple.style.top).toBe('-30px')
    })
    
    it("sets button styles for ripple effect", () => {
      element.click()
      
      expect(element.style.position).toBe('relative')
      expect(element.style.overflow).toBe('hidden')
    })
    
    it("creates multiple ripples for multiple clicks", () => {
      element.click()
      element.click()
      element.click()
      
      const ripples = element.querySelectorAll('.ripple-effect')
      expect(ripples.length).toBe(3)
    })
    
    it("removes ripple after animation ends", () => {
      element.click()
      
      const ripple = element.querySelector('.ripple-effect')
      expect(ripple).toBeTruthy()
      
      // Simulate animation end
      const animationEndEvent = new Event('animationend')
      ripple.dispatchEvent(animationEndEvent)
      
      expect(element.querySelector('.ripple-effect')).toBeFalsy()
    })
  })
  
  describe("#disconnect", () => {
    it("removes click event listener on disconnect", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "ripple")
      const spy = jest.spyOn(controller, 'createRipple')
      
      controller.disconnect()
      
      // Click should not trigger createRipple after disconnect
      element.click()
      
      expect(spy).not.toHaveBeenCalled()
    })
  })
  
  describe("edge cases", () => {
    it("handles rapid clicks correctly", () => {
      // Rapidly click the button
      for (let i = 0; i < 10; i++) {
        element.click()
      }
      
      const ripples = element.querySelectorAll('.ripple-effect')
      expect(ripples.length).toBe(10)
    })
    
    it("handles clicks at element edges", () => {
      element.getBoundingClientRect = jest.fn().mockReturnValue({
        width: 100,
        height: 40,
        left: 0,
        top: 0
      })
      
      // Click at top-left corner
      let clickEvent = new MouseEvent('click', {
        clientX: 0,
        clientY: 0
      })
      element.dispatchEvent(clickEvent)
      
      let ripple = element.querySelector('.ripple-effect')
      expect(ripple.style.left).toBe('-50px')
      expect(ripple.style.top).toBe('-50px')
      
      // Remove first ripple
      ripple.remove()
      
      // Click at bottom-right corner
      clickEvent = new MouseEvent('click', {
        clientX: 100,
        clientY: 40
      })
      element.dispatchEvent(clickEvent)
      
      ripple = element.querySelector('.ripple-effect')
      expect(ripple.style.left).toBe('50px')
      expect(ripple.style.top).toBe('-10px')
    })
    
    it("handles very large elements", () => {
      element.getBoundingClientRect = jest.fn().mockReturnValue({
        width: 500,
        height: 300,
        left: 0,
        top: 0
      })
      
      element.click()
      
      const ripple = element.querySelector('.ripple-effect')
      // Should use the larger dimension
      expect(ripple.style.width).toBe('500px')
      expect(ripple.style.height).toBe('500px')
    })
    
    it("handles zero-sized elements", () => {
      element.getBoundingClientRect = jest.fn().mockReturnValue({
        width: 0,
        height: 0,
        left: 0,
        top: 0
      })
      
      element.click()
      
      const ripple = element.querySelector('.ripple-effect')
      expect(ripple.style.width).toBe('0px')
      expect(ripple.style.height).toBe('0px')
    })
  })
  
  describe("multiple elements", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <button data-controller="ripple" id="button1">Button 1</button>
        <button data-controller="ripple" id="button2">Button 2</button>
        <button data-controller="ripple" id="button3">Button 3</button>
      `
      
      application = Application.start()
      application.register("ripple", RippleController)
    })
    
    it("handles multiple ripple buttons independently", () => {
      const button1 = document.getElementById('button1')
      const button2 = document.getElementById('button2')
      const button3 = document.getElementById('button3')
      
      button1.click()
      button2.click()
      button3.click()
      
      expect(button1.querySelector('.ripple-effect')).toBeTruthy()
      expect(button2.querySelector('.ripple-effect')).toBeTruthy()
      expect(button3.querySelector('.ripple-effect')).toBeTruthy()
    })
  })
  
  describe("CSS requirements", () => {
    it("ripple element has required CSS classes", () => {
      element.click()
      
      const ripple = element.querySelector('.ripple-effect')
      expect(ripple.classList.contains('ripple-effect')).toBe(true)
    })
    
    it("ripple element has inline styles for positioning", () => {
      element.getBoundingClientRect = jest.fn().mockReturnValue({
        width: 100,
        height: 40,
        left: 0,
        top: 0
      })
      
      const clickEvent = new MouseEvent('click', {
        clientX: 50,
        clientY: 20
      })
      element.dispatchEvent(clickEvent)
      
      const ripple = element.querySelector('.ripple-effect')
      expect(ripple.style.position).toBe('') // Position is set by CSS class
      expect(ripple.style.width).toBeTruthy()
      expect(ripple.style.height).toBeTruthy()
      expect(ripple.style.left).toBeTruthy()
      expect(ripple.style.top).toBeTruthy()
    })
  })
})