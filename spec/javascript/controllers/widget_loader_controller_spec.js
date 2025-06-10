import '../setup.js';
import { Application } from '@hotwired/stimulus';
import WidgetLoaderController from '../../../app/javascript/controllers/widget_loader_controller';
import { describe, it, expect, beforeEach, afterEach } from 'bun:test';

describe('WidgetLoaderController', () => {
  let application;
  let controller;
  let element;

  beforeEach(() => {
    // Reset mocks
    global.resetMocks();
    
    // Set up DOM
    document.body.innerHTML = `
      <div data-controller="widget-loader"
           data-widget-loader-url-value="/dashboard/widget"
           data-widget-loader-refresh-interval-value="30000"
           data-widget-loader-lazy-value="false">
        <div class="widget-loader-skeleton">
          <div class="animate-pulse">
            <div class="h-4 bg-gray-200 rounded w-3/4 mb-4"></div>
            <div class="h-4 bg-gray-200 rounded w-1/2"></div>
          </div>
        </div>
        <div data-widget-loader-target="content" class="hidden"></div>
        <div data-widget-loader-target="error" class="hidden"></div>
      </div>
    `;
    
    element = document.querySelector('[data-controller="widget-loader"]');
    
    // Start Stimulus
    application = Application.start();
    application.register('widget-loader', WidgetLoaderController);
  });

  afterEach(() => {
    if (application) {
      application.stop();
    }
    document.body.innerHTML = '';
  });

  describe('initialization', () => {
    it('loads content immediately when lazy is false', async () => {
      fetch.mock.mockResolvedValue({
        ok: true,
        text: () => Promise.resolve('<div>Widget content</div>')
      });

      // Wait for controller to initialize and load content
      await new Promise(resolve => setTimeout(resolve, 150));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      
      // Give additional time for DOM updates
      await new Promise(resolve => setTimeout(resolve, 50));
      
      expect(fetch.mock.calls.length).toBe(1);
      expect(fetch.mock.calls[0][0]).toBe('/dashboard/widget');
      
      // Check that fetch was called with correct headers
      const fetchOptions = fetch.mock.calls[0][1];
      expect(fetchOptions.headers['Accept']).toBe('text/html');
      expect(fetchOptions.headers['X-Requested-With']).toBe('XMLHttpRequest');
      
      expect(controller.contentTarget.innerHTML).toBe('<div>Widget content</div>');
      expect(controller.contentTarget.classList.contains('hidden')).toBe(false);
      expect(element.querySelector('.widget-loader-skeleton').classList.contains('hidden')).toBe(true);
    });

    it('does not load content immediately when lazy is true', async () => {
      element.dataset.widgetLoaderLazyValue = 'true';
      fetch.mock.mockClear();

      // Recreate the element and controller
      document.body.innerHTML = `
        <div data-controller="widget-loader"
             data-widget-loader-url-value="/dashboard/widget"
             data-widget-loader-lazy-value="true">
          <div class="widget-loader-skeleton"></div>
          <div data-widget-loader-target="content" class="hidden"></div>
          <div data-widget-loader-target="error" class="hidden"></div>
        </div>
      `;
      
      element = document.querySelector('[data-controller="widget-loader"]');
      await new Promise(resolve => setTimeout(resolve, 50));
      
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      
      expect(fetch.mock.calls.length).toBe(0);
    });
  });

  describe('content loading', () => {
    it('displays error message on fetch failure', async () => {
      fetch.mock.mockResolvedValue({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error'
      });

      await new Promise(resolve => setTimeout(resolve, 50));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      expect(controller.errorTarget.classList.contains('hidden')).toBe(false);
      expect(controller.contentTarget.classList.contains('hidden')).toBe(true);
      expect(element.querySelector('.widget-loader-skeleton').classList.contains('hidden')).toBe(true);
    });

    it('displays error message on network failure', async () => {
      fetch.mock.mockRejectedValue(new Error('Network error'));

      await new Promise(resolve => setTimeout(resolve, 50));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      expect(controller.errorTarget.classList.contains('hidden')).toBe(false);
      expect(controller.contentTarget.classList.contains('hidden')).toBe(true);
    });
  });

  describe('refresh functionality', () => {
    it('sets up refresh interval when specified', async () => {
      const originalSetInterval = window.setInterval;
      let intervalCallback;
      window.setInterval = createMockFunction((cb, delay) => {
        intervalCallback = cb;
        return 123;
      });
      
      await new Promise(resolve => setTimeout(resolve, 50));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      
      expect(window.setInterval.mock.calls.length).toBe(1);
      expect(window.setInterval.mock.calls[0][1]).toBe(30000);
      
      window.setInterval = originalSetInterval;
    });

    it('does not set up refresh interval when value is 0', async () => {
      document.body.innerHTML = `
        <div data-controller="widget-loader"
             data-widget-loader-url-value="/dashboard/widget"
             data-widget-loader-refresh-interval-value="0">
          <div class="widget-loader-skeleton"></div>
          <div data-widget-loader-target="content" class="hidden"></div>
          <div data-widget-loader-target="error" class="hidden"></div>
        </div>
      `;
      
      element = document.querySelector('[data-controller="widget-loader"]');
      
      const originalSetInterval = window.setInterval;
      window.setInterval = createMockFunction();
      
      await new Promise(resolve => setTimeout(resolve, 50));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      
      expect(window.setInterval.mock.calls.length).toBe(0);
      
      window.setInterval = originalSetInterval;
    });

    it('clears interval on disconnect', async () => {
      const originalClearInterval = window.clearInterval;
      window.clearInterval = createMockFunction();
      
      await new Promise(resolve => setTimeout(resolve, 50));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      controller.disconnect();
      
      expect(window.clearInterval.mock.calls.length).toBe(1);
      
      window.clearInterval = originalClearInterval;
    });
  });

  describe('manual refresh', () => {
    it('reloads content when refresh is called', async () => {
      fetch.mock.mockResolvedValue({
        ok: true,
        text: () => Promise.resolve('<div>Initial content</div>')
      });

      await new Promise(resolve => setTimeout(resolve, 50));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      await new Promise(resolve => setTimeout(resolve, 100));
      
      fetch.mock.mockClear();
      fetch.mock.mockResolvedValue({
        ok: true,
        text: () => Promise.resolve('<div>Refreshed content</div>')
      });
      
      controller.refresh();
      await new Promise(resolve => setTimeout(resolve, 100));
      
      expect(fetch.mock.calls.length).toBe(1);
      expect(fetch.mock.calls[0][0]).toBe('/dashboard/widget');
      expect(controller.contentTarget.innerHTML).toBe('<div>Refreshed content</div>');
    });
  });

  describe('lazy loading', () => {
    it('loads content when element becomes visible', async () => {
      // Create element with lazy loading
      document.body.innerHTML = `
        <div data-controller="widget-loader"
             data-widget-loader-url-value="/dashboard/widget"
             data-widget-loader-lazy-value="true">
          <div class="widget-loader-skeleton"></div>
          <div data-widget-loader-target="content" class="hidden"></div>
          <div data-widget-loader-target="error" class="hidden"></div>
        </div>
      `;
      
      element = document.querySelector('[data-controller="widget-loader"]');
      
      fetch.mock.mockClear();
      fetch.mock.mockResolvedValue({
        ok: true,
        text: () => Promise.resolve('<div>Lazy loaded content</div>')
      });

      // Mock IntersectionObserver
      let observerCallback;
      const originalIntersectionObserver = window.IntersectionObserver;
      window.IntersectionObserver = class MockIntersectionObserver {
        constructor(callback) {
          observerCallback = callback;
        }
        observe() {}
        disconnect() {}
        unobserve() {}
      };

      await new Promise(resolve => setTimeout(resolve, 50));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      
      // Simulate intersection
      if (observerCallback) {
        observerCallback([{ isIntersecting: true, target: element }]);
      }
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      expect(fetch.mock.calls.length).toBe(1);
      expect(fetch.mock.calls[0][0]).toBe('/dashboard/widget');
      expect(controller.contentTarget.innerHTML).toBe('<div>Lazy loaded content</div>');
      
      window.IntersectionObserver = originalIntersectionObserver;
    });
  });

  describe('loading states', () => {
    it('shows skeleton loader during fetch', async () => {
      let resolvePromise;
      fetch.mock.mockResolvedValue(new Promise(resolve => {
        resolvePromise = resolve;
      }));

      await new Promise(resolve => setTimeout(resolve, 50));
      controller = application.getControllerForElementAndIdentifier(element, 'widget-loader');
      
      // Check skeleton is visible during loading
      expect(element.querySelector('.widget-loader-skeleton').classList.contains('hidden')).toBe(false);
      
      // Resolve the fetch promise
      resolvePromise({
        ok: true,
        text: () => Promise.resolve('<div>Content</div>')
      });
      
      await new Promise(resolve => setTimeout(resolve, 100));
      
      // Check skeleton is hidden after loading
      expect(element.querySelector('.widget-loader-skeleton').classList.contains('hidden')).toBe(true);
    });
  });
});