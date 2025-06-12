import { Application } from "@hotwired/stimulus"
import ImageZoomController from "../../../app/javascript/controllers/image_zoom_controller"

describe("ImageZoomController", () => {
  let application
  let controller
  let element
  
  beforeEach(() => {
    application = Application.start()
    application.register("image-zoom", ImageZoomController)
    
    document.body.innerHTML = `
      <div data-controller="image-zoom" data-image-zoom-src-value="/images/test.jpg">
        <img src="/images/test-thumb.jpg" 
             alt="Test image"
             data-action="click->image-zoom#toggle">
        
        <div class="image-zoom-modal hidden" data-image-zoom-target="modal">
          <img data-image-zoom-target="zoomedImage" alt="Zoomed image">
          <button data-action="click->image-zoom#close">Close</button>
          <button data-action="click->image-zoom#zoomIn">Zoom In</button>
          <button data-action="click->image-zoom#zoomOut">Zoom Out</button>
          <button data-action="click->image-zoom#resetZoom">Reset</button>
        </div>
      </div>
    `
    
    element = document.querySelector('[data-controller="image-zoom"]')
    controller = application.getControllerForElementAndIdentifier(element, "image-zoom")
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#toggle", () => {
    it("opens modal when closed", () => {
      const modal = element.querySelector('[data-image-zoom-target="modal"]')
      const image = element.querySelector('img[data-action]')
      
      expect(modal.classList.contains("hidden")).toBe(true)
      
      image.click()
      
      expect(modal.classList.contains("hidden")).toBe(false)
      expect(document.body.classList.contains("overflow-hidden")).toBe(true)
    })
    
    it("closes modal when open", (done) => {
      const modal = element.querySelector('[data-image-zoom-target="modal"]')
      const image = element.querySelector('img[data-action]')
      
      // Open first
      image.click()
      expect(modal.classList.contains("hidden")).toBe(false)
      
      // Then toggle to close
      image.click()
      
      setTimeout(() => {
        expect(modal.classList.contains("hidden")).toBe(true)
        done()
      }, 350)
    })
  })
  
  describe("#open", () => {
    it("sets the zoomed image source", () => {
      const image = element.querySelector('img[data-action]')
      const zoomedImage = element.querySelector('[data-image-zoom-target="zoomedImage"]')
      
      image.click()
      
      expect(zoomedImage.src).toContain("/images/test.jpg")
    })
    
    it("uses clicked image source if no src value", () => {
      controller.srcValue = null
      const image = element.querySelector('img[data-action]')
      const zoomedImage = element.querySelector('[data-image-zoom-target="zoomedImage"]')
      
      image.click()
      
      expect(zoomedImage.src).toContain("/images/test-thumb.jpg")
    })
    
    it("resets transform on open", () => {
      const image = element.querySelector('img[data-action]')
      const zoomedImage = element.querySelector('[data-image-zoom-target="zoomedImage"]')
      
      // Set some transform first
      controller.scale = 2
      controller.translateX = 100
      controller.translateY = 50
      
      image.click()
      
      expect(controller.scale).toBe(1)
      expect(controller.translateX).toBe(0)
      expect(controller.translateY).toBe(0)
    })
  })
  
  describe("#close", () => {
    beforeEach(() => {
      const image = element.querySelector('img[data-action]')
      image.click()
    })
    
    it("hides the modal", (done) => {
      const modal = element.querySelector('[data-image-zoom-target="modal"]')
      const closeButton = element.querySelector('[data-action="click->image-zoom#close"]')
      
      closeButton.click()
      
      setTimeout(() => {
        expect(modal.classList.contains("hidden")).toBe(true)
        expect(document.body.classList.contains("overflow-hidden")).toBe(false)
        done()
      }, 350)
    })
    
    it("resets transform state", (done) => {
      controller.scale = 2
      controller.translateX = 100
      
      const closeButton = element.querySelector('[data-action="click->image-zoom#close"]')
      closeButton.click()
      
      setTimeout(() => {
        expect(controller.scale).toBe(1)
        expect(controller.translateX).toBe(0)
        expect(controller.translateY).toBe(0)
        done()
      }, 350)
    })
  })
  
  describe("keyboard navigation", () => {
    beforeEach(() => {
      const image = element.querySelector('img[data-action]')
      image.click()
    })
    
    it("closes on Escape key", (done) => {
      const modal = element.querySelector('[data-image-zoom-target="modal"]')
      
      const escapeEvent = new KeyboardEvent("keydown", { key: "Escape" })
      document.dispatchEvent(escapeEvent)
      
      setTimeout(() => {
        expect(modal.classList.contains("hidden")).toBe(true)
        done()
      }, 350)
    })
  })
  
  describe("zoom controls", () => {
    beforeEach(() => {
      const image = element.querySelector('img[data-action]')
      image.click()
    })
    
    it("zooms in", () => {
      const zoomInButton = element.querySelector('[data-action="click->image-zoom#zoomIn"]')
      
      expect(controller.scale).toBe(1)
      
      zoomInButton.click()
      
      expect(controller.scale).toBeCloseTo(1.2)
    })
    
    it("zooms out", () => {
      const zoomOutButton = element.querySelector('[data-action="click->image-zoom#zoomOut"]')
      
      controller.scale = 2
      
      zoomOutButton.click()
      
      expect(controller.scale).toBeCloseTo(1.6)
    })
    
    it("resets zoom", () => {
      const resetButton = element.querySelector('[data-action="click->image-zoom#resetZoom"]')
      
      controller.scale = 3
      controller.translateX = 100
      controller.translateY = 50
      
      resetButton.click()
      
      expect(controller.scale).toBe(1)
      expect(controller.translateX).toBe(0)
      expect(controller.translateY).toBe(0)
    })
    
    it("respects zoom limits", () => {
      const zoomInButton = element.querySelector('[data-action="click->image-zoom#zoomIn"]')
      const zoomOutButton = element.querySelector('[data-action="click->image-zoom#zoomOut"]')
      
      // Test max zoom
      controller.scale = 4.5
      zoomInButton.click()
      expect(controller.scale).toBeLessThanOrEqual(5)
      
      // Test min zoom
      controller.scale = 0.6
      zoomOutButton.click()
      expect(controller.scale).toBeGreaterThanOrEqual(0.5)
    })
  })
  
  describe("mouse wheel zoom", () => {
    let zoomedImage
    
    beforeEach(() => {
      const image = element.querySelector('img[data-action]')
      image.click()
      zoomedImage = element.querySelector('[data-image-zoom-target="zoomedImage"]')
    })
    
    it("zooms in on negative deltaY", () => {
      const wheelEvent = new WheelEvent("wheel", { 
        deltaY: -100,
        clientX: 100,
        clientY: 100,
        cancelable: true 
      })
      
      zoomedImage.dispatchEvent(wheelEvent)
      
      expect(controller.scale).toBeGreaterThan(1)
      expect(wheelEvent.defaultPrevented).toBe(true)
    })
    
    it("zooms out on positive deltaY", () => {
      controller.scale = 2
      
      const wheelEvent = new WheelEvent("wheel", { 
        deltaY: 100,
        clientX: 100,
        clientY: 100,
        cancelable: true 
      })
      
      zoomedImage.dispatchEvent(wheelEvent)
      
      expect(controller.scale).toBeLessThan(2)
    })
  })
  
  describe("drag functionality", () => {
    let zoomedImage
    
    beforeEach(() => {
      const image = element.querySelector('img[data-action]')
      image.click()
      zoomedImage = element.querySelector('[data-image-zoom-target="zoomedImage"]')
      // Zoom in to enable dragging
      controller.scale = 2
      controller.updateTransform()
    })
    
    it("initializes drag on mousedown", () => {
      const mousedownEvent = new MouseEvent("mousedown", {
        clientX: 100,
        clientY: 100,
        cancelable: true
      })
      
      zoomedImage.dispatchEvent(mousedownEvent)
      
      expect(controller.isDragging).toBe(true)
      expect(zoomedImage.style.cursor).toBe("grabbing")
    })
    
    it("updates position on mousemove while dragging", () => {
      // Start drag
      const mousedownEvent = new MouseEvent("mousedown", {
        clientX: 100,
        clientY: 100
      })
      zoomedImage.dispatchEvent(mousedownEvent)
      
      // Move mouse
      const mousemoveEvent = new MouseEvent("mousemove", {
        clientX: 150,
        clientY: 120
      })
      document.dispatchEvent(mousemoveEvent)
      
      expect(controller.translateX).toBe(50)
      expect(controller.translateY).toBe(20)
    })
    
    it("stops dragging on mouseup", () => {
      // Start drag
      const mousedownEvent = new MouseEvent("mousedown", {
        clientX: 100,
        clientY: 100
      })
      zoomedImage.dispatchEvent(mousedownEvent)
      
      expect(controller.isDragging).toBe(true)
      
      // End drag
      const mouseupEvent = new MouseEvent("mouseup")
      document.dispatchEvent(mouseupEvent)
      
      expect(controller.isDragging).toBe(false)
      expect(zoomedImage.style.cursor).toBe("grab")
    })
    
    it("does not drag when scale is 1", () => {
      controller.scale = 1
      controller.updateTransform()
      
      const mousedownEvent = new MouseEvent("mousedown", {
        clientX: 100,
        clientY: 100
      })
      zoomedImage.dispatchEvent(mousedownEvent)
      
      expect(controller.isDragging).toBeFalsy()
    })
  })
  
  describe("#updateTransform", () => {
    it("applies transform to zoomed image", () => {
      const image = element.querySelector('img[data-action]')
      image.click()
      
      const zoomedImage = element.querySelector('[data-image-zoom-target="zoomedImage"]')
      
      controller.scale = 2
      controller.translateX = 50
      controller.translateY = -30
      controller.updateTransform()
      
      expect(zoomedImage.style.transform).toBe("translate(50px, -30px) scale(2)")
    })
  })
})