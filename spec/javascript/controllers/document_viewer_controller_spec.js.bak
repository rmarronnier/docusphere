/**
 * @jest-environment jsdom
 */

import { Application } from "@hotwired/stimulus"
import DocumentViewerController from "../../../app/javascript/controllers/document_viewer_controller"

describe("DocumentViewerController", () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div data-controller="document-viewer" data-document-viewer-id-value="123">
        <button data-action="click->document-viewer#download">Download</button>
        <iframe data-document-viewer-target="frame"></iframe>
      </div>
    `

    // Set up Stimulus
    application = Application.start()
    application.register("document-viewer", DocumentViewerController)
    
    element = document.querySelector('[data-controller="document-viewer"]')
    controller = application.getControllerForElementAndIdentifier(element, "document-viewer")

    // Mock fetch for tracking
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        status: 200
      })
    )

    // Mock CSRF token
    document.head.innerHTML = '<meta name="csrf-token" content="test-token">'
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    document.head.innerHTML = ""
    jest.restoreAllMocks()
  })

  describe("connect", () => {
    it("sets up keyboard shortcuts", () => {
      const addEventListenerSpy = jest.spyOn(document, 'addEventListener')
      
      controller.connect()
      
      expect(addEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function))
    })

    it("tracks document view", () => {
      controller.connect()
      
      expect(fetch).toHaveBeenCalledWith(
        '/ged/documents/123/track_view',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'X-CSRF-Token': 'test-token',
            'Content-Type': 'application/json'
          })
        })
      )
    })
  })

  describe("keyboard shortcuts", () => {
    beforeEach(() => {
      controller.connect()
    })

    it("handles Escape key to exit fullscreen", () => {
      const exitFullscreenSpy = jest.spyOn(controller, 'exitFullscreen')
      
      // Mock fullscreen state
      controller.isFullscreen = jest.fn().mockReturnValue(true)
      
      // Trigger Escape key
      const event = new KeyboardEvent('keydown', { key: 'Escape' })
      document.dispatchEvent(event)
      
      expect(exitFullscreenSpy).toHaveBeenCalled()
    })

    it("handles Ctrl+S to download", () => {
      const downloadSpy = jest.spyOn(controller, 'download')
      
      // Trigger Ctrl+S
      const event = new KeyboardEvent('keydown', { 
        key: 's', 
        ctrlKey: true 
      })
      event.preventDefault = jest.fn()
      document.dispatchEvent(event)
      
      expect(event.preventDefault).toHaveBeenCalled()
      expect(downloadSpy).toHaveBeenCalled()
    })

    it("handles Cmd+S to download on Mac", () => {
      const downloadSpy = jest.spyOn(controller, 'download')
      
      // Trigger Cmd+S
      const event = new KeyboardEvent('keydown', { 
        key: 's', 
        metaKey: true 
      })
      event.preventDefault = jest.fn()
      document.dispatchEvent(event)
      
      expect(event.preventDefault).toHaveBeenCalled()
      expect(downloadSpy).toHaveBeenCalled()
    })

    it("handles Ctrl+P to print", () => {
      const printSpy = jest.spyOn(controller, 'print')
      
      // Trigger Ctrl+P
      const event = new KeyboardEvent('keydown', { 
        key: 'p', 
        ctrlKey: true 
      })
      event.preventDefault = jest.fn()
      document.dispatchEvent(event)
      
      expect(event.preventDefault).toHaveBeenCalled()
      expect(printSpy).toHaveBeenCalled()
    })
  })

  describe("download", () => {
    it("clicks download button if available", () => {
      const downloadButton = document.querySelector('[data-action*="download"]')
      const clickSpy = jest.spyOn(downloadButton, 'click')
      
      controller.download()
      
      expect(clickSpy).toHaveBeenCalled()
    })

    it("does nothing if no download button", () => {
      // Remove download button
      document.querySelector('[data-action*="download"]').remove()
      
      expect(() => controller.download()).not.toThrow()
    })
  })

  describe("print", () => {
    it("calls window.print", () => {
      const printSpy = jest.spyOn(window, 'print').mockImplementation(() => {})
      
      controller.print()
      
      expect(printSpy).toHaveBeenCalled()
    })
  })

  describe("fullscreen methods", () => {
    beforeEach(() => {
      // Mock fullscreen API
      element.requestFullscreen = jest.fn(() => Promise.resolve())
      document.exitFullscreen = jest.fn(() => Promise.resolve())
      
      // Mock fullscreen state
      Object.defineProperty(document, 'fullscreenElement', {
        value: null,
        writable: true
      })
    })

    describe("enterFullscreen", () => {
      it("requests fullscreen on element", () => {
        controller.enterFullscreen()
        
        expect(element.requestFullscreen).toHaveBeenCalled()
      })

      it("falls back to webkit prefix", () => {
        element.requestFullscreen = undefined
        element.webkitRequestFullscreen = jest.fn()
        
        controller.enterFullscreen()
        
        expect(element.webkitRequestFullscreen).toHaveBeenCalled()
      })

      it("falls back to ms prefix", () => {
        element.requestFullscreen = undefined
        element.webkitRequestFullscreen = undefined
        element.msRequestFullscreen = jest.fn()
        
        controller.enterFullscreen()
        
        expect(element.msRequestFullscreen).toHaveBeenCalled()
      })
    })

    describe("exitFullscreen", () => {
      it("exits fullscreen", () => {
        controller.exitFullscreen()
        
        expect(document.exitFullscreen).toHaveBeenCalled()
      })

      it("falls back to webkit prefix", () => {
        document.exitFullscreen = undefined
        document.webkitExitFullscreen = jest.fn()
        
        controller.exitFullscreen()
        
        expect(document.webkitExitFullscreen).toHaveBeenCalled()
      })

      it("falls back to ms prefix", () => {
        document.exitFullscreen = undefined
        document.webkitExitFullscreen = undefined
        document.msExitFullscreen = jest.fn()
        
        controller.exitFullscreen()
        
        expect(document.msExitFullscreen).toHaveBeenCalled()
      })
    })

    describe("isFullscreen", () => {
      it("returns true when in fullscreen", () => {
        document.fullscreenElement = element
        
        expect(controller.isFullscreen()).toBe(true)
      })

      it("returns false when not in fullscreen", () => {
        document.fullscreenElement = null
        
        expect(controller.isFullscreen()).toBe(false)
      })

      it("checks webkit prefix", () => {
        document.fullscreenElement = undefined
        document.webkitFullscreenElement = element
        
        expect(controller.isFullscreen()).toBe(true)
      })
    })

    describe("toggleFullscreen", () => {
      it("exits fullscreen when currently fullscreen", () => {
        const exitSpy = jest.spyOn(controller, 'exitFullscreen')
        controller.isFullscreen = jest.fn().mockReturnValue(true)
        
        controller.toggleFullscreen()
        
        expect(exitSpy).toHaveBeenCalled()
      })

      it("enters fullscreen when not currently fullscreen", () => {
        const enterSpy = jest.spyOn(controller, 'enterFullscreen')
        controller.isFullscreen = jest.fn().mockReturnValue(false)
        
        controller.toggleFullscreen()
        
        expect(enterSpy).toHaveBeenCalled()
      })
    })
  })

  describe("disconnect", () => {
    it("removes keyboard event listeners", () => {
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener')
      
      controller.connect()
      controller.disconnect()
      
      expect(removeEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function))
    })
  })

  describe("trackView", () => {
    it("does not track if no document ID", () => {
      element.dataset.documentViewerIdValue = ""
      
      controller.trackView()
      
      expect(fetch).not.toHaveBeenCalled()
    })

    it("handles fetch errors gracefully", () => {
      fetch.mockRejectedValueOnce(new Error('Network error'))
      
      expect(() => controller.trackView()).not.toThrow()
    })
  })
})