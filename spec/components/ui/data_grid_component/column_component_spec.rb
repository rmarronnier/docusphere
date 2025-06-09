require 'rails_helper'

RSpec.describe Ui::DataGridComponent::ColumnComponent, type: :component do
  describe "initialization" do
    it "sets required attributes" do
      component = described_class.new(key: :name, label: "Name")
      
      expect(component.key).to eq(:name)
      expect(component.label).to eq("Name")
    end

    it "sets default values for optional attributes" do
      component = described_class.new(key: :name, label: "Name")
      
      expect(component.sortable).to be false
      expect(component.width).to be_nil
      expect(component.align).to eq(:left)
      expect(component.format).to be_nil
      expect(component.options).to eq({})
    end

    it "accepts all optional attributes" do
      component = described_class.new(
        key: :amount,
        label: "Amount",
        sortable: true,
        width: "w-32",
        align: :right,
        format: :currency,
        header_class: "custom-header",
        cell_class: "custom-cell"
      )
      
      expect(component.sortable).to be true
      expect(component.width).to eq("w-32")
      expect(component.align).to eq(:right)
      expect(component.format).to eq(:currency)
      expect(component.options).to eq({
        header_class: "custom-header",
        cell_class: "custom-cell"
      })
    end
  end

  describe "#call" do
    it "returns nil" do
      component = described_class.new(key: :name, label: "Name")
      expect(component.call).to be_nil
    end
  end
end