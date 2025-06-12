import { test, expect, describe, beforeEach, afterEach } from "bun:test"
import { Application } from "@hotwired/stimulus"
import SearchAutocompleteController from "../../../app/javascript/controllers/search_autocomplete_controller"

describe("SearchAutocompleteController", () => {
  let application
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="search-autocomplete" 
           data-search-autocomplete-url-value="/search/suggestions">
        <form data-search-autocomplete-target="form">
          <input type="text" 
                 data-search-autocomplete-target="input"
                 data-action="input->search-autocomplete#search keydown->search-autocomplete#handleKeydown">
        </form>
        <div class="hidden" data-search-autocomplete-target="suggestions"></div>
      </div>
    `
    
    application = Application.start()
    application.register("search-autocomplete", SearchAutocompleteController)
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#search", () => {
    test("does not search for queries less than 2 characters", () => {
      const controller = application.controllers[0]
      let fetchSuggestionsCalled = false
      controller.fetchSuggestions = () => { fetchSuggestionsCalled = true }
      
      const input = document.querySelector('[data-search-autocomplete-target="input"]')
      input.value = "a"
      input.dispatchEvent(new Event('input'))
      
      expect(fetchSuggestionsCalled).toBe(false)
    })
    
    test("debounces search requests", async () => {
      const controller = application.controllers[0]
      let callCount = 0
      let lastQuery = null
      controller.fetchSuggestions = (query) => { 
        callCount++
        lastQuery = query
      }
      
      const input = document.querySelector('[data-search-autocomplete-target="input"]')
      
      // Déclencher plusieurs événements rapidement
      input.value = "te"
      input.dispatchEvent(new Event('input'))
      
      input.value = "tes"
      input.dispatchEvent(new Event('input'))
      
      input.value = "test"
      input.dispatchEvent(new Event('input'))
      
      // Attendre le délai de debounce
      await new Promise(resolve => setTimeout(resolve, 350))
      
      expect(callCount).toBe(1)
      expect(lastQuery).toBe("test")
    })
  })
  
  describe("#showSuggestions", () => {
    it("displays suggestions correctly", () => {
      const controller = application.controllers[0]
      const suggestions = [
        {
          id: 1,
          title: "Test Document",
          description: "A test description",
          type: "pdf",
          space: "General",
          url: "/documents/1"
        }
      ]
      
      controller.showSuggestions(suggestions)
      
      const suggestionsEl = document.querySelector('[data-search-autocomplete-target="suggestions"]')
      expect(suggestionsEl.classList.contains('hidden')).toBe(false)
      expect(suggestionsEl.innerHTML).toContain("Test Document")
      expect(suggestionsEl.innerHTML).toContain("A test description")
    })
    
    it("highlights matching text", () => {
      const controller = application.controllers[0]
      controller.inputTarget.value = "test"
      
      const suggestions = [{
        id: 1,
        title: "Testing Document",
        description: "A test file",
        type: "pdf",
        space: "General",
        url: "/documents/1"
      }]
      
      controller.showSuggestions(suggestions)
      
      const suggestionsEl = document.querySelector('[data-search-autocomplete-target="suggestions"]')
      expect(suggestionsEl.innerHTML).toContain('<mark class="bg-yellow-200">Test</mark>')
    })
  })
  
  describe("keyboard navigation", () => {
    beforeEach(() => {
      const controller = application.controllers[0]
      const suggestions = [
        { id: 1, title: "Doc 1", url: "/doc/1" },
        { id: 2, title: "Doc 2", url: "/doc/2" },
        { id: 3, title: "Doc 3", url: "/doc/3" }
      ]
      controller.showSuggestions(suggestions)
    })
    
    it("navigates down through suggestions", () => {
      const input = document.querySelector('[data-search-autocomplete-target="input"]')
      const downArrow = new KeyboardEvent('keydown', { key: 'ArrowDown' })
      
      input.dispatchEvent(downArrow)
      
      const suggestions = document.querySelectorAll('a')
      expect(suggestions[0].classList.contains('bg-gray-50')).toBe(true)
      
      input.dispatchEvent(downArrow)
      expect(suggestions[0].classList.contains('bg-gray-50')).toBe(false)
      expect(suggestions[1].classList.contains('bg-gray-50')).toBe(true)
    })
    
    it("wraps around when reaching the end", () => {
      const input = document.querySelector('[data-search-autocomplete-target="input"]')
      const suggestions = document.querySelectorAll('a')
      
      // Aller à la fin
      for (let i = 0; i < 3; i++) {
        input.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown' }))
      }
      
      // Un de plus devrait revenir au début
      input.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown' }))
      
      expect(suggestions[0].classList.contains('bg-gray-50')).toBe(true)
    })
    
    it("closes suggestions on Escape", () => {
      const input = document.querySelector('[data-search-autocomplete-target="input"]')
      const suggestionsEl = document.querySelector('[data-search-autocomplete-target="suggestions"]')
      
      expect(suggestionsEl.classList.contains('hidden')).toBe(false)
      
      input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }))
      
      expect(suggestionsEl.classList.contains('hidden')).toBe(true)
    })
  })
  
  describe("click outside", () => {
    it("hides suggestions when clicking outside", () => {
      const controller = application.controllers[0]
      controller.showSuggestions([{ id: 1, title: "Doc", url: "/doc/1" }])
      
      const suggestionsEl = document.querySelector('[data-search-autocomplete-target="suggestions"]')
      expect(suggestionsEl.classList.contains('hidden')).toBe(false)
      
      // Cliquer en dehors
      document.body.click()
      
      expect(suggestionsEl.classList.contains('hidden')).toBe(true)
    })
  })
})