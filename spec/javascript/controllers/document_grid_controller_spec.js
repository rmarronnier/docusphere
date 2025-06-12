import '../setup.js'
import { Application } from "@hotwired/stimulus"
import DocumentGridController from "../../../app/javascript/controllers/document_grid_controller"

describe("DocumentGridController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="document-grid"
           data-document-grid-selected-value='["1", "2"]'
           data-document-grid-view-mode-value="list">
        
        <!-- Selection controls -->
        <button data-action="click->document-grid#selectAll">Select All</button>
        <button data-action="click->document-grid#deselectAll">Deselect All</button>
        
        <!-- View mode buttons -->
        <button data-view-mode="grid" 
                data-action="click->document-grid#changeViewMode"
                class="text-gray-500">
          Grid View
        </button>
        <button data-view-mode="list" 
                data-action="click->document-grid#changeViewMode"
                class="bg-gray-100 text-gray-900">
          List View
        </button>
        
        <!-- Document items -->
        <div data-document-id="1" 
             data-action="dragstart->document-grid#dragStart dragend->document-grid#dragEnd"
             draggable="true">
          <input type="checkbox" value="1" checked data-action="change->document-grid#toggleSelection">
          <button data-action="click->document-grid#quickPreview">Preview</button>
        </div>
        
        <div data-document-id="2" 
             data-action="dragstart->document-grid#dragStart dragend->document-grid#dragEnd"
             draggable="true">
          <input type="checkbox" value="2" checked data-action="change->document-grid#toggleSelection">
          <button data-action="click->document-grid#quickPreview">Preview</button>
        </div>
        
        <div data-document-id="3"
             data-action="dragstart->document-grid#dragStart dragend->document-grid#dragEnd"
             draggable="true">
          <input type="checkbox" value="3" data-action="change->document-grid#toggleSelection">
          <button data-action="click->document-grid#quickPreview">Preview</button>
        </div>
        
        <!-- Folder drop target -->
        <div data-folder-id="folder-1" 
             data-action="dragover->document-grid#dragOver drop->document-grid#drop">
          Drop folder
        </div>
        
        <!-- Bulk actions -->
        <div data-bulk-actions class="hidden">
          <span data-selection-count>0</span> selected
          <button data-action="click->document-grid#batchDownload">Download</button>
          <button data-action="click->document-grid#batchDelete">Delete</button>
          <button data-action="click->document-grid#batchMove">Move</button>
        </div>
      </div>
    `
    
    application = Application.start()
    application.register("document-grid", DocumentGridController)
    
    element = document.querySelector('[data-controller="document-grid"]')
    
    // Mock confirm
    window.confirm = jest.fn()
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    window.confirm = undefined
  })
  
  describe("connect", () => {
    it("initializes with provided values", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      
      controller.connect()
      
      expect(controller.selectedValue).toEqual(['1', '2'])
      expect(controller.viewModeValue).toBe('list')
    })
    
    it("initializes with defaults when no values provided", () => {
      document.body.innerHTML = `
        <div data-controller="document-grid">
        </div>
      `
      
      const element = document.querySelector('[data-controller="document-grid"]')
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      
      controller.connect()
      
      expect(controller.selectedValue).toEqual([])
      expect(controller.viewModeValue).toBe('grid')
    })
  })
  
  describe("#toggleSelection", () => {
    it("adds document to selection when checked", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      controller.selectedValue = ['1', '2'] // Reset to initial state
      
      const checkbox = element.querySelector('input[value="3"]')
      checkbox.checked = true
      
      const event = new Event('change')
      Object.defineProperty(event, 'target', { value: checkbox, enumerable: true })
      
      const eventHandler = jest.fn()
      element.addEventListener('document-grid:selection-changed', eventHandler)
      
      controller.toggleSelection(event)
      
      expect(controller.selectedValue).toEqual(['1', '2', '3'])
      expect(eventHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { selected: ['1', '2', '3'] }
        })
      )
    })
    
    it("removes document from selection when unchecked", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      controller.selectedValue = ['1', '2']
      
      const checkbox = element.querySelector('input[value="2"]')
      checkbox.checked = false
      
      const event = new Event('change')
      Object.defineProperty(event, 'target', { value: checkbox, enumerable: true })
      
      controller.toggleSelection(event)
      
      expect(controller.selectedValue).toEqual(['1'])
    })
    
    it("updates selection UI", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      const updateSpy = jest.spyOn(controller, 'updateSelectionUI')
      
      const checkbox = element.querySelector('input[value="3"]')
      checkbox.checked = true
      
      const event = new Event('change')
      Object.defineProperty(event, 'target', { value: checkbox, enumerable: true })
      
      controller.toggleSelection(event)
      
      expect(updateSpy).toHaveBeenCalled()
    })
  })
  
  describe("#selectAll", () => {
    it("selects all checkboxes and updates selection", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      const eventHandler = jest.fn()
      element.addEventListener('document-grid:selection-changed', eventHandler)
      
      controller.selectAll()
      
      const checkboxes = element.querySelectorAll('input[type="checkbox"]')
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(true)
      })
      
      expect(controller.selectedValue).toEqual(['1', '2', '3'])
      expect(eventHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { selected: ['1', '2', '3'] }
        })
      )
    })
  })
  
  describe("#deselectAll", () => {
    it("deselects all checkboxes and clears selection", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      controller.selectedValue = ['1', '2', '3']
      
      const eventHandler = jest.fn()
      element.addEventListener('document-grid:selection-changed', eventHandler)
      
      controller.deselectAll()
      
      const checkboxes = element.querySelectorAll('input[type="checkbox"]')
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(false)
      })
      
      expect(controller.selectedValue).toEqual([])
      expect(eventHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { selected: [] }
        })
      )
    })
  })
  
  describe("#updateSelectionUI", () => {
    it("updates selection count display", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      controller.selectedValue = ['1', '2', '3']
      
      controller.updateSelectionUI()
      
      const countElement = document.querySelector('[data-selection-count]')
      expect(countElement.textContent).toBe('3')
    })
    
    it("shows bulk actions when items selected", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      controller.selectedValue = ['1']
      
      controller.updateSelectionUI()
      
      const bulkActions = document.querySelector('[data-bulk-actions]')
      expect(bulkActions.classList.contains('hidden')).toBe(false)
    })
    
    it("hides bulk actions when no items selected", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      controller.selectedValue = []
      
      const bulkActions = document.querySelector('[data-bulk-actions]')
      bulkActions.classList.remove('hidden') // Make it visible first
      
      controller.updateSelectionUI()
      
      expect(bulkActions.classList.contains('hidden')).toBe(true)
    })
  })
  
  describe("#changeViewMode", () => {
    it("changes view mode and dispatches event", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      const eventHandler = jest.fn()
      element.addEventListener('document-grid:view-mode-changed', eventHandler)
      
      const gridButton = element.querySelector('[data-view-mode="grid"]')
      const event = new Event('click')
      Object.defineProperty(event, 'currentTarget', { value: gridButton, enumerable: true })
      
      controller.changeViewMode(event)
      
      expect(controller.viewModeValue).toBe('grid')
      expect(eventHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { viewMode: 'grid' }
        })
      )
    })
    
    it("updates button active states", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      
      const gridButton = element.querySelector('[data-view-mode="grid"]')
      const listButton = element.querySelector('[data-view-mode="list"]')
      
      const event = new Event('click')
      Object.defineProperty(event, 'currentTarget', { value: gridButton, enumerable: true })
      
      controller.changeViewMode(event)
      
      expect(gridButton.classList.contains('bg-gray-100')).toBe(true)
      expect(gridButton.classList.contains('text-gray-900')).toBe(true)
      expect(gridButton.classList.contains('text-gray-500')).toBe(false)
      
      expect(listButton.classList.contains('bg-gray-100')).toBe(false)
      expect(listButton.classList.contains('text-gray-900')).toBe(false)
      expect(listButton.classList.contains('text-gray-500')).toBe(true)
    })
  })
  
  describe("drag and drop", () => {
    describe("#dragStart", () => {
      it("sets drag data and adds opacity", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        const draggable = element.querySelector('[data-document-id="1"]')
        
        const dataTransfer = {
          effectAllowed: '',
          setData: jest.fn()
        }
        
        const event = new DragEvent('dragstart')
        Object.defineProperty(event, 'currentTarget', { value: draggable, enumerable: true })
        Object.defineProperty(event, 'dataTransfer', { value: dataTransfer, enumerable: true })
        
        controller.dragStart(event)
        
        expect(dataTransfer.effectAllowed).toBe('move')
        expect(dataTransfer.setData).toHaveBeenCalledWith('documentId', '1')
        expect(draggable.classList.contains('opacity-50')).toBe(true)
      })
    })
    
    describe("#dragEnd", () => {
      it("removes opacity class", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        const draggable = element.querySelector('[data-document-id="1"]')
        draggable.classList.add('opacity-50')
        
        const event = new DragEvent('dragend')
        Object.defineProperty(event, 'currentTarget', { value: draggable, enumerable: true })
        
        controller.dragEnd(event)
        
        expect(draggable.classList.contains('opacity-50')).toBe(false)
      })
    })
    
    describe("#dragOver", () => {
      it("prevents default and sets drop effect", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        
        const dataTransfer = {
          dropEffect: ''
        }
        
        const event = new DragEvent('dragover')
        event.preventDefault = jest.fn()
        Object.defineProperty(event, 'dataTransfer', { value: dataTransfer, enumerable: true })
        
        controller.dragOver(event)
        
        expect(event.preventDefault).toHaveBeenCalled()
        expect(dataTransfer.dropEffect).toBe('move')
      })
    })
    
    describe("#drop", () => {
      it("dispatches document-dropped event", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        const dropTarget = element.querySelector('[data-folder-id="folder-1"]')
        
        const dataTransfer = {
          getData: jest.fn().mockReturnValue('2')
        }
        
        const event = new DragEvent('drop')
        event.preventDefault = jest.fn()
        Object.defineProperty(event, 'currentTarget', { value: dropTarget, enumerable: true })
        Object.defineProperty(event, 'dataTransfer', { value: dataTransfer, enumerable: true })
        
        const eventHandler = jest.fn()
        element.addEventListener('document-grid:document-dropped', eventHandler)
        
        controller.drop(event)
        
        expect(event.preventDefault).toHaveBeenCalled()
        expect(dataTransfer.getData).toHaveBeenCalledWith('documentId')
        expect(eventHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            detail: { documentId: '2', targetId: 'folder-1' }
          })
        )
      })
    })
  })
  
  describe("#quickPreview", () => {
    it("dispatches quick-preview event", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      const previewButton = element.querySelector('[data-document-id="1"] button')
      
      const event = new Event('click')
      event.preventDefault = jest.fn()
      Object.defineProperty(event, 'currentTarget', { 
        value: Object.assign(previewButton, { dataset: { documentId: '1' } }),
        enumerable: true 
      })
      
      const eventHandler = jest.fn()
      element.addEventListener('document-grid:quick-preview', eventHandler)
      
      controller.quickPreview(event)
      
      expect(event.preventDefault).toHaveBeenCalled()
      expect(eventHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { documentId: '1' }
        })
      )
    })
  })
  
  describe("batch operations", () => {
    describe("#batchDownload", () => {
      it("dispatches batch-download event with selected documents", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        controller.selectedValue = ['1', '2', '3']
        
        const eventHandler = jest.fn()
        element.addEventListener('document-grid:batch-download', eventHandler)
        
        controller.batchDownload()
        
        expect(eventHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            detail: { documentIds: ['1', '2', '3'] }
          })
        )
      })
      
      it("does nothing when no documents selected", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        controller.selectedValue = []
        
        const eventHandler = jest.fn()
        element.addEventListener('document-grid:batch-download', eventHandler)
        
        controller.batchDownload()
        
        expect(eventHandler).not.toHaveBeenCalled()
      })
    })
    
    describe("#batchDelete", () => {
      it("confirms and dispatches batch-delete event", () => {
        window.confirm.mockReturnValue(true)
        
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        controller.selectedValue = ['1', '2']
        
        const eventHandler = jest.fn()
        element.addEventListener('document-grid:batch-delete', eventHandler)
        
        controller.batchDelete()
        
        expect(window.confirm).toHaveBeenCalledWith('Are you sure you want to delete 2 documents?')
        expect(eventHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            detail: { documentIds: ['1', '2'] }
          })
        )
      })
      
      it("cancels when user declines confirmation", () => {
        window.confirm.mockReturnValue(false)
        
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        controller.selectedValue = ['1', '2']
        
        const eventHandler = jest.fn()
        element.addEventListener('document-grid:batch-delete', eventHandler)
        
        controller.batchDelete()
        
        expect(eventHandler).not.toHaveBeenCalled()
      })
      
      it("does nothing when no documents selected", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        controller.selectedValue = []
        
        controller.batchDelete()
        
        expect(window.confirm).not.toHaveBeenCalled()
      })
    })
    
    describe("#batchMove", () => {
      it("dispatches batch-move event with selected documents", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        controller.selectedValue = ['1', '2', '3']
        
        const eventHandler = jest.fn()
        element.addEventListener('document-grid:batch-move', eventHandler)
        
        controller.batchMove()
        
        expect(eventHandler).toHaveBeenCalledWith(
          expect.objectContaining({
            detail: { documentIds: ['1', '2', '3'] }
          })
        )
      })
      
      it("does nothing when no documents selected", () => {
        const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
        controller.selectedValue = []
        
        const eventHandler = jest.fn()
        element.addEventListener('document-grid:batch-move', eventHandler)
        
        controller.batchMove()
        
        expect(eventHandler).not.toHaveBeenCalled()
      })
    })
  })
  
  describe("edge cases", () => {
    it("handles missing elements gracefully", () => {
      document.body.innerHTML = `
        <div data-controller="document-grid">
          <!-- No bulk actions or selection count elements -->
        </div>
      `
      
      const element = document.querySelector('[data-controller="document-grid"]')
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      controller.selectedValue = ['1', '2']
      
      // Should not throw
      expect(() => controller.updateSelectionUI()).not.toThrow()
    })
    
    it("handles concurrent selection changes", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-grid")
      
      // Simulate rapid selection changes
      const checkbox1 = element.querySelector('input[value="1"]')
      const checkbox3 = element.querySelector('input[value="3"]')
      
      checkbox1.checked = false
      checkbox3.checked = true
      
      const event1 = new Event('change')
      Object.defineProperty(event1, 'target', { value: checkbox1, enumerable: true })
      
      const event3 = new Event('change')
      Object.defineProperty(event3, 'target', { value: checkbox3, enumerable: true })
      
      controller.toggleSelection(event1)
      controller.toggleSelection(event3)
      
      expect(controller.selectedValue).toEqual(['2', '3'])
    })
  })
})