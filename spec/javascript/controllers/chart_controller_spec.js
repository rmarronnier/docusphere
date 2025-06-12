import '../setup.js'
import { Application } from "@hotwired/stimulus"
import ChartController from "../../../app/javascript/controllers/chart_controller"

// Mock ApexCharts
const mockChart = {
  render: jest.fn(),
  destroy: jest.fn(),
  updateOptions: jest.fn()
}

const MockApexCharts = jest.fn().mockImplementation(() => mockChart)

// Mock the dynamic import
jest.mock('apexcharts', () => ({
  default: MockApexCharts
}), { virtual: true })

describe("ChartController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="chart"
           data-chart-config-value='{"chart":{"type":"line","height":350},"xaxis":{"categories":["Jan","Feb","Mar"]}}'
           data-chart-series-value='[{"name":"Sales","data":[30,40,35]}]'>
        <div id="chart-123"></div>
      </div>
    `
    
    application = Application.start()
    application.register("chart", ChartController)
    
    element = document.querySelector('[data-controller="chart"]')
    
    // Reset mocks
    mockChart.render.mockClear()
    mockChart.destroy.mockClear()
    mockChart.updateOptions.mockClear()
    MockApexCharts.mockClear()
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("connect", () => {
    it("initializes chart on connect", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      
      // Set ApexCharts globally for the controller
      global.ApexCharts = MockApexCharts
      
      await controller.connect()
      
      // Wait for async initialization
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(MockApexCharts).toHaveBeenCalledWith(
        element.querySelector('[id^="chart-"]'),
        expect.objectContaining({
          chart: { type: 'line', height: 350 },
          xaxis: { categories: ['Jan', 'Feb', 'Mar'] },
          series: [{ name: 'Sales', data: [30, 40, 35] }]
        })
      )
      expect(mockChart.render).toHaveBeenCalled()
    })
    
    it("sets up resize observer", async () => {
      const mockObserve = jest.fn()
      global.ResizeObserver = jest.fn().mockImplementation(() => ({
        observe: mockObserve,
        disconnect: jest.fn()
      }))
      
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      await controller.connect()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(global.ResizeObserver).toHaveBeenCalled()
      expect(mockObserve).toHaveBeenCalledWith(element)
    })
    
    it("handles missing chart element gracefully", async () => {
      document.body.innerHTML = `
        <div data-controller="chart"
             data-chart-config-value='{"chart":{"type":"line"}}'
             data-chart-series-value='[]'>
          <!-- No chart element -->
        </div>
      `
      
      const element = document.querySelector('[data-controller="chart"]')
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      
      await controller.connect()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(MockApexCharts).not.toHaveBeenCalled()
    })
  })
  
  describe("disconnect", () => {
    it("destroys chart on disconnect", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      await controller.connect()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      controller.disconnect()
      
      expect(mockChart.destroy).toHaveBeenCalled()
    })
    
    it("handles disconnect when no chart exists", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      
      // Should not throw error
      expect(() => controller.disconnect()).not.toThrow()
    })
  })
  
  describe("#updateData", () => {
    it("updates chart with new data", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      await controller.connect()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      const event = new CustomEvent('update', {
        detail: {
          series: [{ name: 'Sales', data: [45, 50, 48] }],
          categories: ['Apr', 'May', 'Jun']
        }
      })
      
      controller.updateData(event)
      
      expect(mockChart.updateOptions).toHaveBeenCalledWith({
        series: [{ name: 'Sales', data: [45, 50, 48] }],
        xaxis: {
          categories: ['Apr', 'May', 'Jun']
        }
      })
    })
    
    it("does nothing if chart not initialized", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      
      const event = new CustomEvent('update', {
        detail: {
          series: [{ name: 'Sales', data: [45, 50, 48] }],
          categories: ['Apr', 'May', 'Jun']
        }
      })
      
      controller.updateData(event)
      
      expect(mockChart.updateOptions).not.toHaveBeenCalled()
    })
  })
  
  describe("value changes", () => {
    it("refreshes chart when config value changes", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      await controller.connect()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      const refreshSpy = jest.spyOn(controller, 'refreshChart')
      
      controller.configValueChanged()
      
      expect(refreshSpy).toHaveBeenCalled()
    })
    
    it("refreshes chart when series value changes", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      await controller.connect()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      const refreshSpy = jest.spyOn(controller, 'refreshChart')
      
      controller.seriesValueChanged()
      
      expect(refreshSpy).toHaveBeenCalled()
    })
  })
  
  describe("#refreshChart", () => {
    it("destroys old chart and creates new one", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      await controller.connect()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      mockChart.destroy.mockClear()
      MockApexCharts.mockClear()
      
      controller.refreshChart()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      expect(mockChart.destroy).toHaveBeenCalled()
      expect(MockApexCharts).toHaveBeenCalled()
      expect(mockChart.render).toHaveBeenCalledTimes(2) // Once on connect, once on refresh
    })
    
    it("handles refresh when no chart exists", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      
      // Should not throw error
      expect(() => controller.refreshChart()).not.toThrow()
    })
  })
  
  describe("resize handling", () => {
    it("updates chart width on resize", async () => {
      let resizeCallback
      global.ResizeObserver = jest.fn().mockImplementation((callback) => {
        resizeCallback = callback
        return {
          observe: jest.fn(),
          disconnect: jest.fn()
        }
      })
      
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      await controller.connect()
      await new Promise(resolve => setTimeout(resolve, 100))
      
      // Trigger resize
      resizeCallback([{ target: element }])
      
      expect(mockChart.updateOptions).toHaveBeenCalledWith({
        chart: {
          width: '100%'
        }
      })
    })
  })
  
  describe("dynamic import fallback", () => {
    it("waits for ApexCharts to load if not available initially", async () => {
      // Reset global ApexCharts
      global.ApexCharts = undefined
      
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      
      // Mock dynamic import
      const importPromise = Promise.resolve({ default: MockApexCharts })
      global.import = jest.fn().mockReturnValue(importPromise)
      
      await controller.initializeChart()
      
      expect(global.import).toHaveBeenCalledWith('apexcharts')
      expect(MockApexCharts).toHaveBeenCalled()
      expect(mockChart.render).toHaveBeenCalled()
    })
  })
  
  describe("chart configuration", () => {
    it("merges config and series values correctly", async () => {
      document.body.innerHTML = `
        <div data-controller="chart"
             data-chart-config-value='{"chart":{"type":"bar","toolbar":{"show":false}},"title":{"text":"Monthly Sales"}}'
             data-chart-series-value='[{"name":"2023","data":[10,20,30]},{"name":"2024","data":[15,25,35]}]'>
          <div id="chart-456"></div>
        </div>
      `
      
      const element = document.querySelector('[data-controller="chart"]')
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      await controller.initializeChart()
      
      expect(MockApexCharts).toHaveBeenCalledWith(
        element.querySelector('#chart-456'),
        expect.objectContaining({
          chart: { type: 'bar', toolbar: { show: false } },
          title: { text: 'Monthly Sales' },
          series: [
            { name: '2023', data: [10, 20, 30] },
            { name: '2024', data: [15, 25, 35] }
          ]
        })
      )
    })
  })
  
  describe("error handling", () => {
    it("handles chart creation errors gracefully", async () => {
      MockApexCharts.mockImplementationOnce(() => {
        throw new Error('Chart creation failed')
      })
      
      const controller = application.getControllerForElementAndIdentifier(element, "chart")
      global.ApexCharts = MockApexCharts
      
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()
      
      await controller.initializeChart()
      
      // Should not throw, but might log error
      expect(controller.chart).toBeUndefined()
      
      consoleSpy.mockRestore()
    })
  })
})