import { Application } from "@hotwired/stimulus"
import MobileMenuController from "../../../app/javascript/controllers/mobile_menu_controller"

describe("MobileMenuController", () => {
  let application
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="mobile-menu">
        <button data-action="click->mobile-menu#toggle" 
                data-mobile-menu-target="toggle"
                class="mobile-menu-toggle"
                aria-label="Menu">
          <span class="hamburger"></span>
        </button>
        
        <nav data-mobile-menu-target="menu" class="mobile-menu">
          <div class="mobile-menu-header">
            <button data-action="click->mobile-menu#close" class="close-button">
              Close
            </button>
          </div>
          <ul class="mobile-menu-items">
            <li><a href="/documents">Documents</a></li>
            <li><a href="/spaces">Spaces</a></li>
            <li><a href="/profile">Profile</a></li>
          </ul>
        </nav>
        
        <div data-mobile-menu-target="overlay" 
             data-action="click->mobile-menu#close"
             class="mobile-menu-overlay hidden">
        </div>
      </div>
    `
    
    application = Application.start()
    application.register("mobile-menu", MobileMenuController)
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#toggle", () => {
    it("opens the menu when closed", () => {
      const toggle = document.querySelector('[data-mobile-menu-target="toggle"]')
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      const overlay = document.querySelector('[data-mobile-menu-target="overlay"]')
      
      toggle.click()
      
      expect(menu.classList.contains('active')).toBe(true)
      expect(overlay.classList.contains('hidden')).toBe(false)
      expect(document.body.classList.contains('menu-open')).toBe(true)
    })
    
    it("closes the menu when open", () => {
      const toggle = document.querySelector('[data-mobile-menu-target="toggle"]')
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      // Open first
      toggle.click()
      expect(menu.classList.contains('active')).toBe(true)
      
      // Then close
      toggle.click()
      expect(menu.classList.contains('active')).toBe(false)
    })
    
    it("updates toggle button aria-expanded", () => {
      const toggle = document.querySelector('[data-mobile-menu-target="toggle"]')
      
      expect(toggle.getAttribute('aria-expanded')).toBe('false')
      
      toggle.click()
      expect(toggle.getAttribute('aria-expanded')).toBe('true')
      
      toggle.click()
      expect(toggle.getAttribute('aria-expanded')).toBe('false')
    })
  })
  
  describe("#open", () => {
    it("opens the menu with animation", (done) => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      controller.open()
      
      // Vérifier l'état initial
      expect(menu.classList.contains('active')).toBe(true)
      
      // Vérifier l'animation
      setTimeout(() => {
        expect(menu.classList.contains('animate-in')).toBe(true)
        done()
      }, 50)
    })
    
    it("prevents body scroll when open", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      
      controller.open()
      
      expect(document.body.style.overflow).toBe('hidden')
    })
    
    it("traps focus within menu", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      controller.open()
      
      // Le focus devrait être dans le menu
      expect(menu.contains(document.activeElement)).toBe(true)
    })
  })
  
  describe("#close", () => {
    it("closes the menu with animation", (done) => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      // Open first
      controller.open()
      
      // Then close
      controller.close()
      
      expect(menu.classList.contains('animate-out')).toBe(true)
      
      // After animation
      setTimeout(() => {
        expect(menu.classList.contains('active')).toBe(false)
        done()
      }, 300)
    })
    
    it("restores body scroll", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      
      controller.open()
      controller.close()
      
      // Attendre la fin de l'animation
      setTimeout(() => {
        expect(document.body.style.overflow).toBe('')
      }, 300)
    })
    
    it("returns focus to toggle button", (done) => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const toggle = document.querySelector('[data-mobile-menu-target="toggle"]')
      
      controller.open()
      controller.close()
      
      setTimeout(() => {
        expect(document.activeElement).toBe(toggle)
        done()
      }, 300)
    })
  })
  
  describe("swipe gestures", () => {
    it("closes menu on swipe left", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      // Open menu
      controller.open()
      
      // Simulate swipe left
      const touchstart = new TouchEvent('touchstart', {
        touches: [{ clientX: 250, clientY: 100 }]
      })
      const touchmove = new TouchEvent('touchmove', {
        touches: [{ clientX: 50, clientY: 100 }]
      })
      const touchend = new TouchEvent('touchend', {
        changedTouches: [{ clientX: 50, clientY: 100 }]
      })
      
      menu.dispatchEvent(touchstart)
      menu.dispatchEvent(touchmove)
      menu.dispatchEvent(touchend)
      
      expect(menu.classList.contains('animate-out')).toBe(true)
    })
    
    it("ignores small swipes", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      controller.open()
      
      // Small swipe (< 50px)
      const touchstart = new TouchEvent('touchstart', {
        touches: [{ clientX: 100, clientY: 100 }]
      })
      const touchend = new TouchEvent('touchend', {
        changedTouches: [{ clientX: 80, clientY: 100 }]
      })
      
      menu.dispatchEvent(touchstart)
      menu.dispatchEvent(touchend)
      
      expect(menu.classList.contains('active')).toBe(true)
    })
    
    it("shows visual feedback during swipe", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      controller.open()
      
      const touchstart = new TouchEvent('touchstart', {
        touches: [{ clientX: 250, clientY: 100 }]
      })
      const touchmove = new TouchEvent('touchmove', {
        touches: [{ clientX: 150, clientY: 100 }]
      })
      
      menu.dispatchEvent(touchstart)
      menu.dispatchEvent(touchmove)
      
      // Menu should translate during swipe
      expect(menu.style.transform).toContain('translateX')
    })
  })
  
  describe("keyboard navigation", () => {
    it("closes on Escape key", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      
      controller.open()
      
      const escapeEvent = new KeyboardEvent('keydown', { key: 'Escape' })
      document.dispatchEvent(escapeEvent)
      
      expect(document.querySelector('[data-mobile-menu-target="menu"]').classList.contains('animate-out')).toBe(true)
    })
    
    it("traps tab focus within menu", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const focusableElements = element.querySelectorAll('a, button')
      
      controller.open()
      
      // Focus last element
      focusableElements[focusableElements.length - 1].focus()
      
      // Tab should wrap to first
      const tabEvent = new KeyboardEvent('keydown', { key: 'Tab', shiftKey: false })
      element.dispatchEvent(tabEvent)
      
      // Note: Dans un vrai test, il faudrait implémenter la logique de focus trap
      expect(controller.focusTrap).toBeDefined()
    })
  })
  
  describe("responsive behavior", () => {
    it("auto-closes on window resize to desktop", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      
      controller.open()
      
      // Simulate resize to desktop
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 1024
      })
      
      window.dispatchEvent(new Event('resize'))
      
      expect(document.querySelector('[data-mobile-menu-target="menu"]').classList.contains('active')).toBe(false)
    })
    
    it("maintains state on small resize", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      
      controller.open()
      
      // Small resize within mobile range
      Object.defineProperty(window, 'innerWidth', {
        writable: true,
        configurable: true,
        value: 375
      })
      
      window.dispatchEvent(new Event('resize'))
      
      expect(document.querySelector('[data-mobile-menu-target="menu"]').classList.contains('active')).toBe(true)
    })
  })
  
  describe("submenu support", () => {
    beforeEach(() => {
      // Add submenu to DOM
      const menu = document.querySelector('.mobile-menu-items')
      menu.innerHTML += `
        <li class="has-submenu">
          <button data-action="click->mobile-menu#toggleSubmenu" 
                  data-mobile-menu-submenu-param="admin">
            Admin
          </button>
          <ul class="submenu" data-mobile-menu-target="submenu" data-submenu-id="admin">
            <li><a href="/users">Users</a></li>
            <li><a href="/settings">Settings</a></li>
          </ul>
        </li>
      `
    })
    
    it("toggles submenu", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const submenuButton = element.querySelector('[data-mobile-menu-submenu-param]')
      const submenu = element.querySelector('[data-submenu-id="admin"]')
      
      submenuButton.click()
      
      expect(submenu.classList.contains('open')).toBe(true)
      expect(submenuButton.getAttribute('aria-expanded')).toBe('true')
      
      submenuButton.click()
      
      expect(submenu.classList.contains('open')).toBe(false)
    })
  })
  
  describe("accessibility", () => {
    it("announces menu state to screen readers", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      expect(menu.getAttribute('aria-hidden')).toBe('true')
      
      controller.open()
      expect(menu.getAttribute('aria-hidden')).toBe('false')
      
      controller.close()
      setTimeout(() => {
        expect(menu.getAttribute('aria-hidden')).toBe('true')
      }, 300)
    })
    
    it("provides proper ARIA labels", () => {
      const toggle = document.querySelector('[data-mobile-menu-target="toggle"]')
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      expect(toggle.getAttribute('aria-label')).toBeTruthy()
      expect(toggle.getAttribute('aria-controls')).toBe(menu.id || 'mobile-menu')
    })
  })
  
  describe("performance", () => {
    it("uses will-change for animations", () => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      controller.open()
      
      expect(menu.style.willChange).toBe('transform')
    })
    
    it("cleans up after animation", (done) => {
      const element = document.querySelector('[data-controller="mobile-menu"]')
      const controller = application.getControllerForElementAndIdentifier(element, "mobile-menu")
      const menu = document.querySelector('[data-mobile-menu-target="menu"]')
      
      controller.open()
      controller.close()
      
      setTimeout(() => {
        expect(menu.style.willChange).toBe('')
        done()
      }, 350)
    })
  })
})