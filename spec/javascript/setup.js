// Test setup for Bun
import { JSDOM } from 'jsdom'

// Set up DOM environment
const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>')
global.window = dom.window
global.document = dom.window.document
global.navigator = dom.window.navigator
global.HTMLElement = dom.window.HTMLElement
global.Element = dom.window.Element
global.Event = dom.window.Event
global.CustomEvent = dom.window.CustomEvent
global.MutationObserver = dom.window.MutationObserver
global.Node = dom.window.Node
global.KeyboardEvent = dom.window.KeyboardEvent
global.MouseEvent = dom.window.MouseEvent
global.DataTransfer = dom.window.DataTransfer
global.File = dom.window.File

// Mock DragEvent if not available in jsdom
if (!dom.window.DragEvent) {
  global.DragEvent = class DragEvent extends Event {
    constructor(type, eventInitDict = {}) {
      super(type, eventInitDict)
      this.dataTransfer = eventInitDict.dataTransfer || null
    }
  }
} else {
  global.DragEvent = dom.window.DragEvent
}

// Mock fetch
global.fetch = (() => {
  const fn = (...args) => {
    fn.mock.calls.push(args)
    return fn.mock.response || Promise.resolve({ 
      ok: true, 
      json: async () => ({}) 
    })
  }
  fn.mock = { 
    calls: [],
    response: null,
    mockResolvedValue: (value) => { fn.mock.response = Promise.resolve(value) },
    mockRejectedValue: (value) => { fn.mock.response = Promise.reject(value) },
    mockClear: () => { fn.mock.calls = []; fn.mock.response = null }
  }
  return fn
})()

// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor(callback, options) {
    this.callback = callback
    this.options = options
  }
  observe(target) {
    // Can be overridden in tests
  }
  unobserve(target) {}
  disconnect() {}
}

// Mock localStorage
global.localStorage = {
  data: {},
  getItem: function(key) { return this.data[key] || null },
  setItem: function(key, value) { this.data[key] = value },
  removeItem: function(key) { delete this.data[key] },
  clear: function() { this.data = {} }
}

// Mock sessionStorage  
global.sessionStorage = {
  data: {},
  getItem: function(key) { return this.data[key] || null },
  setItem: function(key, value) { this.data[key] = value },
  removeItem: function(key) { delete this.data[key] },
  clear: function() { this.data = {} }
}

// Performance mock
global.performance = {
  now: () => Date.now(),
  timing: {
    navigationStart: Date.now(),
    loadEventEnd: Date.now() + 1000,
    domContentLoadedEventEnd: Date.now() + 500
  },
  getEntriesByType: (type) => [],
  memory: {
    usedJSHeapSize: 10000000,
    totalJSHeapSize: 20000000,
    jsHeapSizeLimit: 50000000
  }
}

// Helper to create mock functions
global.createMockFunction = (implementation = () => {}) => {
  const fn = (...args) => {
    const result = implementation(...args)
    fn.mock.calls.push(args)
    if (fn.mock.results) {
      fn.mock.results.push({ type: 'return', value: result })
    }
    return result
  }
  fn.mock = {
    calls: [],
    results: [],
    mockClear: () => {
      fn.mock.calls = []
      fn.mock.results = []
    }
  }
  return fn
}

// Helper to reset mocks between tests - will be called manually if needed
global.resetMocks = () => {
  fetch.mock.mockClear()
  localStorage.clear()
  sessionStorage.clear()
}