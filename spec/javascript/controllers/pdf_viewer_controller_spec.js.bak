/**
 * @jest-environment jsdom
 */

import { Application } from "@hotwired/stimulus"
import PdfViewerController from "../../../app/javascript/controllers/pdf_viewer_controller"

describe("PdfViewerController", () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div data-controller="pdf-viewer">
        <iframe data-pdf-viewer-target="frame"></iframe>
        <input data-pdf-viewer-target="pageInput" type="number" value="1">
        <span data-pdf-viewer-target="totalPages">1</span>
        <select data-pdf-viewer-target="zoomSelect">
          <option value="auto">Auto</option>
          <option value="0.5">50%</option>
          <option value="1">100%</option>
          <option value="1.5">150%</option>
        </select>
        <button data-action="click->pdf-viewer#previousPage">Previous</button>
        <button data-action="click->pdf-viewer#nextPage">Next</button>
        <button data-action="click->pdf-viewer#zoomIn">Zoom In</button>
        <button data-action="click->pdf-viewer#zoomOut">Zoom Out</button>
      </div>
    `

    // Set up Stimulus
    application = Application.start()
    application.register("pdf-viewer", PdfViewerController)
    
    element = document.querySelector('[data-controller="pdf-viewer"]')
    controller = application.getControllerForElementAndIdentifier(element, "pdf-viewer")
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("connect", () => {
    it("initializes with default values", () => {
      controller.connect()
      
      expect(controller.currentPage).toBe(1)
      expect(controller.totalPages).toBe(1)
      expect(controller.currentZoom).toBe('auto')
    })

    it("sets up frame load listener", () => {
      const frame = controller.frameTarget
      const addEventListenerSpy = jest.spyOn(frame, 'addEventListener')
      
      controller.connect()
      
      expect(addEventListenerSpy).toHaveBeenCalledWith('load', expect.any(Function))
    })
  })

  describe("page navigation", () => {
    beforeEach(() => {
      controller.connect()
      controller.totalPages = 5
      controller.currentPage = 3
    })

    describe("previousPage", () => {
      it("decrements current page when not on first page", () => {
        const goToPageSpy = jest.spyOn(controller, 'goToPage')
        
        controller.previousPage()
        
        expect(controller.currentPage).toBe(2)
        expect(goToPageSpy).toHaveBeenCalled()
      })

      it("does not decrement below page 1", () => {
        controller.currentPage = 1
        
        controller.previousPage()
        
        expect(controller.currentPage).toBe(1)
      })
    })

    describe("nextPage", () => {
      it("increments current page when not on last page", () => {
        const goToPageSpy = jest.spyOn(controller, 'goToPage')
        
        controller.nextPage()
        
        expect(controller.currentPage).toBe(4)
        expect(goToPageSpy).toHaveBeenCalled()
      })

      it("does not increment beyond total pages", () => {
        controller.currentPage = 5
        
        controller.nextPage()
        
        expect(controller.currentPage).toBe(5)
      })
    })

    describe("goToPage", () => {
      it("updates current page from input value", () => {
        controller.pageInputTarget.value = "4"
        const updateDisplaySpy = jest.spyOn(controller, 'updatePageDisplay')
        
        controller.goToPage()
        
        expect(controller.currentPage).toBe(4)
        expect(updateDisplaySpy).toHaveBeenCalled()
      })

      it("ignores invalid page numbers", () => {
        controller.pageInputTarget.value = "10" // Beyond total pages
        
        controller.goToPage()
        
        expect(controller.currentPage).toBe(3) // Unchanged
      })

      it("ignores negative page numbers", () => {
        controller.pageInputTarget.value = "-1"
        
        controller.goToPage()
        
        expect(controller.currentPage).toBe(3) // Unchanged
      })
    })

    describe("updatePageDisplay", () => {
      it("updates page input value", () => {
        controller.currentPage = 2
        
        controller.updatePageDisplay()
        
        expect(controller.pageInputTarget.value).toBe("2")
      })

      it("disables previous button on first page", () => {
        controller.currentPage = 1
        const prevButton = document.querySelector('[data-action*="previousPage"]')
        
        controller.updatePageDisplay()
        
        expect(prevButton.disabled).toBe(true)
        expect(prevButton.classList.contains('opacity-50')).toBe(true)
      })

      it("disables next button on last page", () => {
        controller.currentPage = 5
        controller.totalPages = 5
        const nextButton = document.querySelector('[data-action*="nextPage"]')
        
        controller.updatePageDisplay()
        
        expect(nextButton.disabled).toBe(true)
        expect(nextButton.classList.contains('opacity-50')).toBe(true)
      })
    })
  })

  describe("zoom functionality", () => {
    beforeEach(() => {
      controller.connect()
    })

    describe("zoomIn", () => {
      it("increases zoom level", () => {
        controller.currentZoom = "1"
        const setZoomLevelSpy = jest.spyOn(controller, 'setZoomLevel')
        
        controller.zoomIn()
        
        expect(setZoomLevelSpy).toHaveBeenCalledWith(1.25)
      })

      it("caps zoom at 500%", () => {
        controller.currentZoom = "5"
        const setZoomLevelSpy = jest.spyOn(controller, 'setZoomLevel')
        
        controller.zoomIn()
        
        expect(setZoomLevelSpy).toHaveBeenCalledWith(5) // No increase
      })
    })

    describe("zoomOut", () => {
      it("decreases zoom level", () => {
        controller.currentZoom = "1"
        const setZoomLevelSpy = jest.spyOn(controller, 'setZoomLevel')
        
        controller.zoomOut()
        
        expect(setZoomLevelSpy).toHaveBeenCalledWith(0.8)
      })

      it("caps zoom at 25%", () => {
        controller.currentZoom = "0.25"
        const setZoomLevelSpy = jest.spyOn(controller, 'setZoomLevel')
        
        controller.zoomOut()
        
        expect(setZoomLevelSpy).toHaveBeenCalledWith(0.25) // No decrease
      })
    })

    describe("setZoom", () => {
      it("sets zoom from select value", () => {
        const event = { target: { value: "1.5" } }
        const setZoomLevelSpy = jest.spyOn(controller, 'setZoomLevel')
        
        controller.setZoom(event)
        
        expect(controller.currentZoom).toBe("1.5")
        expect(setZoomLevelSpy).toHaveBeenCalledWith(1.5)
      })

      it("handles special zoom values", () => {
        const event = { target: { value: "fit-width" } }
        const applySpecialZoomSpy = jest.spyOn(controller, 'applySpecialZoom')
        
        controller.setZoom(event)
        
        expect(controller.currentZoom).toBe("fit-width")
        expect(applySpecialZoomSpy).toHaveBeenCalledWith("fit-width")
      })
    })

    describe("getCurrentZoomLevel", () => {
      it("returns numeric zoom level", () => {
        controller.currentZoom = "1.5"
        
        expect(controller.getCurrentZoomLevel()).toBe(1.5)
      })

      it("returns 1 for non-numeric zoom", () => {
        controller.currentZoom = "auto"
        
        expect(controller.getCurrentZoomLevel()).toBe(1)
      })
    })

    describe("setZoomLevel", () => {
      it("updates zoom select to matching preset", () => {
        controller.setZoomLevel(1.5)
        
        expect(controller.zoomSelectTarget.value).toBe("1.5")
      })

      it("sets custom value for non-preset zoom", () => {
        controller.setZoomLevel(1.3)
        
        expect(controller.zoomSelectTarget.value).toBe("custom")
      })

      it("applies zoom to frame", () => {
        const applyZoomSpy = jest.spyOn(controller, 'applyZoom')
        
        controller.setZoomLevel(1.5)
        
        expect(applyZoomSpy).toHaveBeenCalledWith(1.5)
      })
    })

    describe("applyZoom", () => {
      it("applies transform to frame", () => {
        const frame = controller.frameTarget
        
        controller.applyZoom(1.5)
        
        expect(frame.style.transform).toBe("scale(1.5)")
        expect(frame.style.transformOrigin).toBe("top left")
      })

      it("adjusts container size", () => {
        const frame = controller.frameTarget
        const container = document.createElement('div')
        container.appendChild(frame)
        
        controller.applyZoom(1.5)
        
        expect(container.style.width).toBe("150%")
        expect(container.style.height).toBe("150%")
      })
    })
  })

  describe("fullscreen", () => {
    it("requests fullscreen on viewer container", () => {
      const viewer = document.createElement('div')
      viewer.classList.add('document-viewer-component')
      viewer.appendChild(element)
      document.body.appendChild(viewer)
      
      viewer.requestFullscreen = jest.fn(() => Promise.resolve())
      
      controller.fullscreen()
      
      expect(viewer.requestFullscreen).toHaveBeenCalled()
    })
  })

  describe("print", () => {
    it("prints frame content", () => {
      const frame = controller.frameTarget
      frame.contentWindow = {
        print: jest.fn()
      }
      
      controller.print()
      
      expect(frame.contentWindow.print).toHaveBeenCalled()
    })
  })

  describe("initializePdfViewer", () => {
    it("logs initialization message", () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {})
      
      controller.initializePdfViewer()
      
      expect(consoleSpy).toHaveBeenCalledWith('PDF viewer initialized')
    })
  })
})