# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Forms::AdvancedSearchComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:search_params) { {} }
  let(:show_saved_searches) { true }
  let(:component) { described_class.new(user: user, search_params: search_params, show_saved_searches: show_saved_searches) }

  before do
    # Mock AdvancedSearchService
    search_service = instance_double(AdvancedSearchService)
    allow(AdvancedSearchService).to receive(:new).and_return(search_service)
    allow(search_service).to receive(:saved_searches).and_return([])
    
    # Mock route helpers for tests
    without_partial_double_verification do
      test_helpers = double('helpers')
      allow_any_instance_of(Forms::AdvancedSearchComponent).to receive(:helpers).and_return(test_helpers)
      allow(test_helpers).to receive(:search_documents_path).and_return('/search')
      allow(test_helpers).to receive(:search_suggestions_path).and_return('/search/suggestions')
      allow(test_helpers).to receive(:params).and_return(ActionController::Parameters.new({}))
      allow(test_helpers).to receive(:url_for).and_return('/')
    end
  end

  describe '#initialize' do
    it 'accepts user, search params and show saved searches flag' do
      expect(component).to be_a(described_class)
    end

    it 'initializes search service' do
      expect(AdvancedSearchService).to receive(:new).with(user, search_params.with_indifferent_access)
      component
    end
  end

  describe '#category_options' do
    let!(:space) { create(:space, organization: organization) }
    let!(:document1) { create(:document, space: space, document_category: 'contract') }
    let!(:document2) { create(:document, space: space, document_category: 'invoice') }
    let!(:document3) { create(:document, space: space, document_category: nil) }

    it 'returns unique categories from user organization' do
      categories = component.send(:category_options)
      expect(categories).to contain_exactly(['Contract', 'contract'], ['Invoice', 'invoice'])
    end

    it 'excludes documents from other organizations' do
      other_org = create(:organization)
      other_space = create(:space, organization: other_org)
      create(:document, space: other_space, document_category: 'report')

      categories = component.send(:category_options)
      expect(categories.map(&:last)).not_to include('report')
    end
  end

  describe '#status_options' do
    it 'returns all document status options' do
      options = component.send(:status_options)
      expect(options).to eq([
        ['Brouillon', 'draft'],
        ['Publié', 'published'],
        ['En révision', 'under_review'],
        ['Verrouillé', 'locked'],
        ['Archivé', 'archived']
      ])
    end
  end

  describe '#date_range_options' do
    it 'returns date range options' do
      options = component.send(:date_range_options)
      expect(options.map(&:last)).to eq(['today', 'yesterday', 'this_week', 'this_month', 'this_year', 'custom'])
    end
  end

  describe '#content_type_options' do
    it 'returns common content type options' do
      options = component.send(:content_type_options)
      expect(options.map(&:first)).to include('PDF', 'Images', 'Documents Word', 'Documents Excel')
    end
  end

  describe '#available_users' do
    let!(:user_with_docs) { create(:user, organization: organization) }
    let!(:user_without_docs) { create(:user, organization: organization) }
    let!(:space) { create(:space, organization: organization) }
    let!(:document) { create(:document, uploaded_by: user_with_docs, space: space) }

    it 'returns users who have uploaded documents' do
      users = component.send(:available_users)
      user_ids = users.map(&:last)
      expect(user_ids).to include(user_with_docs.id)
      expect(user_ids).not_to include(user_without_docs.id)
    end
  end

  describe '#available_projects' do
    context 'when ImmoPromo is not defined' do
      before do
        hide_const('Immo::Promo::Project') if defined?(Immo::Promo::Project)
      end

      it 'returns empty array' do
        expect(component.send(:available_projects)).to eq([])
      end
    end

    context 'when ImmoPromo is defined' do
      let(:project_class) { class_double('Immo::Promo::Project') }
      let(:active_scope) { double('active_scope') }
      let(:projects) { double('projects') }

      before do
        stub_const('Immo::Promo::Project', project_class)
        allow(user).to receive(:active_profile).and_return(double(profile_type: 'direction'))
        allow(project_class).to receive(:where).and_return(active_scope)
        allow(active_scope).to receive(:active).and_return(projects)
        allow(projects).to receive(:order).and_return(projects)
        allow(projects).to receive(:pluck).and_return([['Project 1', 1], ['Project 2', 2]])
      end

      it 'returns projects based on user profile' do
        expect(component.send(:available_projects)).to eq([['Project 1', 1], ['Project 2', 2]])
      end
    end
  end

  describe '#popular_tags' do
    let!(:space) { create(:space, organization: organization) }
    let!(:tag1) { create(:tag, name: 'important', organization: organization) }
    let!(:tag2) { create(:tag, name: 'urgent', organization: organization) }
    let!(:documents) { create_list(:document, 3, space: space) }

    before do
      documents.each { |doc| doc.tags << tag1 }
      documents.first(2).each { |doc| doc.tags << tag2 }
    end

    it 'returns tags ordered by usage count' do
      tags = component.send(:popular_tags)
      expect(tags.first[:name]).to eq('important')
      expect(tags.first[:count]).to eq(3)
      expect(tags.second[:name]).to eq('urgent')
      expect(tags.second[:count]).to eq(2)
    end
  end

  describe '#parse_size_to_bytes' do
    it 'parses KB values' do
      expect(component.send(:parse_size_to_bytes, '100KB')).to eq(100.kilobytes)
      expect(component.send(:parse_size_to_bytes, '50k')).to eq(50.kilobytes)
    end

    it 'parses MB values' do
      expect(component.send(:parse_size_to_bytes, '10MB')).to eq(10.megabytes)
      expect(component.send(:parse_size_to_bytes, '5m')).to eq(5.megabytes)
    end

    it 'parses GB values' do
      expect(component.send(:parse_size_to_bytes, '2GB')).to eq(2.gigabytes)
      expect(component.send(:parse_size_to_bytes, '1g')).to eq(1.gigabyte)
    end

    it 'parses numeric values as bytes' do
      expect(component.send(:parse_size_to_bytes, '1024')).to eq(1024)
    end

    it 'returns nil for invalid values' do
      expect(component.send(:parse_size_to_bytes, 'invalid')).to be_nil
      expect(component.send(:parse_size_to_bytes, '')).to be_nil
    end
  end

  describe '#show_custom_date_fields?' do
    context 'when date range is custom' do
      let(:search_params) { { date_range: 'custom' } }

      it 'returns true' do
        expect(component.send(:show_custom_date_fields?)).to be true
      end
    end

    context 'when date range is not custom' do
      let(:search_params) { { date_range: 'this_week' } }

      it 'returns false' do
        expect(component.send(:show_custom_date_fields?)).to be false
      end
    end
  end

  describe '#active_filters_count' do
    context 'with no filters' do
      it 'returns 0' do
        expect(component.send(:active_filters_count)).to eq(0)
      end
    end

    context 'with active filters' do
      let(:search_params) do
        {
          query: 'test',
          categories: ['contract'],
          date_range: 'this_week',
          sort_by: 'created_at', # Should be excluded
          sort_order: 'desc' # Should be excluded
        }
      end

      it 'counts filters excluding sort options' do
        expect(component.send(:active_filters_count)).to eq(3)
      end
    end
  end

  describe '#has_active_filters?' do
    context 'with no filters' do
      it 'returns false' do
        expect(component.send(:has_active_filters?)).to be false
      end
    end

    context 'with filters' do
      let(:search_params) { { query: 'test' } }

      it 'returns true' do
        expect(component.send(:has_active_filters?)).to be true
      end
    end
  end

  describe '#stimulus_controllers' do
    it 'returns all required stimulus controllers' do
      controllers = component.send(:stimulus_controllers)
      expect(controllers).to include('advanced-search')
      expect(controllers).to include('tag-selector')
      expect(controllers).to include('date-picker')
      expect(controllers).to include('autocomplete')
    end
  end

  describe 'rendering' do
    it 'renders successfully' do
      render_inline(component)
      expect(page).to have_css('.advanced-search-component')
    end

    it 'renders search form' do
      render_inline(component)
      expect(page).to have_css('form#advanced-search-form')
    end

    it 'renders main search input' do
      render_inline(component)
      expect(page).to have_field('query')
    end

    it 'renders accordion sections' do
      render_inline(component)
      expect(page).to have_text('Catégories et statuts')
      expect(page).to have_text('Types de fichiers')
      expect(page).to have_text('Dates')
      expect(page).to have_text('Tags')
      expect(page).to have_text('Autres critères')
      expect(page).to have_text('Tri et affichage')
    end

    context 'with active filters' do
      let(:search_params) { { query: 'test', categories: ['contract'] } }

      it 'shows active filters count' do
        render_inline(component)
        expect(page).to have_text('2 filtres actifs')
      end

      it 'shows reset link' do
        render_inline(component)
        expect(page).to have_link('Réinitialiser')
      end
    end

    context 'with saved searches' do
      let(:saved_search) { double(id: 1, name: 'Ma recherche') }

      before do
        search_service = instance_double(AdvancedSearchService)
        allow(AdvancedSearchService).to receive(:new).and_return(search_service)
        allow(search_service).to receive(:saved_searches).and_return([saved_search])
      end

      it 'shows saved searches dropdown' do
        render_inline(component)
        expect(page).to have_text('Recherches sauvegardées')
      end
    end

    context 'with selected filters' do
      let!(:space) { create(:space, organization: organization) }
      let!(:doc1) { create(:document, space: space, document_category: 'contract') }
      let!(:doc2) { create(:document, space: space, document_category: 'invoice') }
      
      let(:search_params) do
        {
          categories: ['contract', 'invoice'],
          statuses: ['draft'],
          tags: ['important', 'urgent']
        }
      end

      it 'checks selected categories' do
        render_inline(component)
        within('.advanced-search-component') do
          expect(page).to have_checked_field('Contract')
          expect(page).to have_checked_field('Invoice')
        end
      end

      it 'checks selected statuses' do
        render_inline(component)
        within('.advanced-search-component') do
          expect(page).to have_checked_field('Brouillon')
        end
      end

      it 'displays selected tags' do
        render_inline(component)
        expect(page).to have_text('important')
        expect(page).to have_text('urgent')
        expect(page).to have_css('input[type="hidden"][name="search[tags][]"][value="important"]', visible: false)
        expect(page).to have_css('input[type="hidden"][name="search[tags][]"][value="urgent"]', visible: false)
      end
    end

    context 'with custom date range' do
      let(:search_params) { { date_range: 'custom' } }

      it 'shows custom date fields' do
        render_inline(component)
        expect(page).to have_field('date_from')
        expect(page).to have_field('date_to')
      end
    end
  end
end