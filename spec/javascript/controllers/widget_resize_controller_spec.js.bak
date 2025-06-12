import { expect, describe, it, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import WidgetResizeController from '../../../app/javascript/controllers/widget_resize_controller'

describe('WidgetResizeController', () => {
  let application
  let element
  
  beforeEach(() => {
    application = Application.start()
    application.register('widget-resize', WidgetResizeController)
    
    document.body.innerHTML = `
      <div class="dashboard-widgets" style="width: 1000px; gap: 16px;">
        <div class="dashboard-widget" 
             data-controller="widget-resize"
             data-widget-id="1"
             data-widget-width="2"
             data-widget-height="1"
             data-widget-resize-min-width-value="1"
             data-widget-resize-max-width-value="4"
             data-widget-resize-min-height-value="1"
             data-widget-resize-max-height-value="4"
             style="grid-column: span 2; grid-row: span 1;">
          Widget Content
        </div>
      </div>
    `
    
    element = document.querySelector('[data-controller="widget-resize"]')
  })
  
  it('adds resize handles on connect', () => {
    const handles = element.querySelectorAll('.resize-handle')
    expect(handles.length).toBe(3) // e, se, s
    expect(element.querySelector('.resize-e')).toBeTruthy()
    expect(element.querySelector('.resize-se')).toBeTruthy()
    expect(element.querySelector('.resize-s')).toBeTruthy()
  })
  
  it('starts resize on handle mousedown', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'widget-resize')
    const handle = element.querySelector('.resize-e')
    const dispatchSpy = vi.spyOn(controller, 'dispatch')
    
    const event = new MouseEvent('mousedown', { pageX: 500, pageY: 300 })
    handle.dispatchEvent(event)
    
    expect(controller.isResizing).toBe(true)
    expect(controller.direction).toBe('e')
    expect(document.body.classList.contains('widget-resizing')).toBe(true)
    expect(dispatchSpy).toHaveBeenCalledWith('resize-start', expect.any(Object))
  })
  
  it('calculates grid cell size correctly', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'widget-resize')
    const handle = element.querySelector('.resize-e')
    
    const event = new MouseEvent('mousedown', { pageX: 500, pageY: 300 })
    handle.dispatchEvent(event)
    
    // Container width: 1000px, gap: 16px, columns: 4
    // Cell width = (1000 - (16 * 3)) / 4 = 238
    expect(controller.cellWidth).toBe(238)
    expect(controller.cellHeight).toBe(320) // Default grid size
  })
  
  it('resizes widget on mousemove', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'widget-resize')
    const handle = element.querySelector('.resize-e')
    
    // Start resize
    const startEvent = new MouseEvent('mousedown', { pageX: 500, pageY: 300 })
    handle.dispatchEvent(startEvent)
    
    // Move mouse
    const moveEvent = new MouseEvent('mousemove', { pageX: 740, pageY: 300 })
    document.dispatchEvent(moveEvent)
    
    // Should increase width by 1 grid unit (240px movement / 238px cell width)
    expect(element.style.gridColumn).toBe('span 3')
  })
  
  it('respects min/max width constraints', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'widget-resize')
    const handle = element.querySelector('.resize-e')
    
    // Start resize
    const startEvent = new MouseEvent('mousedown', { pageX: 500, pageY: 300 })
    handle.dispatchEvent(startEvent)
    
    // Try to resize beyond max width
    const moveEvent = new MouseEvent('mousemove', { pageX: 1500, pageY: 300 })
    document.dispatchEvent(moveEvent)
    
    // Should be clamped to max width (4)
    expect(element.style.gridColumn).toBe('span 4')
  })
  
  it('saves resize on mouseup', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'widget-resize')
    const handle = element.querySelector('.resize-e')
    const dispatchSpy = vi.spyOn(controller, 'dispatch')
    
    // Start resize
    const startEvent = new MouseEvent('mousedown', { pageX: 500, pageY: 300 })
    handle.dispatchEvent(startEvent)
    
    // Move mouse
    const moveEvent = new MouseEvent('mousemove', { pageX: 740, pageY: 300 })
    document.dispatchEvent(moveEvent)
    
    // Stop resize
    const endEvent = new MouseEvent('mouseup')
    document.dispatchEvent(endEvent)
    
    expect(controller.isResizing).toBe(false)
    expect(document.body.classList.contains('widget-resizing')).toBe(false)
    expect(element.dataset.widgetWidth).toBe('3')
    expect(dispatchSpy).toHaveBeenCalledWith('resize-end', expect.objectContaining({
      detail: expect.objectContaining({
        widgetId: '1',
        width: 3,
        height: 1
      })
    }))
  })
  
  it('does not save if size unchanged', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'widget-resize')
    const handle = element.querySelector('.resize-e')
    const dispatchSpy = vi.spyOn(controller, 'dispatch')
    
    // Clear previous calls
    dispatchSpy.mockClear()
    
    // Start and stop without moving
    const startEvent = new MouseEvent('mousedown', { pageX: 500, pageY: 300 })
    handle.dispatchEvent(startEvent)
    
    const endEvent = new MouseEvent('mouseup')
    document.dispatchEvent(endEvent)
    
    // Should not dispatch resize-end if size unchanged
    expect(dispatchSpy).not.toHaveBeenCalledWith('resize-end', expect.any(Object))
  })
  
  it('handles touch events', () => {
    const controller = application.getControllerForElementAndIdentifier(element, 'widget-resize')
    const handle = element.querySelector('.resize-s')
    
    const touchEvent = new TouchEvent('touchstart', {
      touches: [{ pageX: 500, pageY: 300 }]
    })
    handle.dispatchEvent(touchEvent)
    
    expect(controller.isResizing).toBe(true)
    expect(controller.direction).toBe('s')
  })
})