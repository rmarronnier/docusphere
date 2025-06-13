require "rails_helper"

RSpec.describe Immo::Promo::Shared::FilterFormComponent, type: :component do
  let(:action_url) { "/test/path" }
  let(:current_params) { {} }
  let(:basic_filters) do
    [
      {
        name: :status,
        type: :select,
        label: "Statut",
        options: [
          ['Tous les statuts', ''],
          ['Actif', 'active'],
          ['Inactif', 'inactive']
        ]
      },
      {
        name: :search,
        type: :search,
        placeholder: "Rechercher..."
      }
    ]
  end

  describe "#initialize" do
    it "sets default values correctly" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url
      )

      expect(component.filters).to eq(basic_filters)
      expect(component.action_url).to eq(action_url)
      expect(component.method).to eq(:get)
      expect(component.current_params).to eq({})
      expect(component.auto_submit).to be(true)
      expect(component.show_reset).to be(true)
    end

    it "accepts custom parameters" do
      custom_params = { status: "active", page: 2 }
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        method: :post,
        current_params: custom_params,
        auto_submit: false,
        show_reset: false
      )

      expect(component.method).to eq(:post)
      expect(component.current_params).to eq(custom_params)
      expect(component.auto_submit).to be(false)
      expect(component.show_reset).to be(false)
    end
  end

  describe "#css_class" do
    it "returns default CSS classes" do
      component = described_class.new(filters: basic_filters, action_url: action_url)
      expect(component.css_class).to eq("bg-white shadow rounded-lg p-4")
    end

    it "includes custom CSS class when provided" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        css_class: "custom-class"
      )
      expect(component.css_class).to eq("bg-white shadow rounded-lg p-4 custom-class")
    end
  end

  describe "#form_css_classes" do
    it "returns basic form classes when auto_submit is false" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        auto_submit: false
      )
      expect(component.form_css_classes).to eq("flex flex-wrap gap-4 items-end")
    end

    it "includes filter-form class when auto_submit is true" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        auto_submit: true
      )
      expect(component.form_css_classes).to eq("flex flex-wrap gap-4 items-end filter-form")
    end
  end

  describe "#stimulus_attributes" do
    it "returns empty hash when auto_submit is false" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        auto_submit: false
      )
      expect(component.stimulus_attributes).to eq({})
    end

    it "returns stimulus data attributes when auto_submit is true" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        auto_submit: true
      )
      expected = {
        data: {
          controller: "filter-form",
          "filter-form-auto-submit-value": "true"
        }
      }
      expect(component.stimulus_attributes).to eq(expected)
    end
  end

  describe "#selected_value_for" do
    let(:current_params) { { status: "active", search: "test" } }
    let(:component) do
      described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: current_params
      )
    end

    it "returns the correct value for string keys" do
      filter = { name: :status }
      expect(component.selected_value_for(filter)).to eq("active")
    end

    it "returns the correct value for symbol keys" do
      filter = { name: "search" }
      expect(component.selected_value_for(filter)).to eq("test")
    end

    it "returns empty string when no value is set" do
      filter = { name: :nonexistent }
      expect(component.selected_value_for(filter)).to eq("")
    end
  end

  describe "#has_active_filters?" do
    it "returns false when no filters have values" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: {}
      )
      expect(component.has_active_filters?).to be(false)
    end

    it "returns true when at least one filter has a value" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: { status: "active" }
      )
      expect(component.has_active_filters?).to be(true)
    end

    it "ignores empty string values" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: { status: "", search: "" }
      )
      expect(component.has_active_filters?).to be(false)
    end
  end

  describe "#reset_url" do
    it "returns action_url when no other params" do
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: { status: "active" }
      )
      expect(component.reset_url).to eq(action_url)
    end

    it "preserves non-filter parameters" do
      params = { status: "active", search: "test", page: 2, per_page: 20 }
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: params
      )
      expect(component.reset_url).to eq("#{action_url}?page=2&per_page=20")
    end

    it "removes all filter parameters" do
      params = { status: "active", search: "test", other_param: "keep" }
      component = described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: params
      )
      expect(component.reset_url).to eq("#{action_url}?other_param=keep")
    end
  end

  describe "rendering" do
    let(:current_params) { { status: "active" } }
    let(:component) do
      described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: current_params
      )
    end

    before do
      render_inline(component)
    end

    it "renders a form with the correct action" do
      expect(page).to have_css("form[action='#{action_url}']")
    end

    it "renders select filters correctly" do
      expect(page).to have_select("status")
      select_element = page.find("select[name='status']")
      expect(select_element.value).to eq("active")
      expect(page).to have_css("label", text: "Statut")
    end

    it "renders search filters correctly" do
      expect(page).to have_field("search", type: "text")
      expect(page).to have_field("search", placeholder: "Rechercher...")
      expect(page).to have_css(".relative input[type='text'].pl-10")
    end

    it "includes stimulus data attributes when auto_submit is true" do
      expect(page).to have_css("[data-controller='filter-form']")
      expect(page).to have_css("[data-filter-form-auto-submit-value='true']")
    end

    it "shows reset button when filters are active" do
      expect(page).to have_link("Réinitialiser")
    end

    it "shows active filters indicator" do
      expect(page).to have_text("Filtres actifs - Les résultats sont automatiquement mis à jour")
    end
  end

  describe "rendering without auto_submit" do
    let(:component) do
      described_class.new(
        filters: basic_filters,
        action_url: action_url,
        auto_submit: false
      )
    end

    before do
      render_inline(component)
    end

    it "shows submit button when auto_submit is false" do
      expect(page).to have_button("Filtrer")
    end

    it "does not include stimulus data attributes" do
      expect(page).not_to have_css("[data-controller='filter-form']")
    end
  end

  describe "rendering different filter types" do
    let(:comprehensive_filters) do
      [
        {
          name: :text_field,
          type: :text,
          label: "Nom",
          placeholder: "Saisir un nom"
        },
        {
          name: :date_field,
          type: :date,
          label: "Date"
        },
        {
          name: :custom_select,
          type: :select,
          options: [["Option 1", "1"], ["Option 2", "2"]],
          container_class: "w-48"
        }
      ]
    end

    let(:component) do
      described_class.new(
        filters: comprehensive_filters,
        action_url: action_url
      )
    end

    before do
      render_inline(component)
    end

    it "renders text field correctly" do
      expect(page).to have_field("text_field", type: "text")
      expect(page).to have_field("text_field", placeholder: "Saisir un nom")
      expect(page).to have_css("label", text: "Nom")
    end

    it "renders date field correctly" do
      expect(page).to have_field("date_field", type: "date")
      expect(page).to have_css("label", text: "Date")
    end

    it "applies custom container classes" do
      expect(page).to have_css(".w-48")
    end
  end

  describe "rendering without active filters" do
    let(:component) do
      described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: {}
      )
    end

    before do
      render_inline(component)
    end

    it "does not show reset button when no filters are active" do
      expect(page).not_to have_link("Réinitialiser")
    end

    it "does not show active filters indicator" do
      expect(page).not_to have_text("Filtres actifs")
    end
  end

  describe "rendering with show_reset disabled" do
    let(:component) do
      described_class.new(
        filters: basic_filters,
        action_url: action_url,
        current_params: { status: "active" },
        show_reset: false
      )
    end

    before do
      render_inline(component)
    end

    it "does not show reset button even when filters are active" do
      expect(page).not_to have_link("Réinitialiser")
    end
  end
end