class Ui::ChartComponent < ApplicationComponent
  def initialize(type:, data:, title: nil, subtitle: nil, height: "h-64", loading: false, **options)
    @type = type # :line, :bar, :pie, :donut, :area
    @data = data
    @title = title
    @subtitle = subtitle
    @height = height
    @loading = loading
    @options = options
    @chart_id = "chart-#{SecureRandom.hex(8)}"
  end

  private

  attr_reader :type, :data, :title, :subtitle, :height, :loading, :options, :chart_id

  def chart_config
    base_config = {
      chart: {
        type: chart_type,
        height: "100%",
        toolbar: {
          show: false
        },
        animations: {
          enabled: true,
          easing: 'easeinout',
          speed: 800,
          animateGradually: {
            enabled: true,
            delay: 150
          },
          dynamicAnimation: {
            enabled: true,
            speed: 350
          }
        }
      },
      colors: chart_colors,
      dataLabels: {
        enabled: type == :pie || type == :donut
      },
      stroke: {
        curve: 'smooth',
        width: type == :line ? 3 : 0
      },
      grid: {
        borderColor: '#e5e7eb',
        strokeDashArray: 4,
        xaxis: {
          lines: {
            show: false
          }
        }
      },
      xaxis: {
        categories: data[:categories] || [],
        labels: {
          style: {
            colors: '#6b7280',
            fontSize: '12px'
          }
        }
      },
      yaxis: {
        labels: {
          style: {
            colors: '#6b7280',
            fontSize: '12px'
          }
        }
      },
      legend: {
        position: 'bottom',
        horizontalAlign: 'center',
        labels: {
          colors: '#374151'
        }
      },
      tooltip: {
        theme: 'light',
        y: {
          formatter: options[:formatter] || nil
        }
      }
    }

    # Type-specific configurations
    case type
    when :donut
      base_config[:plotOptions] = {
        pie: {
          donut: {
            size: '65%',
            labels: {
              show: true,
              total: {
                show: true,
                showAlways: true,
                fontSize: '22px',
                fontWeight: 600,
                color: '#374151'
              }
            }
          }
        }
      }
    when :area
      base_config[:fill] = {
        type: 'gradient',
        gradient: {
          shadeIntensity: 1,
          opacityFrom: 0.4,
          opacityTo: 0.1,
          stops: [0, 90, 100]
        }
      }
    end

    base_config.deep_merge(options[:config] || {})
  end

  def chart_type
    case type
    when :line then 'line'
    when :bar then 'bar'
    when :pie then 'pie'
    when :donut then 'donut'
    when :area then 'area'
    else 'line'
    end
  end

  def chart_colors
    options[:colors] || ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#14b8a6', '#f97316']
  end

  def chart_series
    data[:series] || []
  end

  def wrapper_classes
    classes = ["chart-wrapper bg-white rounded-xl border border-gray-200 p-6 shadow-sm"]
    classes << height
    classes << options[:class] if options[:class]
    classes.join(" ")
  end
end