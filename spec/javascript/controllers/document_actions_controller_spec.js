import { Application } from "@hotwired/stimulus"
import DocumentActionsController from "../../../app/javascript/controllers/document_actions_controller"
import '../setup'

describe("DocumentActionsController", () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="document-actions" data-document-id="123">
        <button data-action="click->document-actions#move">Move</button>
        <button data-action="click->document-actions#requestValidation">Request Validation</button>
        <button data-action="click->document-actions#generatePublicLink">Generate Link</button>
      </div>
      <div id="move-document-modal" class="hidden"></div>
      <div id="request-validation-modal" class="hidden"></div>
      <meta name="csrf-token" content="test-token">
    `

    application = Application.start()
    application.register("document-actions", DocumentActionsController)
    element = document.querySelector('[data-controller="document-actions"]')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("move action", () => {
    it("opens move modal", () => {
      const modal = document.getElementById('move-document-modal')
      const button = document.querySelector('[data-action*="move"]')
      
      button.click()
      
      expect(modal.classList.contains('hidden')).toBe(false)
    })

    it("dispatches modal:open event", () => {
      const modal = document.getElementById('move-document-modal')
      const eventSpy = jest.fn()
      modal.addEventListener('modal:open', eventSpy)
      
      const button = document.querySelector('[data-action*="move"]')
      button.click()
      
      expect(eventSpy).toHaveBeenCalled()
    })
  })

  describe("requestValidation action", () => {
    it("opens validation modal", () => {
      const modal = document.getElementById('request-validation-modal')
      const button = document.querySelector('[data-action*="requestValidation"]')
      
      button.click()
      
      expect(modal.classList.contains('hidden')).toBe(false)
    })

    it("dispatches modal:open event", () => {
      const modal = document.getElementById('request-validation-modal')
      const eventSpy = jest.fn()
      modal.addEventListener('modal:open', eventSpy)
      
      const button = document.querySelector('[data-action*="requestValidation"]')
      button.click()
      
      expect(eventSpy).toHaveBeenCalled()
    })
  })

  describe("generatePublicLink action", () => {
    let fetchMock

    beforeEach(() => {
      fetchMock = jest.fn()
      global.fetch = fetchMock
      
      // Mock clipboard API
      Object.assign(navigator, {
        clipboard: {
          writeText: jest.fn().mockResolvedValue(undefined)
        }
      })
    })

    it("makes POST request to generate link", async () => {
      fetchMock.mockResolvedValue({
        ok: true,
        json: async () => ({ public_link: 'https://example.com/public/123' })
      })
      
      const button = document.querySelector('[data-action*="generatePublicLink"]')
      button.click()
      
      await new Promise(resolve => setTimeout(resolve, 10))
      
      expect(fetchMock).toHaveBeenCalledWith(
        '/ged/documents/123/generate_public_link',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
            'X-CSRF-Token': 'test-token'
          })
        })
      )
    })

    it("copies link to clipboard on success", async () => {
      const publicLink = 'https://example.com/public/123'
      fetchMock.mockResolvedValue({
        ok: true,
        json: async () => ({ public_link: publicLink })
      })
      
      const button = document.querySelector('[data-action*="generatePublicLink"]')
      button.click()
      
      await new Promise(resolve => setTimeout(resolve, 10))
      
      expect(navigator.clipboard.writeText).toHaveBeenCalledWith(publicLink)
    })

    it("shows success notification", async () => {
      fetchMock.mockResolvedValue({
        ok: true,
        json: async () => ({ public_link: 'https://example.com/public/123' })
      })
      
      const button = document.querySelector('[data-action*="generatePublicLink"]')
      button.click()
      
      await new Promise(resolve => setTimeout(resolve, 10))
      
      const notification = document.querySelector('.bg-green-500')
      expect(notification).toBeTruthy()
      expect(notification.textContent).toContain('Lien public copié')
    })

    it("dispatches public-link-generated event", async () => {
      const publicLink = 'https://example.com/public/123'
      fetchMock.mockResolvedValue({
        ok: true,
        json: async () => ({ public_link: publicLink })
      })
      
      const eventSpy = jest.fn()
      element.addEventListener('public-link-generated', eventSpy)
      
      const button = document.querySelector('[data-action*="generatePublicLink"]')
      button.click()
      
      await new Promise(resolve => setTimeout(resolve, 10))
      
      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { publicLink }
        })
      )
    })

    it("shows error notification on failure", async () => {
      fetchMock.mockResolvedValue({
        ok: false
      })
      
      const button = document.querySelector('[data-action*="generatePublicLink"]')
      button.click()
      
      await new Promise(resolve => setTimeout(resolve, 10))
      
      const notification = document.querySelector('.bg-red-500')
      expect(notification).toBeTruthy()
      expect(notification.textContent).toContain('Erreur')
    })

    it("handles network errors", async () => {
      fetchMock.mockRejectedValue(new Error('Network error'))
      
      const button = document.querySelector('[data-action*="generatePublicLink"]')
      button.click()
      
      await new Promise(resolve => setTimeout(resolve, 10))
      
      const notification = document.querySelector('.bg-red-500')
      expect(notification).toBeTruthy()
    })
  })

  describe("notifications", () => {
    it("removes notification after 3 seconds", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-actions")
      
      controller.showNotification('Test message', 'success')
      
      let notification = document.querySelector('.bg-green-500')
      expect(notification).toBeTruthy()
      
      // Wait for removal
      await new Promise(resolve => setTimeout(resolve, 3500))
      
      notification = document.querySelector('.bg-green-500')
      expect(notification).toBeFalsy()
    })

    it("applies correct styling for different types", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-actions")
      
      controller.showNotification('Success', 'success')
      expect(document.querySelector('.bg-green-500')).toBeTruthy()
      
      controller.showNotification('Error', 'error')
      expect(document.querySelector('.bg-red-500')).toBeTruthy()
      
      controller.showNotification('Info', 'info')
      expect(document.querySelector('.bg-blue-500')).toBeTruthy()
    })
  })

  describe("initialization", () => {
    it("gets document ID from data attribute", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "document-actions")
      
      expect(controller.documentId).toBe(123)
    })

    it("falls back to dataset if value not provided", () => {
      element.removeAttribute('data-document-actions-document-id-value')
      element.dataset.documentId = '456'
      
      const newController = new DocumentActionsController()
      newController.element = element
      newController.documentIdValue = null
      newController.connect()
      
      expect(newController.documentId).toBe('456')
    })
  })
})