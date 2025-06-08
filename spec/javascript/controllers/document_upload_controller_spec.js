import { Application } from "@hotwired/stimulus"
import DocumentUploadController from "../../../app/javascript/controllers/document_upload_controller"

describe("DocumentUploadController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="document-upload" 
           data-document-upload-url-value="/documents"
           data-document-upload-max-size-value="10485760">
        <div class="drop-zone" data-document-upload-target="dropZone">
          <p>Drop files here or click to browse</p>
        </div>
        <input type="file" 
               data-document-upload-target="fileInput" 
               data-action="change->document-upload#handleFileSelect"
               multiple
               hidden>
        <div data-document-upload-target="preview" class="preview-container hidden"></div>
        <div data-document-upload-target="progress" class="progress-container hidden">
          <div class="progress-bar" data-document-upload-target="progressBar"></div>
          <span data-document-upload-target="progressText">0%</span>
        </div>
        <div data-document-upload-target="errors" class="errors-container hidden"></div>
      </div>
    `
    
    application = Application.start()
    application.register("document-upload", DocumentUploadController)
    
    element = document.querySelector('[data-controller="document-upload"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("initialization", () => {
    it("sets up drop zone event listeners", () => {
      const dropZone = element.querySelector('[data-document-upload-target="dropZone"]')
      
      // Simuler dragover
      const dragOverEvent = new DragEvent('dragover', { 
        dataTransfer: new DataTransfer(),
        bubbles: true 
      })
      dropZone.dispatchEvent(dragOverEvent)
      
      expect(dropZone.classList.contains('drag-over')).toBe(true)
      
      // Simuler dragleave
      const dragLeaveEvent = new DragEvent('dragleave', { bubbles: true })
      dropZone.dispatchEvent(dragLeaveEvent)
      
      expect(dropZone.classList.contains('drag-over')).toBe(false)
    })
    
    it("opens file dialog on drop zone click", () => {
      const dropZone = element.querySelector('[data-document-upload-target="dropZone"]')
      const fileInput = element.querySelector('[data-document-upload-target="fileInput"]')
      
      const clickSpy = jest.spyOn(fileInput, 'click')
      
      dropZone.click()
      
      expect(clickSpy).toHaveBeenCalled()
    })
  })
  
  describe("file selection", () => {
    it("handles file input change", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      const fileInput = element.querySelector('[data-document-upload-target="fileInput"]')
      
      // Créer des fichiers de test
      const file1 = new File(['content1'], 'test1.pdf', { type: 'application/pdf' })
      const file2 = new File(['content2'], 'test2.docx', { type: 'application/vnd.ms-word' })
      
      // Simuler la sélection de fichiers
      Object.defineProperty(fileInput, 'files', {
        value: [file1, file2],
        writable: false
      })
      
      const changeEvent = new Event('change', { bubbles: true })
      fileInput.dispatchEvent(changeEvent)
      
      // Vérifier que les fichiers sont traités
      const preview = element.querySelector('[data-document-upload-target="preview"]')
      expect(preview.classList.contains('hidden')).toBe(false)
      expect(preview.querySelectorAll('.file-preview').length).toBe(2)
    })
    
    it("validates file size", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      const fileInput = element.querySelector('[data-document-upload-target="fileInput"]')
      
      // Fichier trop gros (> 10MB)
      const bigFile = new File(['x'.repeat(11 * 1024 * 1024)], 'big.pdf', { type: 'application/pdf' })
      
      Object.defineProperty(fileInput, 'files', {
        value: [bigFile],
        writable: false
      })
      
      fileInput.dispatchEvent(new Event('change'))
      
      const errors = element.querySelector('[data-document-upload-target="errors"]')
      expect(errors.classList.contains('hidden')).toBe(false)
      expect(errors.textContent).toContain('dépasse la taille maximale')
    })
    
    it("validates file type", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      controller.acceptedTypesValue = ['application/pdf', 'image/jpeg']
      
      const fileInput = element.querySelector('[data-document-upload-target="fileInput"]')
      const invalidFile = new File(['content'], 'test.exe', { type: 'application/x-msdownload' })
      
      Object.defineProperty(fileInput, 'files', {
        value: [invalidFile],
        writable: false
      })
      
      fileInput.dispatchEvent(new Event('change'))
      
      const errors = element.querySelector('[data-document-upload-target="errors"]')
      expect(errors.classList.contains('hidden')).toBe(false)
      expect(errors.textContent).toContain('Type de fichier non accepté')
    })
  })
  
  describe("drag and drop", () => {
    it("handles file drop", () => {
      const dropZone = element.querySelector('[data-document-upload-target="dropZone"]')
      
      const file = new File(['content'], 'dropped.pdf', { type: 'application/pdf' })
      const dt = new DataTransfer()
      dt.items.add(file)
      
      const dropEvent = new DragEvent('drop', {
        dataTransfer: dt,
        bubbles: true
      })
      
      dropZone.dispatchEvent(dropEvent)
      
      const preview = element.querySelector('[data-document-upload-target="preview"]')
      expect(preview.classList.contains('hidden')).toBe(false)
      expect(preview.querySelector('.file-preview')).toBeTruthy()
    })
    
    it("prevents default drag behavior", () => {
      const dropZone = element.querySelector('[data-document-upload-target="dropZone"]')
      
      const dragOverEvent = new DragEvent('dragover', {
        dataTransfer: new DataTransfer(),
        bubbles: true
      })
      
      const preventDefaultSpy = jest.spyOn(dragOverEvent, 'preventDefault')
      
      dropZone.dispatchEvent(dragOverEvent)
      
      expect(preventDefaultSpy).toHaveBeenCalled()
    })
  })
  
  describe("file upload", () => {
    beforeEach(() => {
      // Mock fetch
      global.fetch = jest.fn()
    })
    
    it("uploads files with progress tracking", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      const file = new File(['content'], 'upload.pdf', { type: 'application/pdf' })
      
      // Mock successful response
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ id: 1, title: 'upload.pdf' })
      })
      
      // Spy on progress update
      const updateProgressSpy = jest.spyOn(controller, 'updateProgress')
      
      await controller.uploadFile(file)
      
      expect(fetch).toHaveBeenCalledWith('/documents', expect.objectContaining({
        method: 'POST',
        body: expect.any(FormData)
      }))
      
      expect(updateProgressSpy).toHaveBeenCalled()
      
      const progress = element.querySelector('[data-document-upload-target="progress"]')
      expect(progress.classList.contains('hidden')).toBe(true) // Hidden after completion
    })
    
    it("handles upload errors", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      const file = new File(['content'], 'error.pdf', { type: 'application/pdf' })
      
      // Mock error response
      fetch.mockResolvedValueOnce({
        ok: false,
        status: 422,
        json: async () => ({ errors: { file: ['is invalid'] } })
      })
      
      await controller.uploadFile(file)
      
      const errors = element.querySelector('[data-document-upload-target="errors"]')
      expect(errors.classList.contains('hidden')).toBe(false)
      expect(errors.textContent).toContain('Erreur')
    })
    
    it("supports multiple file upload", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      
      const files = [
        new File(['content1'], 'file1.pdf', { type: 'application/pdf' }),
        new File(['content2'], 'file2.pdf', { type: 'application/pdf' })
      ]
      
      fetch.mockResolvedValue({
        ok: true,
        json: async () => ({ id: Date.now(), title: 'file.pdf' })
      })
      
      await controller.uploadFiles(files)
      
      expect(fetch).toHaveBeenCalledTimes(2)
    })
  })
  
  describe("preview generation", () => {
    it("shows image preview for image files", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      const imageFile = new File([''], 'image.jpg', { type: 'image/jpeg' })
      
      // Mock FileReader
      const mockFileReader = {
        readAsDataURL: jest.fn(),
        addEventListener: jest.fn((event, handler) => {
          if (event === 'load') {
            mockFileReader.result = 'data:image/jpeg;base64,mock'
            handler()
          }
        })
      }
      
      jest.spyOn(window, 'FileReader').mockImplementation(() => mockFileReader)
      
      controller.addFilePreview(imageFile)
      
      const preview = element.querySelector('[data-document-upload-target="preview"]')
      const img = preview.querySelector('img')
      
      expect(img).toBeTruthy()
      expect(img.src).toBe('data:image/jpeg;base64,mock')
    })
    
    it("shows icon for non-image files", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      const pdfFile = new File([''], 'document.pdf', { type: 'application/pdf' })
      
      controller.addFilePreview(pdfFile)
      
      const preview = element.querySelector('[data-document-upload-target="preview"]')
      const icon = preview.querySelector('.file-icon')
      
      expect(icon).toBeTruthy()
      expect(icon.classList.contains('icon-pdf')).toBe(true)
    })
  })
  
  describe("file removal", () => {
    it("removes file from preview", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      const file = new File([''], 'test.pdf', { type: 'application/pdf' })
      
      controller.addFilePreview(file)
      
      const preview = element.querySelector('[data-document-upload-target="preview"]')
      const removeButton = preview.querySelector('.remove-file')
      
      removeButton.click()
      
      expect(preview.querySelector('.file-preview')).toBeFalsy()
    })
  })
  
  describe("chunked upload", () => {
    it("uploads large files in chunks", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      controller.chunkSizeValue = 1024 * 1024 // 1MB chunks
      
      // Create a 3MB file
      const largeFile = new File(['x'.repeat(3 * 1024 * 1024)], 'large.pdf', { type: 'application/pdf' })
      
      fetch.mockResolvedValue({
        ok: true,
        json: async () => ({ chunk: 'received' })
      })
      
      await controller.uploadLargeFile(largeFile)
      
      // Should be called 3 times (3 chunks)
      expect(fetch).toHaveBeenCalledTimes(3)
      
      // Verify chunk headers
      expect(fetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'X-Chunk-Index': expect.any(String),
            'X-Total-Chunks': '3'
          })
        })
      )
    })
  })
  
  describe("accessibility", () => {
    it("provides keyboard navigation for drop zone", () => {
      const dropZone = element.querySelector('[data-document-upload-target="dropZone"]')
      const fileInput = element.querySelector('[data-document-upload-target="fileInput"]')
      
      // Add tabindex for test
      dropZone.setAttribute('tabindex', '0')
      dropZone.focus()
      
      const enterEvent = new KeyboardEvent('keydown', { key: 'Enter' })
      const clickSpy = jest.spyOn(fileInput, 'click')
      
      dropZone.dispatchEvent(enterEvent)
      
      expect(clickSpy).toHaveBeenCalled()
    })
    
    it("announces upload progress to screen readers", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-upload")
      
      controller.updateProgress(50)
      
      const progressText = element.querySelector('[data-document-upload-target="progressText"]')
      expect(progressText.getAttribute('aria-live')).toBe('polite')
      expect(progressText.textContent).toBe('50%')
    })
  })
})