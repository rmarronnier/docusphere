import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["container", "widget"]
  static values = { 
    handle: String,
    animation: { type: Number, default: 150 },
    ghostClass: { type: String, default: "sortable-ghost" },
    dragClass: { type: String, default: "sortable-drag" },
    chosenClass: { type: String, default: "sortable-chosen" }
  }
  
  connect() {
    this.initializeSortable()
    // Start with sortable disabled
    this.disable()
  }
  
  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }
  
  initializeSortable() {
    const options = {
      animation: this.animationValue,
      handle: this.handleValue || ".widget-drag-handle",
      draggable: ".dashboard-widget",
      ghostClass: this.ghostClassValue,
      dragClass: this.dragClassValue,
      chosenClass: this.chosenClassValue,
      
      // Enable auto-scrolling
      scroll: true,
      scrollSensitivity: 30,
      scrollSpeed: 10,
      
      // Grid layout support
      forceFallback: true,
      
      // Events
      onStart: this.onStart.bind(this),
      onEnd: this.onEnd.bind(this),
      onChange: this.onChange.bind(this)
    }
    
    this.sortable = new Sortable(this.containerTarget, options)
  }
  
  onStart(event) {
    // Add dragging class to body for global styling
    document.body.classList.add("dashboard-dragging")
    
    // Dispatch event
    this.dispatch("drag-start", { 
      detail: { 
        item: event.item,
        index: event.oldIndex 
      } 
    })
  }
  
  onEnd(event) {
    // Remove dragging class from body
    document.body.classList.remove("dashboard-dragging")
    
    // Dispatch event
    this.dispatch("drag-end", { 
      detail: { 
        item: event.item,
        oldIndex: event.oldIndex,
        newIndex: event.newIndex 
      } 
    })
    
    // Only save if position actually changed
    if (event.oldIndex !== event.newIndex) {
      this.saveOrder()
    }
  }
  
  onChange(event) {
    // Dispatch event for real-time updates
    this.dispatch("drag-change", { 
      detail: { 
        item: event.item,
        oldIndex: event.oldIndex,
        newIndex: event.newIndex 
      } 
    })
  }
  
  saveOrder() {
    const widgetIds = Array.from(this.widgetTargets).map(widget => {
      return widget.dataset.widgetId
    })
    
    // Dispatch to dashboard controller
    this.dispatch("reorder-widgets", { 
      detail: { widgetIds },
      target: this.element.closest("[data-controller*='dashboard']")
    })
  }
  
  // Public methods for external control
  enable() {
    if (this.sortable) {
      this.sortable.option("disabled", false)
    }
  }
  
  disable() {
    if (this.sortable) {
      this.sortable.option("disabled", true)
    }
  }
  
  toggleEdit() {
    const isEditing = this.element.dataset.editing === "true"
    
    if (isEditing) {
      this.exitEditMode()
    } else {
      this.enterEditMode()
    }
  }
  
  enterEditMode() {
    this.element.dataset.editing = "true"
    this.element.classList.add("edit-mode")
    
    // Show drag handles
    this.widgetTargets.forEach(widget => {
      widget.classList.add("draggable")
    })
    
    // Enable sorting
    this.enable()
    
    // Dispatch event
    this.dispatch("edit-mode-entered")
  }
  
  exitEditMode() {
    this.element.dataset.editing = "false"
    this.element.classList.remove("edit-mode")
    
    // Hide drag handles
    this.widgetTargets.forEach(widget => {
      widget.classList.remove("draggable")
    })
    
    // Disable sorting
    this.disable()
    
    // Dispatch event
    this.dispatch("edit-mode-exited")
  }
}