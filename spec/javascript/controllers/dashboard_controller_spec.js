import { test, expect, describe, beforeEach, afterEach } from "bun:test"
import { Application } from "@hotwired/stimulus"
import DashboardController from "../../../app/javascript/controllers/dashboard_controller"

// Import the setup to ensure DOM is available
import "../setup.js"

describe("DashboardController", () => {
  let application
  let controller
  let element

  beforeEach(async () => {
    // Create a fresh meta tag for CSRF token
    const metaTag = document.createElement('meta')
    metaTag.name = 'csrf-token'
    metaTag.content = 'test-csrf-token'
    document.head.appendChild(metaTag)
    
    application = Application.start()
    application.register("dashboard", DashboardController)
    
    element = document.createElement("div")
    element.setAttribute("data-controller", "dashboard")
    element.innerHTML = `
      <div data-dashboard-target="widgets">
        <div class="widget" data-widget-id="1">Widget 1</div>
        <div class="widget" data-widget-id="2">Widget 2</div>
      </div>
    `
    document.body.appendChild(element)
    
    // Wait for Stimulus to initialize the controller
    await new Promise(resolve => setTimeout(resolve, 10))
    
    controller = application.getControllerForElementAndIdentifier(element, "dashboard")
  })

  afterEach(() => {
    application.stop()
    document.body.removeChild(element)
    // Remove CSRF token meta tag
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    if (metaTag) metaTag.remove()
  })

  describe("#connect", () => {
    test("initializes the dashboard", () => {
      expect(controller.hasWidgetsTarget).toBe(true)
    })
    
    test("finds all widgets", () => {
      const widgets = element.querySelectorAll(".widget")
      expect(widgets.length).toBe(2)
    })
  })

  describe("#updateWidget", () => {
    test("sends update request for widget", async () => {
      const originalFetch = global.fetch
      global.fetch = createMockFunction(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ status: 'success' })
        })
      )
      
      const event = new CustomEvent("update-widget", {
        detail: { widgetId: 1, config: { refresh_interval: 60 } }
      })
      
      await controller.updateWidget(event)
      
      expect(global.fetch.mock.calls.length).toBe(1)
      const [url, options] = global.fetch.mock.calls[0]
      expect(url).toMatch(/\/dashboard\/widgets\/1\/update/)
      expect(options.method).toBe('POST')
      expect(options.headers['Content-Type']).toBe('application/json')
      
      global.fetch = originalFetch
    })
  })

  describe("#reorderWidgets", () => {
    test("sends reorder request with widget IDs", async () => {
      const originalFetch = global.fetch
      global.fetch = createMockFunction(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ status: 'success' })
        })
      )
      
      const event = new CustomEvent("reorder-widgets", {
        detail: { widgetIds: [2, 1] }
      })
      
      await controller.reorderWidgets(event)
      
      expect(global.fetch.mock.calls.length).toBe(1)
      const [url, options] = global.fetch.mock.calls[0]
      expect(url).toMatch(/\/dashboard\/widgets\/reorder/)
      expect(options.method).toBe('POST')
      expect(options.body).toContain('"widget_ids":[2,1]')
      
      global.fetch = originalFetch
    })
  })

  describe("#refreshWidget", () => {
    test("refreshes a specific widget", async () => {
      const originalFetch = global.fetch
      global.fetch = createMockFunction(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ 
            status: 'success',
            widget: { id: 1, content: 'Updated content' }
          })
        })
      )
      
      const widgetElement = element.querySelector('[data-widget-id="1"]')
      const refreshButton = document.createElement('button')
      refreshButton.setAttribute('data-widget-id', '1')
      refreshButton.setAttribute('data-action', 'click->dashboard#refreshWidget')
      widgetElement.appendChild(refreshButton)
      
      const event = new Event('click')
      Object.defineProperty(event, 'currentTarget', {
        value: refreshButton,
        enumerable: true
      })
      
      await controller.refreshWidget(event)
      
      expect(global.fetch.mock.calls.length).toBe(1)
      const [url, options] = global.fetch.mock.calls[0]
      expect(url).toMatch(/\/dashboard\/widgets\/1\/refresh/)
      expect(options.method).toBe('POST')
      
      global.fetch = originalFetch
    })
    
    test("shows loading state during refresh", async () => {
      const originalFetch = global.fetch
      const widgetElement = element.querySelector('[data-widget-id="1"]')
      const refreshButton = document.createElement('button')
      refreshButton.setAttribute('data-widget-id', '1')
      widgetElement.appendChild(refreshButton)
      
      global.fetch = createMockFunction(() =>
        new Promise(resolve => {
          // Simulate network delay
          setTimeout(() => {
            resolve({
              ok: true,
              json: () => Promise.resolve({ status: 'success' })
            })
          }, 100)
        })
      )
      
      const event = new Event('click')
      Object.defineProperty(event, 'currentTarget', {
        value: refreshButton,
        enumerable: true
      })
      
      const refreshPromise = controller.refreshWidget(event)
      
      // Check loading state is active
      expect(widgetElement.classList.contains('loading')).toBe(true)
      
      await refreshPromise
      
      // Check loading state is removed
      expect(widgetElement.classList.contains('loading')).toBe(false)
      
      global.fetch = originalFetch
    })
  })

  describe("error handling", () => {
    test("handles network errors gracefully", async () => {
      const originalFetch = global.fetch
      global.fetch = createMockFunction(() => Promise.reject(new Error('Network error')))
      
      const originalConsoleError = console.error
      const consoleErrorCalls = []
      console.error = (...args) => consoleErrorCalls.push(args)
      
      const event = new CustomEvent("update-widget", {
        detail: { widgetId: 1, config: {} }
      })
      
      await controller.updateWidget(event)
      
      expect(consoleErrorCalls.length).toBe(1)
      expect(consoleErrorCalls[0][0]).toBe('Error updating widget:')
      expect(consoleErrorCalls[0][1]).toBeInstanceOf(Error)
      
      console.error = originalConsoleError
      global.fetch = originalFetch
    })
    
    test("handles server errors", async () => {
      const originalFetch = global.fetch
      global.fetch = createMockFunction(() =>
        Promise.resolve({
          ok: false,
          status: 500,
          statusText: 'Internal Server Error'
        })
      )
      
      const originalConsoleError = console.error
      const consoleErrorCalls = []
      console.error = (...args) => consoleErrorCalls.push(args)
      
      const event = new CustomEvent("update-widget", {
        detail: { widgetId: 1, config: {} }
      })
      
      await controller.updateWidget(event)
      
      expect(consoleErrorCalls.length).toBe(1)
      expect(consoleErrorCalls[0][0]).toContain('Server error')
      
      console.error = originalConsoleError
      global.fetch = originalFetch
    })
  })
})