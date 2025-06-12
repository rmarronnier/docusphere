import '../setup.js'
import { Application } from "@hotwired/stimulus"
import DocumentShareController from "../../../app/javascript/controllers/document_share_controller"

describe("DocumentShareController", () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <form data-controller="document-share">
        <input type="email" 
               data-document-share-target="emailInput" 
               data-action="input->document-share#validateEmail"
               class="border-gray-300" />
        <select data-document-share-target="permissionSelect">
          <option value="read">Read</option>
          <option value="write">Write</option>
        </select>
        <textarea data-document-share-target="messageInput"></textarea>
        <button type="submit" data-document-share-target="submitButton">Submit</button>
        
        <button data-action="click->document-share#selectUser" 
                data-email="user@example.com">
          Select User
        </button>
      </form>
      
      <div class="share-modal">
        <div id="share-success-notification" 
             class="hidden" 
             data-notification-delay-value="100">
          Success
        </div>
      </div>
    `

    application = Application.start()
    application.register("document-share", DocumentShareController)
    
    element = document.querySelector('[data-controller="document-share"]')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("connect", () => {
    it("validates email on connect", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      const validateSpy = jest.fn()
      controller.validateEmail = validateSpy
      controller.connect()
      
      expect(validateSpy).toHaveBeenCalled()
    })
  })

  describe("validateEmail", () => {
    it("disables submit button for invalid email", () => {
      const emailInput = element.querySelector('[data-document-share-target="emailInput"]')
      const submitButton = element.querySelector('[data-document-share-target="submitButton"]')
      
      emailInput.value = "invalid-email"
      emailInput.dispatchEvent(new Event('input'))
      
      expect(submitButton.disabled).toBe(true)
      expect(emailInput.classList.contains('border-red-300')).toBe(true)
    })

    it("enables submit button for valid email", () => {
      const emailInput = element.querySelector('[data-document-share-target="emailInput"]')
      const submitButton = element.querySelector('[data-document-share-target="submitButton"]')
      
      emailInput.value = "valid@example.com"
      emailInput.dispatchEvent(new Event('input'))
      
      expect(submitButton.disabled).toBe(false)
      expect(emailInput.classList.contains('border-gray-300')).toBe(true)
    })

    it("handles empty email gracefully", () => {
      const emailInput = element.querySelector('[data-document-share-target="emailInput"]')
      const submitButton = element.querySelector('[data-document-share-target="submitButton"]')
      
      emailInput.value = ""
      emailInput.dispatchEvent(new Event('input'))
      
      expect(submitButton.disabled).toBe(true)
      expect(emailInput.classList.contains('border-gray-300')).toBe(true)
    })
  })

  describe("selectUser", () => {
    it("fills email input with selected user email", () => {
      const emailInput = element.querySelector('[data-document-share-target="emailInput"]')
      const selectButton = element.querySelector('[data-action="click->document-share#selectUser"]')
      
      selectButton.click()
      
      expect(emailInput.value).toBe("user@example.com")
    })

    it("validates email after selection", () => {
      const submitButton = element.querySelector('[data-document-share-target="submitButton"]')
      const selectButton = element.querySelector('[data-action="click->document-share#selectUser"]')
      
      selectButton.click()
      
      expect(submitButton.disabled).toBe(false)
    })

    it("focuses email input after selection", () => {
      const emailInput = element.querySelector('[data-document-share-target="emailInput"]')
      const selectButton = element.querySelector('[data-action="click->document-share#selectUser"]')
      
      jest.spyOn(emailInput, 'focus')
      selectButton.click()
      
      expect(emailInput.focus).toHaveBeenCalled()
    })
  })

  describe("onSuccess", () => {
    it("hides the modal", () => {
      const modal = document.querySelector('.share-modal')
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      
      controller.onSuccess({ detail: [{}, 200, {}] })
      
      expect(modal.classList.contains('hidden')).toBe(true)
    })

    it("shows success notification", (done) => {
      const notification = document.getElementById('share-success-notification')
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      
      controller.onSuccess({ detail: [{}, 200, {}] })
      
      expect(notification.classList.contains('hidden')).toBe(false)
      
      // Wait for auto-hide
      setTimeout(() => {
        expect(notification.classList.contains('hidden')).toBe(true)
        done()
      }, 150)
    })

    it("resets the form", () => {
      const emailInput = element.querySelector('[data-document-share-target="emailInput"]')
      emailInput.value = "test@example.com"
      
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      controller.onSuccess({ detail: [{}, 200, {}] })
      
      expect(emailInput.value).toBe("")
    })

    it("dispatches shared event with details", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      const emailInput = element.querySelector('[data-document-share-target="emailInput"]')
      const permissionSelect = element.querySelector('[data-document-share-target="permissionSelect"]')
      const messageInput = element.querySelector('[data-document-share-target="messageInput"]')
      
      emailInput.value = "test@example.com"
      permissionSelect.value = "write"
      messageInput.value = "Test message"
      
      const dispatchSpy = jest.fn()
      controller.dispatch = dispatchSpy
      
      controller.onSuccess({ detail: [{}, 200, {}] })
      
      expect(dispatchSpy).toHaveBeenCalledWith('shared', {
        detail: {
          email: "test@example.com",
          permission: "write",
          message: "Test message"
        }
      })
    })
  })

  describe("onError", () => {
    it("shows error message from response", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      window.alert = jest.fn()
      
      controller.onError({ 
        detail: [
          { error: "Email already exists" }, 
          422, 
          {}
        ] 
      })
      
      expect(window.alert).toHaveBeenCalledWith("Email already exists")
    })

    it("shows default error message when no specific error", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      window.alert = jest.fn()
      
      controller.onError({ detail: [{}, 500, {}] })
      
      expect(window.alert).toHaveBeenCalledWith("Une erreur est survenue lors du partage.")
    })

    it("re-enables submit button", () => {
      const submitButton = element.querySelector('[data-document-share-target="submitButton"]')
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      
      submitButton.disabled = true
      controller.onError({ detail: [{}, 500, {}] })
      
      expect(submitButton.disabled).toBe(false)
    })
  })

  describe("isValidEmail", () => {
    it("validates correct email formats", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      
      expect(controller.isValidEmail("user@example.com")).toBe(true)
      expect(controller.isValidEmail("user.name@example.com")).toBe(true)
      expect(controller.isValidEmail("user+tag@example.co.uk")).toBe(true)
    })

    it("rejects invalid email formats", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-share")
      
      expect(controller.isValidEmail("invalid")).toBe(false)
      expect(controller.isValidEmail("@example.com")).toBe(false)
      expect(controller.isValidEmail("user@")).toBe(false)
      expect(controller.isValidEmail("user @example.com")).toBe(false)
    })
  })
})