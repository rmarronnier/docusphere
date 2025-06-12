import { Application } from "@hotwired/stimulus"
import DocumentPreviewController from "../../../app/javascript/controllers/document_preview_controller"

describe("DocumentPreviewController", () => {
  let application
  let controller
  let element
  
  beforeEach(() => {
    application = Application.start()
    application.register("document-preview", DocumentPreviewController)
    
    document.body.innerHTML = `
      <div data-controller="document-preview" data-document-preview-id-value="123">
        <button data-action="click->document-preview#open" data-document-id="456">Open Preview</button>
        
        <div class="fixed inset-0 z-50 overflow-y-auto hidden" data-document-preview-target="modal">
          <div class="fixed inset-0 bg-black bg-opacity-75" data-document-preview-target="backdrop"></div>
          
          <div class="relative" data-document-preview-target="content">
            <button data-action="click->document-preview#close">Close</button>
            
            <div data-document-preview-target="viewer">
              <!-- Content will be loaded here -->
            </div>
            
            <div class="hidden" data-document-preview-target="loading">Loading...</div>
            <div class="hidden" data-document-preview-target="error">Error</div>
            
            <button data-action="click->document-preview#share">Share</button>
          </div>
        </div>
      </div>
    `
    
    element = document.querySelector('[data-controller="document-preview"]')
    controller = application.getControllerForElementAndIdentifier(element, "document-preview")
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#open", () => {
    it("shows the modal", () => {
      const modal = element.querySelector('[data-document-preview-target="modal"]')
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      
      expect(modal.classList.contains("hidden")).toBe(true)
      
      button.click()
      
      expect(modal.classList.contains("hidden")).toBe(false)
      expect(document.body.classList.contains("overflow-hidden")).toBe(true)
    })
    
    it("updates document ID from button data attribute", () => {
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      
      expect(controller.idValue).toBe(123)
      
      button.click()
      
      expect(controller.idValue).toBe(456)
    })
    
    it("prevents default action", () => {
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      const event = new MouseEvent("click", { cancelable: true })
      
      button.dispatchEvent(event)
      
      expect(event.defaultPrevented).toBe(true)
    })
  })
  
  describe("#close", () => {
    beforeEach(() => {
      // Open modal first
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      button.click()
    })
    
    it("hides the modal", (done) => {
      const modal = element.querySelector('[data-document-preview-target="modal"]')
      const closeButton = element.querySelector('[data-action="click->document-preview#close"]')
      
      expect(modal.classList.contains("hidden")).toBe(false)
      
      closeButton.click()
      
      // Wait for animation to complete
      setTimeout(() => {
        expect(modal.classList.contains("hidden")).toBe(true)
        expect(document.body.classList.contains("overflow-hidden")).toBe(false)
        done()
      }, 350)
    })
    
    it("clears viewer content", (done) => {
      const viewer = element.querySelector('[data-document-preview-target="viewer"]')
      viewer.innerHTML = "<p>Some content</p>"
      
      const closeButton = element.querySelector('[data-action="click->document-preview#close"]')
      closeButton.click()
      
      setTimeout(() => {
        expect(viewer.innerHTML).toBe("")
        done()
      }, 350)
    })
  })
  
  describe("#closeOnBackdrop", () => {
    beforeEach(() => {
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      button.click()
    })
    
    it("closes when clicking on backdrop", (done) => {
      const modal = element.querySelector('[data-document-preview-target="modal"]')
      modal.click()
      
      setTimeout(() => {
        expect(modal.classList.contains("hidden")).toBe(true)
        done()
      }, 350)
    })
    
    it("does not close when clicking on content", () => {
      const modal = element.querySelector('[data-document-preview-target="modal"]')
      const content = element.querySelector('[data-document-preview-target="content"]')
      
      content.click()
      
      expect(modal.classList.contains("hidden")).toBe(false)
    })
  })
  
  describe("keyboard navigation", () => {
    beforeEach(() => {
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      button.click()
    })
    
    it("closes on Escape key", (done) => {
      const modal = element.querySelector('[data-document-preview-target="modal"]')
      
      const escapeEvent = new KeyboardEvent("keydown", { key: "Escape" })
      document.dispatchEvent(escapeEvent)
      
      setTimeout(() => {
        expect(modal.classList.contains("hidden")).toBe(true)
        done()
      }, 350)
    })
  })
  
  describe("#loadPreview", () => {
    beforeEach(() => {
      global.fetch = jest.fn()
    })
    
    afterEach(() => {
      jest.restoreAllMocks()
    })
    
    it("shows loading state while fetching", async () => {
      const loading = element.querySelector('[data-document-preview-target="loading"]')
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      button.dataset.previewUrl = "/preview/123"
      
      fetch.mockResolvedValueOnce({
        ok: true,
        text: () => Promise.resolve("<p>Preview content</p>")
      })
      
      button.click()
      
      // Loading should be visible immediately
      expect(loading.classList.contains("hidden")).toBe(false)
    })
    
    it("updates viewer content on success", async () => {
      const viewer = element.querySelector('[data-document-preview-target="viewer"]')
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      button.dataset.previewUrl = "/preview/123"
      
      fetch.mockResolvedValueOnce({
        ok: true,
        text: () => Promise.resolve("<p>Preview content</p>")
      })
      
      button.click()
      
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(viewer.innerHTML).toBe("<p>Preview content</p>")
    })
    
    it("shows error state on failure", async () => {
      const error = element.querySelector('[data-document-preview-target="error"]')
      const button = element.querySelector('[data-action="click->document-preview#open"]')
      button.dataset.previewUrl = "/preview/123"
      
      fetch.mockRejectedValueOnce(new Error("Network error"))
      
      button.click()
      
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(error.classList.contains("hidden")).toBe(false)
    })
  })
  
  describe("#share", () => {
    it("dispatches share event", () => {
      const shareButton = element.querySelector('[data-action="click->document-preview#share"]')
      let eventDispatched = false
      let eventDetail = null
      
      element.addEventListener("document-preview:share", (event) => {
        eventDispatched = true
        eventDetail = event.detail
      })
      
      shareButton.click()
      
      expect(eventDispatched).toBe(true)
      expect(eventDetail.documentId).toBe(123)
    })
  })
})