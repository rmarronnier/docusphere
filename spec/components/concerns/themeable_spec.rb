require 'rails_helper'

RSpec.describe Themeable do
  let(:test_class) do
    Class.new(ApplicationComponent) do
      include Themeable
      
      def initialize(theme: :primary, size: :default, variant: :default)
        @theme = theme
        @size = size
        @variant = variant
      end
    end
  end
  
  let(:component) { test_class.new }

  describe 'THEME_COLORS' do
    it 'defines color schemes for all themes' do
      %i[primary secondary success danger warning info].each do |theme|
        expect(Themeable::THEME_COLORS).to have_key(theme)
        expect(Themeable::THEME_COLORS[theme]).to include(:bg, :text, :hover, :focus, :light, :light_text)
      end
    end
  end

  describe 'SIZES' do
    it 'defines size configurations' do
      %i[xs sm default lg xl].each do |size|
        expect(Themeable::SIZES).to have_key(size)
        expect(Themeable::SIZES[size]).to include(:text, :padding, :gap)
      end
    end
  end

  describe '#theme_colors' do
    context 'default variant' do
      it 'returns full theme colors' do
        colors = component.theme_colors
        expect(colors[:bg]).to eq 'bg-indigo-600'
        expect(colors[:text]).to eq 'text-white'
        expect(colors[:hover]).to eq 'hover:bg-indigo-700'
      end
    end

    context 'light variant' do
      it 'returns light theme colors' do
        colors = component.theme_colors(:light)
        expect(colors[:bg]).to eq 'bg-indigo-100'
        expect(colors[:text]).to eq 'text-indigo-800'
      end
    end

    context 'outline variant' do
      it 'returns outline theme colors' do
        colors = component.theme_colors(:outline)
        expect(colors[:bg]).to eq 'bg-transparent'
        expect(colors[:text]).to eq 'text-indigo-800'
        expect(colors[:border]).to include 'border-2'
      end
    end

    context 'with unknown theme' do
      let(:component) { test_class.new(theme: :unknown) }

      it 'defaults to primary colors' do
        colors = component.theme_colors
        expect(colors[:bg]).to eq 'bg-indigo-600'
      end
    end
  end

  describe '#size_classes' do
    %i[xs sm default lg xl].each do |size|
      context "with #{size} size" do
        let(:component) { test_class.new(size: size) }

        it 'returns correct size classes' do
          classes = component.size_classes
          expect(classes[:text]).to be_present
          expect(classes[:padding]).to be_present
          expect(classes[:gap]).to be_present
        end
      end
    end

    context 'with unknown size' do
      let(:component) { test_class.new(size: :unknown) }

      it 'defaults to default size' do
        classes = component.size_classes
        expect(classes).to eq Themeable::SIZES[:default]
      end
    end
  end

  describe '#themed_classes' do
    it 'combines theme and size classes' do
      classes = component.themed_classes('custom-class')
      expect(classes).to include('bg-indigo-600')
      expect(classes).to include('text-white')
      expect(classes).to include('text-base')
      expect(classes).to include('px-4 py-2')
      expect(classes).to include('custom-class')
    end

    context 'with light variant' do
      let(:component) { test_class.new(variant: :light) }

      it 'does not include hover classes' do
        classes = component.themed_classes
        expect(classes).not_to include('hover:')
      end
    end
  end

  describe '#color_class' do
    it 'generates color class' do
      expect(component.color_class('red', 'bg', 500)).to eq 'bg-red-500'
      expect(component.color_class('blue', 'text', 700)).to eq 'text-blue-700'
      expect(component.color_class('green', 'border', 300)).to eq 'border-green-300'
    end
  end

  describe '#merge_classes' do
    it 'merges without conflicts when no overlaps' do
      result = component.merge_classes('bg-blue-500 text-white', 'font-bold rounded')
      expect(result).to include('bg-blue-500', 'text-white', 'font-bold', 'rounded')
    end

    it 'replaces conflicting classes' do
      result = component.merge_classes('bg-blue-500 text-white', 'bg-red-500')
      expect(result).to include('bg-red-500')
      expect(result).not_to include('bg-blue-500')
      expect(result).to include('text-white')
    end

    it 'handles multiple prefixes' do
      result = component.merge_classes(
        'bg-blue-500 text-white px-4 py-2',
        'bg-red-500 text-black px-6'
      )
      expect(result).to include('bg-red-500', 'text-black', 'px-6', 'py-2')
      expect(result).not_to include('bg-blue-500', 'text-white', 'px-4')
    end

    it 'handles empty custom classes' do
      result = component.merge_classes('bg-blue-500 text-white', '')
      expect(result).to eq 'bg-blue-500 text-white'
    end
  end

  describe '.available_themes' do
    let(:test_class) do
      Class.new(ApplicationComponent) do
        include Themeable
        
        available_themes :primary, :secondary, :success
        
        def initialize(theme: :primary)
          @theme = theme
          validate_theme
        end
      end
    end

    it 'validates theme selection' do
      component = test_class.new(theme: :primary)
      expect(component.instance_variable_get(:@theme)).to eq :primary
    end

    it 'defaults to first available theme for invalid selection' do
      component = test_class.new(theme: :invalid)
      expect(component.instance_variable_get(:@theme)).to eq :primary
    end
  end

  describe '.available_sizes' do
    let(:test_class) do
      Class.new(ApplicationComponent) do
        include Themeable
        
        available_sizes :sm, :default, :lg
        
        def initialize(size: :default)
          @size = size
          validate_size
        end
      end
    end

    it 'validates size selection' do
      component = test_class.new(size: :sm)
      expect(component.instance_variable_get(:@size)).to eq :sm
    end

    it 'defaults to :default for invalid selection' do
      component = test_class.new(size: :invalid)
      expect(component.instance_variable_get(:@size)).to eq :default
    end
  end
end