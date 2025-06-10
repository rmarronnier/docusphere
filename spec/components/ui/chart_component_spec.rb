require 'rails_helper'

RSpec.describe Ui::ChartComponent, type: :component do
  let(:sample_data) do
    {
      categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
      series: [
        {
          name: 'Sales',
          data: [30, 40, 35, 50, 49]
        }
      ]
    }
  end

  describe "basic rendering" do
    it "renders chart container with required attributes" do
      render_inline(described_class.new(type: :line, data: sample_data))
      
      expect(page).to have_css(".chart-wrapper")
      expect(page).to have_css("[data-chart-config]")
    end

    it "generates unique chart ID" do
      component1 = described_class.new(type: :bar, data: sample_data)
      component2 = described_class.new(type: :bar, data: sample_data)
      
      render_inline(component1)
      id1 = page.find('[data-chart-config]')['data-chart-id']
      
      render_inline(component2)
      id2 = page.find('[data-chart-config]')['data-chart-id']
      
      expect(id1).not_to eq(id2)
    end

    it "renders with title" do
      render_inline(described_class.new(
        type: :line,
        data: sample_data,
        title: "Monthly Revenue"
      ))
      
      expect(page).to have_text("Monthly Revenue")
    end

    it "renders with subtitle" do
      render_inline(described_class.new(
        type: :line,
        data: sample_data,
        title: "Sales Performance",
        subtitle: "Last 5 months"
      ))
      
      expect(page).to have_text("Sales Performance")
      expect(page).to have_text("Last 5 months")
    end
  end

  describe "chart types" do
    %i[line bar pie donut area].each do |chart_type|
      it "renders #{chart_type} chart" do
        render_inline(described_class.new(type: chart_type, data: sample_data))
        
        expect(page).to have_css("[data-chart-type='#{chart_type}']")
      end
    end

    it "configures pie chart specific options" do
      pie_data = {
        series: [44, 55, 13, 43, 22],
        labels: ['Team A', 'Team B', 'Team C', 'Team D', 'Team E']
      }
      
      render_inline(described_class.new(type: :pie, data: pie_data))
      
      config = page.find('[data-chart-config]')['data-chart-config']
      expect(config).to include('dataLabels')
    end

    it "configures donut chart with center label" do
      donut_data = {
        series: [44, 55, 41, 17],
        labels: ['Q1', 'Q2', 'Q3', 'Q4']
      }
      
      render_inline(described_class.new(type: :donut, data: donut_data))
      
      config = page.find('[data-chart-config]')['data-chart-config']
      expect(config).to include('donut')
    end
  end

  describe "chart height" do
    it "applies default height" do
      render_inline(described_class.new(type: :line, data: sample_data))
      
      expect(page).to have_css(".h-64")
    end

    it "accepts custom height" do
      render_inline(described_class.new(
        type: :bar,
        data: sample_data,
        height: "h-96"
      ))
      
      expect(page).to have_css(".h-96")
      expect(page).not_to have_css(".h-64")
    end
  end

  describe "loading state" do
    it "shows loading skeleton" do
      render_inline(described_class.new(
        type: :line,
        data: {},
        loading: true
      ))
      
      expect(page).to have_css(".animate-spin")
      expect(page).to have_text("Chargement du graphique...")
    end
  end

  describe "custom colors" do
    it "accepts custom color palette" do
      custom_colors = ['#FF0000', '#00FF00', '#0000FF']
      
      render_inline(described_class.new(
        type: :bar,
        data: sample_data,
        colors: custom_colors
      ))
      
      config = page.find('[data-chart-config]')['data-chart-config']
      expect(config).to include('#FF0000')
    end
  end

  describe "data formatting" do
    it "accepts formatter function for tooltip" do
      render_inline(described_class.new(
        type: :line,
        data: sample_data,
        formatter: "function(val) { return '$' + val }"
      ))
      
      config = page.find('[data-chart-config]')['data-chart-config']
      expect(config).to include('formatter')
    end
  end

  describe "custom configuration" do
    it "merges custom config options" do
      custom_config = {
        chart: {
          toolbar: {
            show: true
          }
        },
        grid: {
          show: false
        }
      }
      
      render_inline(described_class.new(
        type: :area,
        data: sample_data,
        config: custom_config
      ))
      
      expect(page).to have_css("[data-chart-config]")
    end
  end

  describe "responsive design" do
    it "has responsive wrapper classes" do
      render_inline(described_class.new(type: :line, data: sample_data))
      
      expect(page).to have_css(".rounded-xl")
      expect(page).to have_css(".border")
      expect(page).to have_css(".shadow-sm")
    end
  end

  describe "accessibility" do
    it "includes proper ARIA attributes for chart region" do
      render_inline(described_class.new(
        type: :bar,
        data: sample_data,
        title: "Sales Chart"
      ))
      
      # Charts should have proper ARIA labels and roles
      expect(page).to have_css("[role='img']")
    end
  end

  describe "multiple series" do
    it "handles multiple data series" do
      multi_series_data = {
        categories: ['Jan', 'Feb', 'Mar'],
        series: [
          { name: 'Series 1', data: [30, 40, 35] },
          { name: 'Series 2', data: [20, 30, 25] },
          { name: 'Series 3', data: [10, 20, 15] }
        ]
      }
      
      render_inline(described_class.new(
        type: :line,
        data: multi_series_data
      ))
      
      expect(page).to have_css("[data-chart-config]")
    end
  end

  describe "empty state" do
    it "handles empty data gracefully" do
      empty_data = {
        categories: [],
        series: []
      }
      
      render_inline(described_class.new(
        type: :line,
        data: empty_data
      ))
      
      expect(page).to have_css(".chart-wrapper")
    end
  end

  describe "stimulus integration" do
    it "includes data attributes for stimulus controller" do
      render_inline(described_class.new(type: :line, data: sample_data))
      
      expect(page).to have_css("[data-controller='chart']")
      expect(page).to have_css("[data-chart-config]")
      expect(page).to have_css("[data-chart-id]")
    end
  end
end