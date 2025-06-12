import '../setup.js'
import { Application } from "@hotwired/stimulus"
import LazyLoadController from "../../../app/javascript/controllers/lazy_load_controller"

describe("LazyLoadController", () => {
  let application
  let element
  let observeCallback
  let mockObserver
  
  beforeEach(() => {
    // Mock IntersectionObserver
    observeCallback = null
    mockObserver = {
      observe: jest.fn(),
      unobserve: jest.fn(),
      disconnect: jest.fn()
    }
    
    global.IntersectionObserver = jest.fn().mockImplementation((callback, options) => {
      observeCallback = callback
      return mockObserver
    })
    
    // Mock Image constructor
    global.Image = jest.fn().mockImplementation(function() {
      this.onload = null
      this.onerror = null
      Object.defineProperty(this, 'src', {
        set: function(value) {
          this._src = value
          // Simulate successful load by default
          if (this.onload && !value.includes('error')) {
            setTimeout(() => this.onload(), 10)
          } else if (this.onerror && value.includes('error')) {
            setTimeout(() => this.onerror(), 10)
          }
        },
        get: function() {
          return this._src
        }
      })
    })
    
    document.body.innerHTML = `
      <div data-controller="lazy-load"
           data-lazy-load-src-value="https://example.com/image.jpg"
           data-lazy-load-threshold-value="0.2"
           data-lazy-load-root-margin-value="100px">
        <div data-lazy-load-target="placeholder" class="placeholder">Loading...</div>
        <img data-lazy-load-target="image" data-src="https://example.com/image1.jpg" style="opacity: 1">
      </div>
      
      <div data-controller="lazy-load">
        <img data-lazy-load-target="image" data-src="https://example.com/image2.jpg">
        <img data-lazy-load-target="image" data-src="https://example.com/image3.jpg">
      </div>
      
      <img data-controller="lazy-load" data-src="https://example.com/single-image.jpg">
    `
    
    application = Application.start()
    application.register("lazy-load", LazyLoadController)
    
    element = document.querySelector('[data-controller="lazy-load"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    jest.clearAllTimers()
  })
  
  describe("connect", () => {
    it("creates IntersectionObserver with correct options", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      
      controller.connect()
      
      expect(global.IntersectionObserver).toHaveBeenCalledWith(
        expect.any(Function),
        {
          threshold: 0.2,
          rootMargin: "100px"
        }
      )
    })
    
    it("observes image targets when available", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      
      controller.connect()
      
      const images = element.querySelectorAll('[data-lazy-load-target="image"]')
      expect(mockObserver.observe).toHaveBeenCalledWith(images[0])
    })
    
    it("observes element itself when no image targets", () => {
      const singleImage = document.querySelector('img[data-controller="lazy-load"]')
      const controller = application.getControllerForElementAndIdentifier(singleImage, "lazy-load")
      
      controller.connect()
      
      expect(mockObserver.observe).toHaveBeenCalledWith(singleImage)
    })
    
    it("uses default values when not specified", () => {
      document.body.innerHTML = `
        <div data-controller="lazy-load">
          <img data-lazy-load-target="image" data-src="test.jpg">
        </div>
      `
      
      const element = document.querySelector('[data-controller="lazy-load"]')
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      
      controller.connect()
      
      expect(global.IntersectionObserver).toHaveBeenCalledWith(
        expect.any(Function),
        {
          threshold: 0.1,
          rootMargin: "50px"
        }
      )
    })
  })
  
  describe("disconnect", () => {
    it("disconnects observer on disconnect", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      
      controller.connect()
      controller.disconnect()
      
      expect(mockObserver.disconnect).toHaveBeenCalled()
    })
  })
  
  describe("#handleIntersection", () => {
    it("loads images when they intersect", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      controller.connect()
      
      const img = element.querySelector('[data-lazy-load-target="image"]')
      const entries = [{
        isIntersecting: true,
        target: img
      }]
      
      observeCallback(entries)
      
      // Wait for image load
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(img.src).toBe('https://example.com/image1.jpg')
      expect(mockObserver.unobserve).toHaveBeenCalledWith(img)
    })
    
    it("does not load images when not intersecting", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      controller.connect()
      
      const img = element.querySelector('[data-lazy-load-target="image"]')
      const entries = [{
        isIntersecting: false,
        target: img
      }]
      
      observeCallback(entries)
      
      expect(img.src).not.toBe('https://example.com/image1.jpg')
      expect(mockObserver.unobserve).not.toHaveBeenCalled()
    })
  })
  
  describe("#loadImage", () => {
    it("loads image with fade-in animation", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = element.querySelector('[data-lazy-load-target="image"]')
      
      controller.loadImage(img)
      
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(img.src).toBe('https://example.com/image1.jpg')
      expect(img.style.opacity).toBe('1')
      expect(img.style.transition).toBe('opacity 300ms ease-in-out')
      expect(img.dataset.src).toBeUndefined()
      expect(element.classList.contains('lazy-loaded')).toBe(true)
    })
    
    it("removes placeholder on successful load", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = element.querySelector('[data-lazy-load-target="image"]')
      const placeholder = element.querySelector('[data-lazy-load-target="placeholder"]')
      
      controller.loadImage(img)
      
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(placeholder.style.opacity).toBe('0')
      
      // Wait for removal
      await new Promise(resolve => setTimeout(resolve, 310))
      
      expect(document.contains(placeholder)).toBe(false)
    })
    
    it("uses src value from controller when data-src not present", async () => {
      document.body.innerHTML = `
        <div data-controller="lazy-load"
             data-lazy-load-src-value="https://example.com/controller-image.jpg">
          <img data-lazy-load-target="image">
        </div>
      `
      
      const element = document.querySelector('[data-controller="lazy-load"]')
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = element.querySelector('img')
      
      controller.loadImage(img)
      
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(img.src).toBe('https://example.com/controller-image.jpg')
    })
    
    it("handles non-img elements correctly", async () => {
      document.body.innerHTML = `
        <div data-controller="lazy-load">
          <div data-lazy-load-target="image" data-src="https://example.com/bg.jpg">
            <img>
          </div>
        </div>
      `
      
      const element = document.querySelector('[data-controller="lazy-load"]')
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const div = element.querySelector('div[data-lazy-load-target]')
      const img = div.querySelector('img')
      
      controller.loadImage(div)
      
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(img.src).toBe('https://example.com/bg.jpg')
    })
    
    it("dispatches loaded event on successful load", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = element.querySelector('[data-lazy-load-target="image"]')
      
      const loadedHandler = jest.fn()
      element.addEventListener('lazy-load:loaded', loadedHandler)
      
      controller.loadImage(img)
      
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(loadedHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { src: 'https://example.com/image1.jpg' }
        })
      )
    })
    
    it("handles image load errors", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = element.querySelector('[data-lazy-load-target="image"]')
      img.dataset.src = 'https://example.com/error.jpg'
      
      const errorHandler = jest.fn()
      element.addEventListener('lazy-load:error', errorHandler)
      
      controller.loadImage(img)
      
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(element.classList.contains('lazy-error')).toBe(true)
      expect(errorHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { src: 'https://example.com/error.jpg' }
        })
      )
    })
    
    it("does nothing when no src available", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = document.createElement('img')
      
      controller.loadImage(img)
      
      expect(img.src).toBe('')
    })
    
    it("does nothing when no img element found", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const div = document.createElement('div')
      
      // Should not throw
      expect(() => controller.loadImage(div)).not.toThrow()
    })
  })
  
  describe("#load", () => {
    it("manually loads all image targets", async () => {
      const container = document.querySelectorAll('[data-controller="lazy-load"]')[1]
      const controller = application.getControllerForElementAndIdentifier(container, "lazy-load")
      const loadImageSpy = jest.spyOn(controller, 'loadImage')
      
      controller.load()
      
      expect(loadImageSpy).toHaveBeenCalledTimes(2)
    })
    
    it("manually loads element when no image targets", () => {
      const singleImage = document.querySelector('img[data-controller="lazy-load"]')
      const controller = application.getControllerForElementAndIdentifier(singleImage, "lazy-load")
      const loadImageSpy = jest.spyOn(controller, 'loadImage')
      
      controller.load()
      
      expect(loadImageSpy).toHaveBeenCalledWith(singleImage)
    })
  })
  
  describe("static preload", () => {
    it("preloads multiple images", () => {
      const urls = [
        'https://example.com/preload1.jpg',
        'https://example.com/preload2.jpg',
        'https://example.com/preload3.jpg'
      ]
      
      LazyLoadController.preload(urls)
      
      expect(global.Image).toHaveBeenCalledTimes(urls.length)
    })
  })
  
  describe("requestAnimationFrame", () => {
    it("uses requestAnimationFrame for smooth animation", async () => {
      const rafSpy = jest.spyOn(window, 'requestAnimationFrame')
      
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = element.querySelector('[data-lazy-load-target="image"]')
      
      controller.loadImage(img)
      
      await new Promise(resolve => setTimeout(resolve, 20))
      
      expect(rafSpy).toHaveBeenCalled()
      
      rafSpy.mockRestore()
    })
  })
  
  describe("edge cases", () => {
    it("handles multiple rapid load calls", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = element.querySelector('[data-lazy-load-target="image"]')
      
      // Call loadImage multiple times rapidly
      controller.loadImage(img)
      controller.loadImage(img)
      controller.loadImage(img)
      
      await new Promise(resolve => setTimeout(resolve, 30))
      
      // Should only load once
      expect(img.src).toBe('https://example.com/image1.jpg')
    })
    
    it("handles disconnect during image load", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "lazy-load")
      const img = element.querySelector('[data-lazy-load-target="image"]')
      
      controller.loadImage(img)
      controller.disconnect()
      
      await new Promise(resolve => setTimeout(resolve, 20))
      
      // Should still complete the load
      expect(img.src).toBe('https://example.com/image1.jpg')
    })
  })
})