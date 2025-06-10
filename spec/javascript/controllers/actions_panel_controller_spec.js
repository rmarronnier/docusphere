import { test, expect, describe, beforeEach, afterEach } from "bun:test"
import { Application } from "@hotwired/stimulus"
import ActionsPanelController from "../../../app/javascript/controllers/actions_panel_controller"

// Import the setup to ensure DOM is available
import "../setup.js"

describe("ActionsPanelController", () => {
  let application
  let controller
  let element

  beforeEach(async () => {
    application = Application.start()
    application.register("actions-panel", ActionsPanelController)
    
    element = document.createElement("div")
    element.setAttribute("data-controller", "actions-panel")
    element.innerHTML = `
      <div class="actions-panel">
        <div class="flex items-center justify-between p-4 border-b">
          <h2 class="text-lg font-semibold text-gray-900">
            Actions prioritaires
          </h2>
          <button 
            data-action="click->actions-panel#toggle"
            class="p-1 rounded hover:bg-gray-100"
          >
            <svg class="h-5 w-5 text-gray-500 transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
            </svg>
          </button>
        </div>
        
        <div class="p-4 space-y-3">
          <div class="action-item">Action 1</div>
          <div class="action-item">Action 2</div>
        </div>
      </div>
    `
    document.body.appendChild(element)
    
    // Wait for Stimulus to initialize the controller
    await new Promise(resolve => setTimeout(resolve, 10))
    
    controller = application.getControllerForElementAndIdentifier(element, "actions-panel")
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(element)
  })

  describe("#connect", () => {
    test("initializes the controller", () => {
      expect(controller).toBeTruthy()
    })
    
    test("sets initial collapsed state from data attribute", async () => {
      // Create new element with collapsed attribute
      const collapsedElement = document.createElement("div")
      collapsedElement.setAttribute("data-controller", "actions-panel")
      collapsedElement.setAttribute("data-actions-panel-collapsed-value", "true")
      collapsedElement.innerHTML = element.innerHTML
      document.body.appendChild(collapsedElement)
      
      await new Promise(resolve => setTimeout(resolve, 10))
      
      const collapsedController = application.getControllerForElementAndIdentifier(collapsedElement, "actions-panel")
      expect(collapsedController.collapsedValue).toBe(true)
      
      document.body.removeChild(collapsedElement)
    })
  })

  describe("#toggle", () => {
    test("toggles collapsed state", () => {
      const initialState = controller.collapsedValue
      controller.toggle()
      expect(controller.collapsedValue).toBe(!initialState)
    })
    
    test("updates DOM classes when toggling", async () => {
      const panel = element.querySelector('.actions-panel')
      const content = element.querySelector('.p-4.space-y-3')
      const icon = element.querySelector('svg')
      
      // Start in expanded state
      controller.collapsedValue = false
      controller.collapsedValueChanged()
      
      expect(panel.classList.contains('collapsed')).toBe(false)
      expect(content.classList.contains('hidden')).toBe(false)
      expect(icon.classList.contains('rotate-180')).toBe(false)
      
      // Toggle to collapsed
      controller.toggle()
      
      // Wait for Stimulus to process the value change
      await new Promise(resolve => setTimeout(resolve, 0))
      
      // Wait for DOM updates
      expect(controller.collapsedValue).toBe(true)
      expect(panel.classList.contains('collapsed')).toBe(true)
      expect(content.classList.contains('hidden')).toBe(true)
      expect(icon.classList.contains('rotate-180')).toBe(true)
    })
    
    test("shows badge when collapsed with count", () => {
      // Add count badge element
      const badgeHtml = `
        <div class="p-2 hidden" data-actions-panel-target="badge">
          <span class="badge">5</span>
        </div>
      `
      element.querySelector('.actions-panel').insertAdjacentHTML('beforeend', badgeHtml)
      
      controller.collapsedValue = true
      controller.collapsedValueChanged()
      
      const badge = element.querySelector('[data-actions-panel-target="badge"]')
      expect(badge.classList.contains('hidden')).toBe(false)
    })
  })

  describe("#collapsedValueChanged", () => {
    test("persists collapsed state to localStorage", () => {
      controller.collapsedValue = true
      controller.collapsedValueChanged()
      
      expect(localStorage.getItem('actions-panel-collapsed')).toBe('true')
      
      controller.collapsedValue = false
      controller.collapsedValueChanged()
      
      expect(localStorage.getItem('actions-panel-collapsed')).toBe('false')
    })
    
    test("dispatches event when state changes", () => {
      const eventSpy = []
      element.addEventListener('actions-panel:toggled', (event) => {
        eventSpy.push(event.detail)
      })
      
      controller.collapsedValue = true
      controller.collapsedValueChanged()
      
      expect(eventSpy.length).toBe(1)
      expect(eventSpy[0].collapsed).toBe(true)
    })
  })

  describe("accessibility", () => {
    test("updates aria-expanded attribute", () => {
      const button = element.querySelector('[data-action="click->actions-panel#toggle"]')
      
      controller.collapsedValue = false
      controller.collapsedValueChanged()
      expect(button.getAttribute('aria-expanded')).toBe('true')
      
      controller.collapsedValue = true
      controller.collapsedValueChanged()
      expect(button.getAttribute('aria-expanded')).toBe('false')
    })
    
    test("maintains keyboard navigation", () => {
      const button = element.querySelector('[data-action="click->actions-panel#toggle"]')
      const event = new KeyboardEvent('keydown', { key: 'Enter' })
      
      const initialState = controller.collapsedValue
      button.dispatchEvent(event)
      
      // Should not toggle on Enter key (only on click)
      expect(controller.collapsedValue).toBe(initialState)
    })
  })
})