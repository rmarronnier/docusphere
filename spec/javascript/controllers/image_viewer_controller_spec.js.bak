import { Application } from "@hotwired/stimulus"
import ImageViewerController from "../../../app/javascript/controllers/image_viewer_controller"

describe("ImageViewerController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="image-viewer" style="width: 800px; height: 600px;">
        <img data-image-viewer-target="image" 
             src="test.jpg" 
             style="width: 400px; height: 300px;"
             naturalWidth="1200"
             naturalHeight="900" />
        <span data-image-viewer-target="zoomLevel">100%</span>
        
        <button data-action="click->image-viewer#zoomIn">Zoom In</button>
        <button data-action="click->image-viewer#zoomOut">Zoom Out</button>
        <button data-action="click->image-viewer#fit">Fit</button>
        <button data-action="click->image-viewer#actualSize">Actual Size</button>
        <button data-action="click->image-viewer#rotate">Rotate</button>
        <button data-action="click->image-viewer#flipHorizontal">Flip H</button>
        <button data-action="click->image-viewer#flipVertical">Flip V</button>
        <button data-action="click->image-viewer#previous">Previous</button>
        <button data-action="click->image-viewer#next">Next</button>
      </div>
    `
    
    application = Application.start()
    application.register("image-viewer", ImageViewerController)
    
    element = document.querySelector('[data-controller="image-viewer"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#connect", () => {
    it("initializes with default values", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      
      expect(controller.zoom).toBe(1)
      expect(controller.rotation).toBe(0)
      expect(controller.flipX).toBe(1)
      expect(controller.flipY).toBe(1)
      expect(controller.isDragging).toBe(false)
      expect(controller.translateX).toBe(0)
      expect(controller.translateY).toBe(0)
    })
    
    it("sets up event listeners", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      const wheelSpy = jest.spyOn(controller, 'handleWheel')
      const startDragSpy = jest.spyOn(controller, 'startDrag')
      
      // Re-connect to ensure listeners are added
      controller.disconnect()
      controller.connect()
      
      // Test wheel event
      const wheelEvent = new WheelEvent('wheel', { deltaY: -100, ctrlKey: true })
      element.dispatchEvent(wheelEvent)
      expect(wheelSpy).toHaveBeenCalled()
      
      // Test mousedown event
      const mousedownEvent = new MouseEvent('mousedown')
      controller.imageTarget.dispatchEvent(mousedownEvent)
      expect(startDragSpy).toHaveBeenCalled()
    })
  })
  
  describe("#disconnect", () => {
    it("removes event listeners", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      const handleWheelSpy = jest.spyOn(controller, 'handleWheel')
      
      controller.disconnect()
      
      // Wheel event should not trigger handler after disconnect
      const wheelEvent = new WheelEvent('wheel', { deltaY: -100, ctrlKey: true })
      element.dispatchEvent(wheelEvent)
      
      expect(handleWheelSpy).not.toHaveBeenCalled()
    })
  })
  
  describe("zoom functionality", () => {
    describe("#handleWheel", () => {
      it("zooms in on ctrl+wheel up", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const wheelEvent = new WheelEvent('wheel', { deltaY: -100, ctrlKey: true })
        
        element.dispatchEvent(wheelEvent)
        
        expect(controller.zoom).toBeGreaterThan(1)
      })
      
      it("zooms out on ctrl+wheel down", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const wheelEvent = new WheelEvent('wheel', { deltaY: 100, ctrlKey: true })
        
        element.dispatchEvent(wheelEvent)
        
        expect(controller.zoom).toBeLessThan(1)
      })
      
      it("prevents default behavior when zooming", () => {
        const wheelEvent = new WheelEvent('wheel', { deltaY: -100, ctrlKey: true })
        const preventDefaultSpy = jest.spyOn(wheelEvent, 'preventDefault')
        
        element.dispatchEvent(wheelEvent)
        
        expect(preventDefaultSpy).toHaveBeenCalled()
      })
      
      it("ignores wheel without ctrl/meta key", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const wheelEvent = new WheelEvent('wheel', { deltaY: -100 })
        
        element.dispatchEvent(wheelEvent)
        
        expect(controller.zoom).toBe(1)
      })
    })
    
    describe("#zoomIn", () => {
      it("increases zoom level", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const button = element.querySelector('[data-action*="zoomIn"]')
        
        button.click()
        
        expect(controller.zoom).toBe(1.25)
      })
    })
    
    describe("#zoomOut", () => {
      it("decreases zoom level", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const button = element.querySelector('[data-action*="zoomOut"]')
        
        button.click()
        
        expect(controller.zoom).toBe(0.8)
      })
    })
    
    describe("#setZoom", () => {
      it("clamps zoom between 0.1 and 5", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        
        controller.setZoom(10)
        expect(controller.zoom).toBe(5)
        
        controller.setZoom(0.01)
        expect(controller.zoom).toBe(0.1)
      })
      
      it("updates zoom display", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const zoomDisplay = element.querySelector('[data-image-viewer-target="zoomLevel"]')
        
        controller.setZoom(1.5)
        
        expect(zoomDisplay.textContent).toBe('150%')
      })
      
      it("updates transform", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const updateTransformSpy = jest.spyOn(controller, 'updateTransform')
        
        controller.setZoom(2)
        
        expect(updateTransformSpy).toHaveBeenCalled()
      })
    })
    
    describe("#fit", () => {
      it("resets zoom and position", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const button = element.querySelector('[data-action*="fit"]')
        
        // Change zoom and position
        controller.zoom = 2
        controller.translateX = 100
        controller.translateY = 50
        
        button.click()
        
        expect(controller.zoom).toBe(1)
        expect(controller.translateX).toBe(0)
        expect(controller.translateY).toBe(0)
      })
    })
    
    describe("#actualSize", () => {
      it("sets zoom to show image at natural size", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const button = element.querySelector('[data-action*="actualSize"]')
        const image = controller.imageTarget
        
        // Mock natural and display dimensions
        Object.defineProperty(image, 'naturalWidth', { value: 1200, configurable: true })
        Object.defineProperty(image, 'offsetWidth', { value: 400, configurable: true })
        
        button.click()
        
        expect(controller.zoom).toBe(3) // 1200 / 400
      })
    })
  })
  
  describe("rotation and flipping", () => {
    describe("#rotate", () => {
      it("rotates image by 90 degrees", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const button = element.querySelector('[data-action*="rotate"]')
        
        button.click()
        expect(controller.rotation).toBe(90)
        
        button.click()
        expect(controller.rotation).toBe(180)
        
        button.click()
        expect(controller.rotation).toBe(270)
        
        button.click()
        expect(controller.rotation).toBe(0)
      })
    })
    
    describe("#flipHorizontal", () => {
      it("flips image horizontally", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const button = element.querySelector('[data-action*="flipHorizontal"]')
        
        button.click()
        expect(controller.flipX).toBe(-1)
        
        button.click()
        expect(controller.flipX).toBe(1)
      })
    })
    
    describe("#flipVertical", () => {
      it("flips image vertically", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        const button = element.querySelector('[data-action*="flipVertical"]')
        
        button.click()
        expect(controller.flipY).toBe(-1)
        
        button.click()
        expect(controller.flipY).toBe(1)
      })
    })
  })
  
  describe("drag and pan", () => {
    describe("#startDrag", () => {
      it("starts dragging when zoom > 1", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        controller.zoom = 2
        controller.updateTransform()
        
        const mousedownEvent = new MouseEvent('mousedown', { clientX: 100, clientY: 100 })
        controller.imageTarget.dispatchEvent(mousedownEvent)
        
        expect(controller.isDragging).toBe(true)
        expect(controller.startX).toBe(100)
        expect(controller.startY).toBe(100)
        expect(controller.imageTarget.style.cursor).toBe('grabbing')
      })
      
      it("does not start dragging when zoom = 1", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        
        const mousedownEvent = new MouseEvent('mousedown', { clientX: 100, clientY: 100 })
        controller.imageTarget.dispatchEvent(mousedownEvent)
        
        expect(controller.isDragging).toBe(false)
      })
      
      it("prevents default behavior", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        controller.zoom = 2
        
        const mousedownEvent = new MouseEvent('mousedown', { clientX: 100, clientY: 100 })
        const preventDefaultSpy = jest.spyOn(mousedownEvent, 'preventDefault')
        
        controller.imageTarget.dispatchEvent(mousedownEvent)
        
        expect(preventDefaultSpy).toHaveBeenCalled()
      })
    })
    
    describe("#drag", () => {
      it("updates translate position while dragging", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        controller.zoom = 2
        controller.updateTransform()
        
        // Start drag
        const mousedownEvent = new MouseEvent('mousedown', { clientX: 100, clientY: 100 })
        controller.imageTarget.dispatchEvent(mousedownEvent)
        
        // Move mouse
        const mousemoveEvent = new MouseEvent('mousemove', { clientX: 150, clientY: 120 })
        document.dispatchEvent(mousemoveEvent)
        
        expect(controller.translateX).toBe(50)
        expect(controller.translateY).toBe(20)
      })
      
      it("does nothing when not dragging", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        
        const mousemoveEvent = new MouseEvent('mousemove', { clientX: 150, clientY: 120 })
        document.dispatchEvent(mousemoveEvent)
        
        expect(controller.translateX).toBe(0)
        expect(controller.translateY).toBe(0)
      })
    })
    
    describe("#endDrag", () => {
      it("stops dragging on mouseup", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        controller.zoom = 2
        controller.updateTransform()
        
        // Start drag
        const mousedownEvent = new MouseEvent('mousedown', { clientX: 100, clientY: 100 })
        controller.imageTarget.dispatchEvent(mousedownEvent)
        
        // End drag
        const mouseupEvent = new MouseEvent('mouseup')
        document.dispatchEvent(mouseupEvent)
        
        expect(controller.isDragging).toBe(false)
        expect(controller.imageTarget.style.cursor).toBe('grab')
      })
    })
  })
  
  describe("touch support", () => {
    describe("#startTouch", () => {
      it("starts dragging with single touch when zoomed", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        controller.zoom = 2
        
        const touchEvent = new TouchEvent('touchstart', {
          touches: [{ clientX: 100, clientY: 100 }]
        })
        
        controller.imageTarget.dispatchEvent(touchEvent)
        
        expect(controller.isDragging).toBe(true)
      })
      
      it("initializes pinch zoom with two touches", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        
        const touchEvent = new TouchEvent('touchstart', {
          touches: [
            { clientX: 100, clientY: 100 },
            { clientX: 200, clientY: 200 }
          ]
        })
        
        controller.imageTarget.dispatchEvent(touchEvent)
        
        expect(controller.initialPinchDistance).toBeDefined()
        expect(controller.initialZoom).toBe(1)
      })
    })
    
    describe("#touchMove", () => {
      it("updates position with single touch drag", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        controller.zoom = 2
        
        // Start touch
        const touchStartEvent = new TouchEvent('touchstart', {
          touches: [{ clientX: 100, clientY: 100 }]
        })
        controller.imageTarget.dispatchEvent(touchStartEvent)
        
        // Move touch
        const touchMoveEvent = new TouchEvent('touchmove', {
          touches: [{ clientX: 150, clientY: 120 }]
        })
        document.dispatchEvent(touchMoveEvent)
        
        expect(controller.translateX).toBe(50)
        expect(controller.translateY).toBe(20)
      })
      
      it("updates zoom with pinch gesture", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        
        // Start pinch
        const touchStartEvent = new TouchEvent('touchstart', {
          touches: [
            { clientX: 100, clientY: 100 },
            { clientX: 200, clientY: 100 }
          ]
        })
        controller.imageTarget.dispatchEvent(touchStartEvent)
        
        // Pinch out (increase distance)
        const touchMoveEvent = new TouchEvent('touchmove', {
          touches: [
            { clientX: 50, clientY: 100 },
            { clientX: 250, clientY: 100 }
          ]
        })
        document.dispatchEvent(touchMoveEvent)
        
        expect(controller.zoom).toBeGreaterThan(1)
      })
    })
    
    describe("#getPinchDistance", () => {
      it("calculates distance between two touch points", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
        
        const touches = [
          { clientX: 0, clientY: 0 },
          { clientX: 3, clientY: 4 }
        ]
        
        const distance = controller.getPinchDistance(touches)
        expect(distance).toBe(5) // 3-4-5 triangle
      })
    })
  })
  
  describe("#updateTransform", () => {
    it("applies all transformations to image", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      const image = controller.imageTarget
      
      controller.zoom = 2
      controller.rotation = 90
      controller.flipX = -1
      controller.translateX = 50
      controller.translateY = 30
      
      controller.updateTransform()
      
      expect(image.style.transform).toContain('translate(50px, 30px)')
      expect(image.style.transform).toContain('scale(-2, 2)')
      expect(image.style.transform).toContain('rotate(90deg)')
    })
    
    it("updates cursor based on zoom level", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      const image = controller.imageTarget
      
      controller.zoom = 1
      controller.updateTransform()
      expect(image.style.cursor).toBe('default')
      
      controller.zoom = 2
      controller.updateTransform()
      expect(image.style.cursor).toBe('grab')
      
      controller.isDragging = true
      controller.updateTransform()
      expect(image.style.cursor).toBe('grabbing')
    })
  })
  
  describe("#updateZoomDisplay", () => {
    it("updates zoom percentage display", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      const zoomDisplay = element.querySelector('[data-image-viewer-target="zoomLevel"]')
      
      controller.zoom = 0.5
      controller.updateZoomDisplay()
      expect(zoomDisplay.textContent).toBe('50%')
      
      controller.zoom = 2.5
      controller.updateZoomDisplay()
      expect(zoomDisplay.textContent).toBe('250%')
    })
    
    it("handles missing zoom display gracefully", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      element.querySelector('[data-image-viewer-target="zoomLevel"]').remove()
      
      // Should not throw
      expect(() => controller.updateZoomDisplay()).not.toThrow()
    })
  })
  
  describe("navigation", () => {
    describe("#previous", () => {
      it("dispatches navigation event with previous direction", () => {
        const button = element.querySelector('[data-action*="previous"]')
        let eventDetail = null
        
        element.addEventListener('image-viewer:navigate', (event) => {
          eventDetail = event.detail
        })
        
        button.click()
        
        expect(eventDetail).toEqual({ direction: 'previous' })
      })
      
      it("event bubbles up", () => {
        const button = element.querySelector('[data-action*="previous"]')
        let eventCaught = false
        
        document.body.addEventListener('image-viewer:navigate', () => {
          eventCaught = true
        })
        
        button.click()
        
        expect(eventCaught).toBe(true)
      })
    })
    
    describe("#next", () => {
      it("dispatches navigation event with next direction", () => {
        const button = element.querySelector('[data-action*="next"]')
        let eventDetail = null
        
        element.addEventListener('image-viewer:navigate', (event) => {
          eventDetail = event.detail
        })
        
        button.click()
        
        expect(eventDetail).toEqual({ direction: 'next' })
      })
    })
  })
  
  describe("edge cases", () => {
    it("handles rapid zoom changes", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      const zoomInButton = element.querySelector('[data-action*="zoomIn"]')
      
      // Rapidly click zoom in
      for (let i = 0; i < 10; i++) {
        zoomInButton.click()
      }
      
      // Should be clamped at max zoom
      expect(controller.zoom).toBe(5)
    })
    
    it("handles transform with extreme values", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      
      controller.zoom = 5
      controller.rotation = 270
      controller.flipX = -1
      controller.flipY = -1
      controller.translateX = 1000
      controller.translateY = -1000
      
      // Should not throw
      expect(() => controller.updateTransform()).not.toThrow()
    })
    
    it("handles missing image target gracefully", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "image-viewer")
      controller.imageTarget.remove()
      
      // Methods should not throw
      expect(() => controller.updateTransform()).not.toThrow()
      expect(() => controller.zoomIn()).not.toThrow()
    })
  })
})