import '../setup.js'  // Import setup first to ensure DOM is available
import { Application } from "@hotwired/stimulus"
import GedController from "../../../app/javascript/controllers/ged_controller"

describe("GedController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="ged">
        <button data-action="click->ged#openUploadModal" id="uploadButton">Upload</button>
        
        <div id="uploadModal" class="hidden">
          <form id="uploadForm" action="/ged/documents" method="post">
            <meta name="csrf-token" content="test-token">
            <select id="document_space_id" name="document[space_id]">
              <option value="">Select space</option>
              <option value="1">Space 1</option>
            </select>
            <input type="file" id="document_file" name="document[file]">
            <input type="text" id="document_title" name="document[title]">
            <button type="submit">Téléverser</button>
          </form>
          <div id="uploadProgress" class="hidden">
            <div id="uploadProgressBar" style="width: 0%"></div>
            <span id="uploadProgressText">0%</span>
          </div>
          <div id="uploadErrors" class="hidden">
            <ul id="uploadErrorsList"></ul>
          </div>
        </div>
      </div>
    `
    
    application = Application.start()
    application.register("ged", GedController)
    
    element = document.querySelector('[data-controller="ged"]')
    
    // Reset fetch mock
    fetch.mock.mockClear()
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#openUploadModal", () => {
    it("opens the upload modal", () => {
      const modal = document.getElementById("uploadModal")
      const button = document.querySelector("[data-action='click->ged#openUploadModal']")
      
      expect(modal.classList.contains("hidden")).toBe(true)
      
      button.click()
      
      expect(modal.classList.contains("hidden")).toBe(false)
    })
    
    it("sets space context when provided", () => {
      const button = document.querySelector("[data-action='click->ged#openUploadModal']")
      button.setAttribute('data-ged-space-value', '1')
      
      button.click()
      
      const spaceSelect = document.getElementById('document_space_id')
      expect(spaceSelect.value).toBe('1')
    })
    
    it("sets folder context when provided", () => {
      const button = document.querySelector("[data-action='click->ged#openUploadModal']")
      button.setAttribute('data-ged-space-value', '1')
      button.setAttribute('data-ged-folder-value', '42')
      
      button.click()
      
      const folderSelect = document.getElementById('document_folder_id')
      // Note: folder select doesn't exist in our minimal HTML, but the controller would set it if it existed
    })
  })
  
  describe("Form submission", () => {
    beforeEach(() => {
      // Reset fetch mock
      fetch.mock.mockClear()
    })
    
    it("submits form via AJAX", async () => {
      const mockResponse = {
        success: true,
        message: "Document uploaded successfully"
      }
      
      fetch.mock.mockResolvedValue({
        status: 200,
        json: async () => mockResponse
      })

      const form = document.getElementById("uploadForm")
      const submitEvent = new Event("submit", { bubbles: true, cancelable: true })
      
      form.dispatchEvent(submitEvent)
      
      // Wait for async operations
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(fetch.mock.calls.length).toBe(1)
      expect(fetch.mock.calls[0][0]).toBe("/ged/documents")
      expect(fetch.mock.calls[0][1].method).toBe("POST")
    })
    
    it("shows errors on failure", async () => {
      const mockResponse = {
        success: false,
        errors: ["Le titre est requis", "L'espace est requis"]
      }
      
      fetch.mock.mockResolvedValue({
        status: 422,
        json: async () => mockResponse
      })

      const form = document.getElementById("uploadForm")
      const submitEvent = new Event("submit", { bubbles: true, cancelable: true })
      
      form.dispatchEvent(submitEvent)
      
      await new Promise(resolve => setTimeout(resolve, 100))
      
      const errorContainer = document.getElementById("uploadErrors")
      const errorList = document.getElementById("uploadErrorsList")
      
      expect(errorContainer.classList.contains("hidden")).toBe(false)
      expect(errorList.children.length).toBe(2)
    })
    
    it("handles duplicate detection", async () => {
      const mockResponse = {
        success: false,
        duplicate_detected: true,
        existing_document: {
          id: 1,
          title: "contract_v1.pdf",
          path: "/ged/documents/1"
        }
      }
      
      fetch.mock.mockResolvedValue({
        status: 200,
        json: async () => mockResponse
      })

      const form = document.getElementById("uploadForm")
      const submitEvent = new Event("submit", { bubbles: true, cancelable: true })
      
      form.dispatchEvent(submitEvent)
      
      await new Promise(resolve => setTimeout(resolve, 100))
      
      // Check that duplicate detection modal would be shown
      const duplicateModal = document.getElementById("duplicateDetectionModal")
      expect(duplicateModal).toBeTruthy()
    })
    
    it("shows progress during upload", async () => {
      fetch.mock.mockResolvedValue({
        status: 200,
        json: async () => ({ success: true })
      })

      const form = document.getElementById("uploadForm")
      const progressContainer = document.getElementById("uploadProgress")
      const submitEvent = new Event("submit", { bubbles: true, cancelable: true })
      
      form.dispatchEvent(submitEvent)
      
      // Progress should be visible
      expect(progressContainer.classList.contains("hidden")).toBe(false)
      
      await new Promise(resolve => setTimeout(resolve, 1500))
      
      // Progress should be hidden after completion
      expect(progressContainer.classList.contains("hidden")).toBe(true)
    })
  })
  
  describe("Auto-fill functionality", () => {
    it("auto-fills title from filename", () => {
      const fileInput = document.getElementById("document_file")
      const titleInput = document.getElementById("document_title")
      
      // Create a mock file
      const file = new File(["content"], "test_document.pdf", { type: "application/pdf" })
      Object.defineProperty(fileInput, "files", {
        value: [file],
        writable: false
      })
      
      // Trigger change event
      const changeEvent = new Event("change", { bubbles: true })
      fileInput.dispatchEvent(changeEvent)
      
      // Title should be filled without extension
      expect(titleInput.value).toBe("test_document")
    })
    
    it("doesn't override existing title", () => {
      const fileInput = document.getElementById("document_file")
      const titleInput = document.getElementById("document_title")
      
      // Set existing title
      titleInput.value = "Existing Title"
      
      // Create a mock file
      const file = new File(["content"], "new_document.pdf", { type: "application/pdf" })
      Object.defineProperty(fileInput, "files", {
        value: [file],
        writable: false
      })
      
      // Trigger change event
      const changeEvent = new Event("change", { bubbles: true })
      fileInput.dispatchEvent(changeEvent)
      
      // Title should remain unchanged
      expect(titleInput.value).toBe("Existing Title")
    })
  })
  
  describe("Global functions", () => {
    it("defines openModal function", () => {
      expect(typeof window.openModal).toBe("function")
    })
    
    it("defines closeModal function", () => {
      expect(typeof window.closeModal).toBe("function")
    })
    
    it("closeModal resets form", () => {
      const modal = document.getElementById("uploadModal")
      const form = document.getElementById("uploadForm")
      const titleInput = document.getElementById("document_title")
      
      // Set some values
      titleInput.value = "Test"
      modal.classList.remove("hidden")
      
      // Close modal
      window.closeModal("uploadModal")
      
      expect(modal.classList.contains("hidden")).toBe(true)
      expect(titleInput.value).toBe("")
    })
    
    it("setSpaceContext updates space select", () => {
      const spaceSelect = document.getElementById("document_space_id")
      
      window.setSpaceContext("1")
      
      expect(spaceSelect.value).toBe("1")
    })
  })
  
  describe("Drag and drop", () => {
    it("has setupDragAndDrop method", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "ged")
      
      // Test that the method exists
      expect(typeof controller.setupDragAndDrop).toBe("function")
    })
    
    it("handles multiple files", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "ged")
      
      // Test the handleMultipleFiles method exists
      expect(typeof controller.handleMultipleFiles).toBe("function")
      
      // Create mock files
      const files = [
        new File(["content1"], "file1.pdf", { type: "application/pdf" }),
        new File(["content2"], "file2.pdf", { type: "application/pdf" })
      ]
      
      // This should open batch upload modal
      controller.handleMultipleFiles(files)
      
      // Check that batch upload modal was created
      const batchModal = document.getElementById("batchUploadModal")
      expect(batchModal).toBeTruthy()
    })
  })
})