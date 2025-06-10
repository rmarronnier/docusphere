require 'rails_helper'

RSpec.describe BaseFormComponent, type: :component do
  describe 'constants' do
    it 'defines FieldComponent' do
      expect(described_class::FieldComponent).to be < ApplicationComponent
    end

    it 'defines TextFieldComponent' do
      expect(described_class::TextFieldComponent).to be < described_class::FieldComponent
    end

    it 'defines TextAreaComponent' do
      expect(described_class::TextAreaComponent).to be < described_class::FieldComponent
    end

    it 'defines SelectComponent' do
      expect(described_class::SelectComponent).to be < described_class::FieldComponent
    end

    it 'defines CheckboxComponent' do
      expect(described_class::CheckboxComponent).to be < described_class::FieldComponent
    end

    it 'defines RadioGroupComponent' do
      expect(described_class::RadioGroupComponent).to be < described_class::FieldComponent
    end
  end

  describe 'inheritance hierarchy' do
    it 'all field components inherit from FieldComponent' do
      [
        described_class::TextFieldComponent,
        described_class::TextAreaComponent,
        described_class::SelectComponent,
        described_class::CheckboxComponent,
        described_class::RadioGroupComponent
      ].each do |klass|
        expect(klass).to be < described_class::FieldComponent
      end
    end
    
    it 'FieldComponent inherits from ApplicationComponent' do
      expect(described_class::FieldComponent).to be < ApplicationComponent
    end
  end

  describe 'as abstract base class' do
    it 'is designed to contain nested form field components' do
      expect(described_class.constants).to include(:FieldComponent)
      expect(described_class.constants).to include(:TextFieldComponent)
      expect(described_class.constants).to include(:TextAreaComponent)
      expect(described_class.constants).to include(:SelectComponent)
      expect(described_class.constants).to include(:CheckboxComponent)
      expect(described_class.constants).to include(:RadioGroupComponent)
    end
  end
end