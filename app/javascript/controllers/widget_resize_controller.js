import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["handle", "widget"]
  static values = { 
    minWidth: { type: Number, default: 1 },
    maxWidth: { type: Number, default: 4 },
    minHeight: { type: Number, default: 1 },
    maxHeight: { type: Number, default: 4 },
    gridSize: { type: Number, default: 320 } // Base grid size in pixels
  }
  
  connect() {
    this.isResizing = false
    this.startSize = {}
    this.startPos = {}
    
    // Add resize handles if not present
    if (!this.hasHandleTarget) {
      this.addResizeHandles()
    }
  }
  
  addResizeHandles() {
    const handles = ['e', 'se', 's'] // East, Southeast, South
    
    handles.forEach(direction => {
      const handle = document.createElement('div')
      handle.classList.add('resize-handle', `resize-${direction}`)
      handle.dataset.widgetResizeTarget = 'handle'
      handle.dataset.direction = direction
      handle.addEventListener('mousedown', this.startResize.bind(this))
      handle.addEventListener('touchstart', this.startResize.bind(this))
      
      this.element.appendChild(handle)
    })
  }
  
  startResize(event) {
    event.preventDefault()
    event.stopPropagation()
    
    this.isResizing = true
    this.direction = event.currentTarget.dataset.direction
    
    // Get initial dimensions
    const widget = this.widgetTarget || this.element
    const computedStyle = window.getComputedStyle(widget)
    
    this.startSize = {
      width: parseInt(widget.dataset.widgetWidth || 1),
      height: parseInt(widget.dataset.widgetHeight || 1)
    }
    
    this.startPos = {
      x: event.pageX || event.touches[0].pageX,
      y: event.pageY || event.touches[0].pageY
    }
    
    // Calculate grid cell size based on container
    const container = widget.closest('.dashboard-widgets')
    if (container) {
      const containerWidth = container.offsetWidth
      const gap = parseInt(window.getComputedStyle(container).gap) || 16
      const columns = 4 // Default grid columns
      this.cellWidth = (containerWidth - (gap * (columns - 1))) / columns
      this.cellHeight = this.gridSizeValue // Fixed height
    }
    
    // Add global listeners
    document.addEventListener('mousemove', this.resize.bind(this))
    document.addEventListener('mouseup', this.stopResize.bind(this))
    document.addEventListener('touchmove', this.resize.bind(this))
    document.addEventListener('touchend', this.stopResize.bind(this))
    
    // Add resizing class
    document.body.classList.add('widget-resizing')
    widget.classList.add('resizing')
    
    // Dispatch start event
    this.dispatch("resize-start", { 
      detail: { 
        widget,
        startSize: this.startSize 
      } 
    })
  }
  
  resize(event) {
    if (!this.isResizing) return
    
    const currentX = event.pageX || event.touches[0].pageX
    const currentY = event.pageY || event.touches[0].pageY
    
    const deltaX = currentX - this.startPos.x
    const deltaY = currentY - this.startPos.y
    
    // Calculate new size in grid units
    let newWidth = this.startSize.width
    let newHeight = this.startSize.height
    
    if (this.direction.includes('e')) {
      // Resizing width
      const widthChange = Math.round(deltaX / this.cellWidth)
      newWidth = Math.max(this.minWidthValue, Math.min(this.maxWidthValue, this.startSize.width + widthChange))
    }
    
    if (this.direction.includes('s')) {
      // Resizing height
      const heightChange = Math.round(deltaY / this.cellHeight)
      newHeight = Math.max(this.minHeightValue, Math.min(this.maxHeightValue, this.startSize.height + heightChange))
    }
    
    // Update visual preview
    const widget = this.widgetTarget || this.element
    widget.style.gridColumn = `span ${newWidth}`
    widget.style.gridRow = `span ${newHeight}`
    
    // Store temp values
    this.tempSize = { width: newWidth, height: newHeight }
    
    // Dispatch resize event
    this.dispatch("resize", { 
      detail: { 
        widget,
        width: newWidth,
        height: newHeight 
      } 
    })
  }
  
  stopResize(event) {
    if (!this.isResizing) return
    
    this.isResizing = false
    
    // Remove global listeners
    document.removeEventListener('mousemove', this.resize.bind(this))
    document.removeEventListener('mouseup', this.stopResize.bind(this))
    document.removeEventListener('touchmove', this.resize.bind(this))
    document.removeEventListener('touchend', this.stopResize.bind(this))
    
    // Remove classes
    document.body.classList.remove('widget-resizing')
    const widget = this.widgetTarget || this.element
    widget.classList.remove('resizing')
    
    // Save new size if changed
    if (this.tempSize && 
        (this.tempSize.width !== this.startSize.width || 
         this.tempSize.height !== this.startSize.height)) {
      
      // Update data attributes
      widget.dataset.widgetWidth = this.tempSize.width
      widget.dataset.widgetHeight = this.tempSize.height
      
      // Dispatch save event
      this.dispatch("resize-end", { 
        detail: { 
          widget,
          widgetId: widget.dataset.widgetId,
          width: this.tempSize.width,
          height: this.tempSize.height 
        },
        target: widget.closest("[data-controller*='dashboard']")
      })
    }
    
    // Clear temp values
    this.tempSize = null
  }
}