# Concern for services that perform calculations and metrics
module Calculable
  extend ActiveSupport::Concern

  included do
    attr_reader :calculation_cache
    
    def initialize(*args)
      super
      @calculation_cache = {}
    end
  end

  # Calculate percentage with proper rounding
  def calculate_percentage(numerator, denominator, precision: 2)
    return 0.0 if denominator.zero?
    ((numerator.to_f / denominator.to_f) * 100).round(precision)
  end

  # Calculate progress between dates
  def calculate_time_progress(start_date, end_date, current_date = Date.current)
    return 0.0 if start_date >= end_date
    return 100.0 if current_date >= end_date
    return 0.0 if current_date <= start_date
    
    total_duration = (end_date - start_date).to_f
    elapsed_duration = (current_date - start_date).to_f
    
    calculate_percentage(elapsed_duration, total_duration)
  end

  # Calculate weighted average
  def calculate_weighted_average(values_with_weights)
    return 0.0 if values_with_weights.empty?
    
    total_weighted_sum = 0.0
    total_weights = 0.0
    
    values_with_weights.each do |value, weight|
      total_weighted_sum += value * weight
      total_weights += weight
    end
    
    return 0.0 if total_weights.zero?
    total_weighted_sum / total_weights
  end

  # Calculate trend (growth rate)
  def calculate_trend(old_value, new_value)
    return 0.0 if old_value.zero?
    calculate_percentage(new_value - old_value, old_value)
  end

  # Calculate compound growth rate
  def calculate_cagr(start_value, end_value, periods)
    return 0.0 if start_value.zero? || periods.zero?
    ((end_value.to_f / start_value.to_f) ** (1.0 / periods) - 1) * 100
  end

  # Calculate moving average
  def calculate_moving_average(values, window_size)
    return [] if values.empty? || window_size <= 0
    
    (0...(values.size - window_size + 1)).map do |i|
      window = values[i, window_size]
      window.sum.to_f / window.size
    end
  end

  # Format number with proper locale
  def format_number(number, type: :decimal, precision: 2)
    case type
    when :currency
      format_currency(number)
    when :percentage
      "#{number.round(precision)}%"
    when :integer
      number.to_i.to_s(:delimited)
    else
      number.round(precision).to_s(:delimited)
    end
  end

  # Format currency with proper symbol
  def format_currency(amount, currency: 'EUR')
    case currency.upcase
    when 'EUR'
      "#{amount.round(2).to_s(:delimited)} €"
    when 'USD'
      "$#{amount.round(2).to_s(:delimited)}"
    else
      "#{amount.round(2).to_s(:delimited)} #{currency}"
    end
  end

  # Format duration in human readable format
  def format_duration(days)
    case days
    when 0...7
      "#{days} jour#{'s' if days > 1}"
    when 7...30
      weeks = (days / 7.0).round(1)
      "#{weeks} semaine#{'s' if weeks > 1}"
    when 30...365
      months = (days / 30.0).round(1)
      "#{months} mois"
    else
      years = (days / 365.0).round(1)
      "#{years} année#{'s' if years > 1}"
    end
  end

  # Calculate business days between dates
  def calculate_business_days(start_date, end_date)
    return 0 if start_date >= end_date
    
    total_days = (end_date - start_date).to_i
    full_weeks = total_days / 7
    extra_days = total_days % 7
    
    business_days = full_weeks * 5
    
    # Handle extra days
    current_date = start_date + (full_weeks * 7).days
    extra_days.times do
      business_days += 1 unless weekend?(current_date)
      current_date += 1.day
    end
    
    business_days
  end

  # Cached calculation to avoid repeated computation
  def cached_calculation(key, &block)
    return @calculation_cache[key] if @calculation_cache.key?(key)
    
    @calculation_cache[key] = yield
  end

  # Clear calculation cache
  def clear_calculation_cache!
    @calculation_cache.clear
  end

  private

  def weekend?(date)
    date.saturday? || date.sunday?
  end

  # Calculate variance for a dataset
  def calculate_variance(values)
    return 0.0 if values.size < 2
    
    mean = values.sum.to_f / values.size
    sum_of_squares = values.map { |v| (v - mean) ** 2 }.sum
    sum_of_squares / (values.size - 1)
  end

  # Calculate standard deviation
  def calculate_standard_deviation(values)
    Math.sqrt(calculate_variance(values))
  end

  # Statistical analysis for trends
  def analyze_trend(values)
    return nil if values.size < 2
    
    {
      mean: values.sum.to_f / values.size,
      median: calculate_median(values),
      variance: calculate_variance(values),
      std_deviation: calculate_standard_deviation(values),
      min: values.min,
      max: values.max,
      range: values.max - values.min
    }
  end

  def calculate_median(values)
    sorted = values.sort
    size = sorted.size
    
    if size.even?
      (sorted[size / 2 - 1] + sorted[size / 2]).to_f / 2
    else
      sorted[size / 2].to_f
    end
  end
end