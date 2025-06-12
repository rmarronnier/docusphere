import { expect, describe, it, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import DashboardSortableController from '../../../app/javascript/controllers/dashboard_sortable_controller'

// Mock Sortablejs
vi.mock('sortablejs', () => {
  return {
    default: vi.fn().mockImplementation(() => ({
      destroy: vi.fn(),
      option: vi.fn()
    }))
  }
})

describe('DashboardSortableController', () => {
  let application
  let element
  
  beforeEach(() => {
    application = Application.start()
    application.register('dashboard-sortable', DashboardSortableController)
    
    document.body.innerHTML = `
      <div data-controller="dashboard-sortable" 
           data-dashboard-sortable-handle-value=".drag-handle"
           data-dashboard-sortable-animation-value="200">
        <div data-dashboard-sortable-target="container">
          <div class="dashboard-widget" data-widget-id="1" data-dashboard-sortable-target="widget">
            <div class="drag-handle"></div>
            Widget 1
          </div>
          <div class="dashboard-widget" data-widget-id="2" data-dashboard-sortable-target="widget">
            <div class="drag-handle"></div>
            Widget 2
          </div>
          <div class="dashboard-widget" data-widget-id="3" data-dashboard-sortable-target="widget">
            <div class="drag-handle"></div>
            Widget 3
          </div>
        </div>
      </div>
    `
    
    element = document.querySelector('[data-controller="dashboard-sortable"]')
  })
  
  it('initializes sortable on connect', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    expect(controller.sortable).toBeDefined()
  })
  
  it('adds dragging class to body on drag start', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    const mockEvent = { item: element.querySelector('.dashboard-widget'), oldIndex: 0 }
    
    controller.onStart(mockEvent)
    
    expect(document.body.classList.contains('dashboard-dragging')).toBe(true)
  })
  
  it('removes dragging class on drag end', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    document.body.classList.add('dashboard-dragging')
    
    const mockEvent = { 
      item: element.querySelector('.dashboard-widget'), 
      oldIndex: 0, 
      newIndex: 0 
    }
    
    controller.onEnd(mockEvent)
    
    expect(document.body.classList.contains('dashboard-dragging')).toBe(false)
  })
  
  it('saves order when position changes', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    const saveOrderSpy = vi.spyOn(controller, 'saveOrder')
    
    const mockEvent = { 
      item: element.querySelector('.dashboard-widget'), 
      oldIndex: 0, 
      newIndex: 2 
    }
    
    controller.onEnd(mockEvent)
    
    expect(saveOrderSpy).toHaveBeenCalled()
  })
  
  it('does not save order when position unchanged', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    const saveOrderSpy = vi.spyOn(controller, 'saveOrder')
    
    const mockEvent = { 
      item: element.querySelector('.dashboard-widget'), 
      oldIndex: 0, 
      newIndex: 0 
    }
    
    controller.onEnd(mockEvent)
    
    expect(saveOrderSpy).not.toHaveBeenCalled()
  })
  
  it('dispatches reorder event with widget IDs', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    const dispatchSpy = vi.spyOn(controller, 'dispatch')
    
    controller.saveOrder()
    
    expect(dispatchSpy).toHaveBeenCalledWith('reorder-widgets', {
      detail: { widgetIds: ['1', '2', '3'] },
      target: expect.any(Object)
    })
  })
  
  it('toggles edit mode', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    
    // Enter edit mode
    controller.toggleEdit()
    expect(element.dataset.editing).toBe('true')
    expect(element.classList.contains('edit-mode')).toBe(true)
    
    // Exit edit mode
    controller.toggleEdit()
    expect(element.dataset.editing).toBe('false')
    expect(element.classList.contains('edit-mode')).toBe(false)
  })
  
  it('shows drag handles in edit mode', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    const widgets = element.querySelectorAll('.dashboard-widget')
    
    controller.enterEditMode()
    
    widgets.forEach(widget => {
      expect(widget.classList.contains('draggable')).toBe(true)
    })
  })
  
  it('hides drag handles when exiting edit mode', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'dashboard-sortable')
    const widgets = element.querySelectorAll('.dashboard-widget')
    
    controller.enterEditMode()
    controller.exitEditMode()
    
    widgets.forEach(widget => {
      expect(widget.classList.contains('draggable')).toBe(false)
    })
  })
})