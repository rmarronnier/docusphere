import '../setup.js'
import { Application } from "@hotwired/stimulus"
import ModalController from "../../../app/javascript/controllers/modal_controller"

describe("ModalController", () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="modal">
        <button data-action="click->modal#open" 
                data-modal-target-value="test-modal">
          Open Modal
        </button>
        
        <div id="test-modal" 
             class="share-modal hidden" 
             data-action="click->modal#closeOnBackdrop">
          <div data-action="click->modal#stopPropagation">
            <input type="text" id="test-input" />
            <button data-action="click->modal#close">Close</button>
          </div>
        </div>
      </div>
    `

    application = Application.start()
    application.register("modal", ModalController)
    
    element = document.querySelector('[data-controller="modal"]')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("open", () => {
    it("removes hidden class from modal", () => {
      const openButton = element.querySelector('[data-action="click->modal#open"]')
      const modal = document.getElementById('test-modal')
      
      openButton.click()
      
      expect(modal.classList.contains('hidden')).toBe(false)
    })

    it("focuses first input after opening", (done) => {
      const openButton = element.querySelector('[data-action="click->modal#open"]')
      const input = document.getElementById('test-input')
      
      jest.spyOn(input, 'focus')
      openButton.click()
      
      setTimeout(() => {
        expect(input.focus).toHaveBeenCalled()
        done()
      }, 150)
    })

    it("adds keydown event listener", () => {
      const openButton = element.querySelector('[data-action="click->modal#open"]')
      const addEventListenerSpy = jest.spyOn(document, 'addEventListener')
      
      openButton.click()
      
      expect(addEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function))
    })
  })

  describe("close", () => {
    it("adds hidden class to modal", () => {
      const modal = document.getElementById('test-modal')
      const closeButton = modal.querySelector('[data-action="click->modal#close"]')
      
      // First open the modal
      modal.classList.remove('hidden')
      
      closeButton.click()
      
      expect(modal.classList.contains('hidden')).toBe(true)
    })

    it("removes keydown event listener", () => {
      const modal = document.getElementById('test-modal')
      const closeButton = modal.querySelector('[data-action="click->modal#close"]')
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener')
      
      // First open the modal
      modal.classList.remove('hidden')
      
      closeButton.click()
      
      expect(removeEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function))
    })
  })

  describe("closeOnBackdrop", () => {
    it("closes modal when clicking on backdrop", () => {
      const modal = document.getElementById('test-modal')
      
      // First open the modal
      modal.classList.remove('hidden')
      
      // Simulate click on backdrop
      const event = new MouseEvent('click', { bubbles: true })
      Object.defineProperty(event, 'target', { value: modal, enumerable: true })
      Object.defineProperty(event, 'currentTarget', { value: modal, enumerable: true })
      
      modal.dispatchEvent(event)
      
      expect(modal.classList.contains('hidden')).toBe(true)
    })

    it("does not close modal when clicking inside content", () => {
      const modal = document.getElementById('test-modal')
      const content = modal.querySelector('[data-action="click->modal#stopPropagation"]')
      
      // First open the modal
      modal.classList.remove('hidden')
      
      // Simulate click on content
      content.click()
      
      expect(modal.classList.contains('hidden')).toBe(false)
    })
  })

  describe("handleEscape", () => {
    it("closes modal on Escape key", () => {
      const modal = document.getElementById('test-modal')
      const openButton = element.querySelector('[data-action="click->modal#open"]')
      
      // Open the modal first
      openButton.click()
      expect(modal.classList.contains('hidden')).toBe(false)
      
      // Simulate Escape key
      const escapeEvent = new KeyboardEvent('keydown', { key: 'Escape', keyCode: 27 })
      document.dispatchEvent(escapeEvent)
      
      expect(modal.classList.contains('hidden')).toBe(true)
    })

    it("does not interfere with other keys", () => {
      const modal = document.getElementById('test-modal')
      const openButton = element.querySelector('[data-action="click->modal#open"]')
      
      // Open the modal first
      openButton.click()
      expect(modal.classList.contains('hidden')).toBe(false)
      
      // Simulate other key
      const enterEvent = new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13 })
      document.dispatchEvent(enterEvent)
      
      expect(modal.classList.contains('hidden')).toBe(false)
    })
  })

  describe("disconnect", () => {
    it("removes event listener on disconnect", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "modal")
      const removeEventListenerSpy = jest.spyOn(document, 'removeEventListener')
      
      controller.disconnect()
      
      expect(removeEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function))
    })
  })
})