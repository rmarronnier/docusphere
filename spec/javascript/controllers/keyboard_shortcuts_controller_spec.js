import { Application } from "@hotwired/stimulus"
import KeyboardShortcutsController from "../../../app/javascript/controllers/keyboard_shortcuts_controller"
import '../setup'

describe("KeyboardShortcutsController", () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="keyboard-shortcuts">
        <div id="keyboard-shortcuts-modal" class="hidden"></div>
        <button data-action="click->document-viewer#download">Download</button>
        <button data-action="click->document-viewer#print">Print</button>
        <button data-action="click->document-viewer#share">Share</button>
        <button data-action="click->document-viewer#edit-metadata">Edit</button>
        <div data-document-viewer-target="viewer">Viewer</div>
      </div>
    `

    application = Application.start()
    application.register("keyboard-shortcuts", KeyboardShortcutsController)
    element = document.querySelector('[data-controller="keyboard-shortcuts"]')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("keyboard navigation", () => {
    it("shows help modal on ? key", () => {
      const modal = document.getElementById('keyboard-shortcuts-modal')
      const event = new KeyboardEvent('keydown', { key: '?', shiftKey: true })
      
      document.dispatchEvent(event)
      
      expect(modal.classList.contains('hidden')).toBe(false)
    })

    it("triggers download on D key", () => {
      const downloadButton = document.querySelector('[data-action*="download"]')
      const clickSpy = jest.spyOn(downloadButton, 'click')
      const event = new KeyboardEvent('keydown', { key: 'd' })
      
      document.dispatchEvent(event)
      
      expect(clickSpy).toHaveBeenCalled()
    })

    it("triggers print on P key", () => {
      const printButton = document.querySelector('[data-action*="print"]')
      const clickSpy = jest.spyOn(printButton, 'click')
      const event = new KeyboardEvent('keydown', { key: 'p' })
      
      document.dispatchEvent(event)
      
      expect(clickSpy).toHaveBeenCalled()
    })

    it("triggers share on S key", () => {
      const shareButton = document.querySelector('[data-action*="share"]')
      const clickSpy = jest.spyOn(shareButton, 'click')
      const event = new KeyboardEvent('keydown', { key: 's' })
      
      document.dispatchEvent(event)
      
      expect(clickSpy).toHaveBeenCalled()
    })

    it("triggers edit on E key", () => {
      const editButton = document.querySelector('[data-action*="edit-metadata"]')
      const clickSpy = jest.spyOn(editButton, 'click')
      const event = new KeyboardEvent('keydown', { key: 'e' })
      
      document.dispatchEvent(event)
      
      expect(clickSpy).toHaveBeenCalled()
    })

    it("dispatches zoom-in event on + key", () => {
      const dispatchSpy = jest.spyOn(element, 'dispatchEvent')
      const event = new KeyboardEvent('keydown', { key: '+' })
      
      document.dispatchEvent(event)
      
      expect(dispatchSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'zoom-in'
        })
      )
    })

    it("dispatches zoom-out event on - key", () => {
      const dispatchSpy = jest.spyOn(element, 'dispatchEvent')
      const event = new KeyboardEvent('keydown', { key: '-' })
      
      document.dispatchEvent(event)
      
      expect(dispatchSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'zoom-out'
        })
      )
    })

    it("dispatches navigate-previous event on left arrow", () => {
      const dispatchSpy = jest.spyOn(element, 'dispatchEvent')
      const event = new KeyboardEvent('keydown', { key: 'ArrowLeft' })
      
      document.dispatchEvent(event)
      
      expect(dispatchSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'navigate-previous'
        })
      )
    })

    it("dispatches navigate-next event on right arrow", () => {
      const dispatchSpy = jest.spyOn(element, 'dispatchEvent')
      const event = new KeyboardEvent('keydown', { key: 'ArrowRight' })
      
      document.dispatchEvent(event)
      
      expect(dispatchSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'navigate-next'
        })
      )
    })
  })

  describe("fullscreen handling", () => {
    it("requests fullscreen on F key", () => {
      const viewer = document.querySelector('[data-document-viewer-target="viewer"]')
      const requestFullscreenSpy = jest.spyOn(viewer, 'requestFullscreen').mockImplementation(() => {})
      const event = new KeyboardEvent('keydown', { key: 'f' })
      
      document.dispatchEvent(event)
      
      expect(requestFullscreenSpy).toHaveBeenCalled()
    })

    it("exits fullscreen on F key when in fullscreen", () => {
      const exitFullscreenSpy = jest.spyOn(document, 'exitFullscreen').mockImplementation(() => {})
      Object.defineProperty(document, 'fullscreenElement', {
        writable: true,
        value: document.body
      })
      
      const event = new KeyboardEvent('keydown', { key: 'f' })
      document.dispatchEvent(event)
      
      expect(exitFullscreenSpy).toHaveBeenCalled()
    })
  })

  describe("escape handling", () => {
    it("closes modal on ESC key", () => {
      const modal = document.getElementById('keyboard-shortcuts-modal')
      modal.classList.remove('hidden')
      
      const event = new KeyboardEvent('keydown', { key: 'Escape' })
      document.dispatchEvent(event)
      
      expect(modal.classList.contains('hidden')).toBe(true)
    })

    it("exits fullscreen on ESC key", () => {
      const exitFullscreenSpy = jest.spyOn(document, 'exitFullscreen').mockImplementation(() => {})
      Object.defineProperty(document, 'fullscreenElement', {
        writable: true,
        value: document.body
      })
      
      const event = new KeyboardEvent('keydown', { key: 'Escape' })
      document.dispatchEvent(event)
      
      expect(exitFullscreenSpy).toHaveBeenCalled()
    })
  })

  describe("input handling", () => {
    it("ignores shortcuts when typing in input", () => {
      document.body.innerHTML += '<input type="text" />'
      const input = document.querySelector('input')
      input.focus()
      
      const dispatchSpy = jest.spyOn(element, 'dispatchEvent')
      const event = new KeyboardEvent('keydown', { key: 'd', target: input })
      
      input.dispatchEvent(event)
      
      expect(dispatchSpy).not.toHaveBeenCalled()
    })

    it("ignores shortcuts when typing in textarea", () => {
      document.body.innerHTML += '<textarea></textarea>'
      const textarea = document.querySelector('textarea')
      textarea.focus()
      
      const dispatchSpy = jest.spyOn(element, 'dispatchEvent')
      const event = new KeyboardEvent('keydown', { key: 'd', target: textarea })
      
      textarea.dispatchEvent(event)
      
      expect(dispatchSpy).not.toHaveBeenCalled()
    })
  })

  describe("modifier keys", () => {
    it("ignores D key with Cmd modifier", () => {
      const downloadButton = document.querySelector('[data-action*="download"]')
      const clickSpy = jest.spyOn(downloadButton, 'click')
      const event = new KeyboardEvent('keydown', { key: 'd', metaKey: true })
      
      document.dispatchEvent(event)
      
      expect(clickSpy).not.toHaveBeenCalled()
    })

    it("ignores P key with Ctrl modifier", () => {
      const printButton = document.querySelector('[data-action*="print"]')
      const clickSpy = jest.spyOn(printButton, 'click')
      const event = new KeyboardEvent('keydown', { key: 'p', ctrlKey: true })
      
      document.dispatchEvent(event)
      
      expect(clickSpy).not.toHaveBeenCalled()
    })
  })
})