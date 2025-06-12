import { Application } from "@hotwired/stimulus"
import DropdownController from "../../../app/javascript/controllers/dropdown_controller"

describe("DropdownController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="dropdown" class="dropdown">
        <button data-action="click->dropdown#toggle" data-dropdown-target="button">
          Menu
        </button>
        <div data-dropdown-target="menu" class="dropdown-menu hidden">
          <a href="#" class="dropdown-item">Item 1</a>
          <a href="#" class="dropdown-item">Item 2</a>
          <a href="#" class="dropdown-item">Item 3</a>
        </div>
      </div>
    `
    
    application = Application.start()
    application.register("dropdown", DropdownController)
    
    element = document.querySelector('[data-controller="dropdown"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#toggle", () => {
    it("toggles menu visibility", () => {
      const button = element.querySelector('[data-dropdown-target="button"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      
      expect(menu.classList.contains('hidden')).toBe(true)
      
      button.click()
      expect(menu.classList.contains('hidden')).toBe(false)
      expect(menu.classList.contains('show')).toBe(true)
      
      button.click()
      expect(menu.classList.contains('hidden')).toBe(true)
      expect(menu.classList.contains('show')).toBe(false)
    })
    
    it("adds active class to button when open", () => {
      const button = element.querySelector('[data-dropdown-target="button"]')
      
      button.click()
      expect(button.classList.contains('active')).toBe(true)
      
      button.click()
      expect(button.classList.contains('active')).toBe(false)
    })
  })
  
  describe("#show", () => {
    it("shows the menu", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "dropdown")
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      
      controller.show()
      
      expect(menu.classList.contains('hidden')).toBe(false)
      expect(menu.classList.contains('show')).toBe(true)
    })
    
    it("positions menu correctly", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "dropdown")
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      
      // Mock getBoundingClientRect
      const button = element.querySelector('[data-dropdown-target="button"]')
      button.getBoundingClientRect = jest.fn().mockReturnValue({
        bottom: 100,
        left: 50,
        right: 150,
        width: 100
      })
      
      controller.show()
      
      // Le menu devrait être positionné sous le bouton
      expect(menu.style.top).toBeTruthy()
      expect(menu.style.left).toBeTruthy()
    })
  })
  
  describe("#hide", () => {
    it("hides the menu", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "dropdown")
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      
      // D'abord montrer
      controller.show()
      expect(menu.classList.contains('show')).toBe(true)
      
      // Puis cacher
      controller.hide()
      expect(menu.classList.contains('hidden')).toBe(true)
      expect(menu.classList.contains('show')).toBe(false)
    })
  })
  
  describe("click outside", () => {
    it("closes menu when clicking outside", () => {
      const button = element.querySelector('[data-dropdown-target="button"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      
      // Ouvrir le menu
      button.click()
      expect(menu.classList.contains('show')).toBe(true)
      
      // Cliquer en dehors
      document.body.click()
      
      // Le menu devrait se fermer
      expect(menu.classList.contains('hidden')).toBe(true)
    })
    
    it("keeps menu open when clicking inside menu", () => {
      const button = element.querySelector('[data-dropdown-target="button"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      const menuItem = menu.querySelector('.dropdown-item')
      
      // Ouvrir le menu
      button.click()
      expect(menu.classList.contains('show')).toBe(true)
      
      // Cliquer dans le menu
      menuItem.click()
      
      // Le menu devrait rester ouvert (sauf si l'item a une action)
      expect(menu.classList.contains('show')).toBe(true)
    })
  })
  
  describe("keyboard navigation", () => {
    it("closes on Escape key", () => {
      const button = element.querySelector('[data-dropdown-target="button"]')
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      
      // Ouvrir le menu
      button.click()
      expect(menu.classList.contains('show')).toBe(true)
      
      // Appuyer sur Escape
      const escapeEvent = new KeyboardEvent('keydown', { key: 'Escape' })
      document.dispatchEvent(escapeEvent)
      
      expect(menu.classList.contains('hidden')).toBe(true)
    })
    
    it("navigates menu items with arrow keys", () => {
      const button = element.querySelector('[data-dropdown-target="button"]')
      const menuItems = element.querySelectorAll('.dropdown-item')
      
      // Ouvrir le menu
      button.click()
      
      // Simuler ArrowDown
      const arrowDownEvent = new KeyboardEvent('keydown', { key: 'ArrowDown' })
      element.dispatchEvent(arrowDownEvent)
      
      // Le premier item devrait avoir le focus
      expect(document.activeElement).toBe(menuItems[0])
      
      // ArrowDown à nouveau
      element.dispatchEvent(arrowDownEvent)
      expect(document.activeElement).toBe(menuItems[1])
      
      // ArrowUp
      const arrowUpEvent = new KeyboardEvent('keydown', { key: 'ArrowUp' })
      element.dispatchEvent(arrowUpEvent)
      expect(document.activeElement).toBe(menuItems[0])
    })
    
    it("wraps focus at menu boundaries", () => {
      const button = element.querySelector('[data-dropdown-target="button"]')
      const menuItems = element.querySelectorAll('.dropdown-item')
      
      button.click()
      
      // Aller au dernier item
      menuItems[menuItems.length - 1].focus()
      
      // ArrowDown devrait revenir au premier
      const arrowDownEvent = new KeyboardEvent('keydown', { key: 'ArrowDown' })
      element.dispatchEvent(arrowDownEvent)
      expect(document.activeElement).toBe(menuItems[0])
      
      // ArrowUp devrait aller au dernier
      const arrowUpEvent = new KeyboardEvent('keydown', { key: 'ArrowUp' })
      element.dispatchEvent(arrowUpEvent)
      expect(document.activeElement).toBe(menuItems[menuItems.length - 1])
    })
  })
  
  describe("with custom position", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="dropdown" 
             data-dropdown-position-value="top"
             data-dropdown-align-value="end"
             class="dropdown">
          <button data-dropdown-target="button">Menu</button>
          <div data-dropdown-target="menu" class="dropdown-menu hidden">
            <a href="#" class="dropdown-item">Item</a>
          </div>
        </div>
      `
      
      element = document.querySelector('[data-controller="dropdown"]')
    })
    
    it("positions menu according to data attributes", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "dropdown")
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      
      controller.show()
      
      // Vérifier que les classes de position sont appliquées
      expect(menu.classList.contains('dropdown-top')).toBe(true)
      expect(menu.classList.contains('dropdown-end')).toBe(true)
    })
  })
  
  describe("nested dropdowns", () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div data-controller="dropdown" class="dropdown">
          <button data-dropdown-target="button">Parent</button>
          <div data-dropdown-target="menu" class="dropdown-menu hidden">
            <div data-controller="dropdown" class="dropdown">
              <button data-dropdown-target="button">Child</button>
              <div data-dropdown-target="menu" class="dropdown-menu hidden">
                <a href="#" class="dropdown-item">Nested Item</a>
              </div>
            </div>
          </div>
        </div>
      `
    })
    
    it("handles nested dropdowns independently", () => {
      const parentDropdown = document.querySelector('[data-controller="dropdown"]')
      const parentButton = parentDropdown.querySelector('[data-dropdown-target="button"]')
      const parentMenu = parentDropdown.querySelector('[data-dropdown-target="menu"]')
      
      // Ouvrir le parent
      parentButton.click()
      expect(parentMenu.classList.contains('show')).toBe(true)
      
      // Ouvrir l'enfant
      const childDropdown = parentMenu.querySelector('[data-controller="dropdown"]')
      const childButton = childDropdown.querySelector('[data-dropdown-target="button"]')
      const childMenu = childDropdown.querySelector('[data-dropdown-target="menu"]')
      
      childButton.click()
      expect(childMenu.classList.contains('show')).toBe(true)
      expect(parentMenu.classList.contains('show')).toBe(true) // Parent reste ouvert
    })
  })
  
  describe("disconnect", () => {
    it("removes event listeners on disconnect", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "dropdown")
      const button = element.querySelector('[data-dropdown-target="button"]')
      
      // Ouvrir le dropdown
      button.click()
      const menu = element.querySelector('[data-dropdown-target="menu"]')
      expect(menu.classList.contains('show')).toBe(true)
      
      // Déconnecter le controller
      controller.disconnect()
      
      // Cliquer en dehors ne devrait plus fermer le menu
      document.body.click()
      expect(menu.classList.contains('show')).toBe(true)
    })
  })
})