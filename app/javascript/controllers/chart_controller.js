import { Controller } from "@hotwired/stimulus"

// Note: You'll need to install ApexCharts
// Run: yarn add apexcharts or npm install apexcharts
// Then import it in your application.js
let ApexCharts;
if (typeof window !== 'undefined') {
  import('apexcharts').then(module => {
    ApexCharts = module.default;
  });
}

export default class extends Controller {
  static values = { 
    config: Object,
    series: Array
  }

  connect() {
    this.initializeChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  async initializeChart() {
    // Wait for ApexCharts to be loaded
    if (!ApexCharts) {
      const module = await import('apexcharts');
      ApexCharts = module.default;
    }

    const chartElement = this.element.querySelector('[id^="chart-"]')
    if (!chartElement) return

    const options = {
      ...this.configValue,
      series: this.seriesValue
    }

    this.chart = new ApexCharts(chartElement, options)
    this.chart.render()

    // Add resize observer for responsive charts
    this.resizeObserver = new ResizeObserver(() => {
      if (this.chart) {
        this.chart.updateOptions({
          chart: {
            width: '100%'
          }
        })
      }
    })
    this.resizeObserver.observe(this.element)
  }

  updateData(event) {
    const { series, categories } = event.detail
    
    if (this.chart) {
      this.chart.updateOptions({
        series: series,
        xaxis: {
          categories: categories
        }
      })
    }
  }

  configValueChanged() {
    this.refreshChart()
  }

  seriesValueChanged() {
    this.refreshChart()
  }

  refreshChart() {
    if (this.chart) {
      this.chart.destroy()
    }
    this.initializeChart()
  }
}