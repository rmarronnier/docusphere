class Ui::MetricCardComponent < ApplicationComponent
  include Themeable
  
  def initialize(title:, value:, subtitle: nil, icon: 'chart-bar', icon_color: 'text-blue-600', 
                 trend: nil, trend_value: nil, bg_color: 'bg-white', value_color: 'text-gray-900',
                 format: :auto, **options)
    @title = title
    @value = value
    @subtitle = subtitle
    @icon = icon
    @icon_color = icon_color
    @trend = trend # :up, :down, :stable
    @trend_value = trend_value
    @bg_color = bg_color
    @value_color = value_color
    @format = format # :auto, :money, :number, :percentage, :none
    @options = options
  end

  private

  attr_reader :title, :value, :subtitle, :icon, :icon_color, :trend, :trend_value, 
              :bg_color, :value_color, :format, :options

  def trend_icon
    case trend
    when :up
      'trending-up'
    when :down
      'trending-down'
    else
      'minus'
    end
  end

  def trend_color
    case trend
    when :up
      'text-green-600'
    when :down
      'text-red-600'
    else
      'text-gray-500'
    end
  end

  def formatted_value
    case @format
    when :money
      format_as_money
    when :number
      format_as_number
    when :percentage
      format_as_percentage
    when :none
      value.to_s
    else # :auto
      auto_format_value
    end
  end

  def auto_format_value
    case value
    when Money
      format_as_money
    when Numeric
      if value.to_s.include?('.')
        format_as_decimal
      else
        format_as_number
      end
    else
      value.to_s
    end
  end

  def format_as_money
    if value.respond_to?(:format)
      value.format(symbol: true, thousands_separator: ' ')
    else
      helpers.number_to_currency(value, unit: '€', separator: ',', delimiter: ' ')
    end
  end

  def format_as_number
    helpers.number_with_delimiter(value)
  end

  def format_as_decimal
    helpers.number_with_precision(value, precision: 2, delimiter: ' ')
  end

  def format_as_percentage
    "#{helpers.number_with_precision(value, precision: 1)}%"
  end

  def card_classes
    classes = [@bg_color, 'rounded-lg shadow p-6']
    classes << @options[:class] if @options[:class]
    classes.join(' ')
  end
end