require 'rails_helper'

RSpec.describe Documents::ActivityTimelineComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:space) { create(:space, organization: organization) }
  let(:document) { create(:document, space: space, uploaded_by: user) }
  
  before do
    allow_any_instance_of(Documents::ActivityTimelineComponent).to receive(:heroicon).and_return('<svg></svg>'.html_safe)
  end

  describe 'initialization' do
    it 'renders with required parameters' do
      component = described_class.new(document: document)
      
      expect(component).to be_a(described_class)
    end

    it 'accepts optional parameters' do
      component = described_class.new(
        document: document,
        limit: 10,
        show_filters: false
      )
      
      expect(component).to be_a(described_class)
    end
  end

  describe 'activity filters' do
    context 'when show_filters is true' do
      it 'displays filter tabs' do
        render_inline(described_class.new(document: document, show_filters: true))
        
        expect(page).to have_css('nav[aria-label="Activity filters"]')
        expect(page).to have_text('All Activities')
        expect(page).to have_text('Updates')
        expect(page).to have_text('Validations')
        expect(page).to have_text('Shares')
        expect(page).to have_text('Versions')
      end
    end

    context 'when show_filters is false' do
      it 'does not display filter tabs' do
        render_inline(described_class.new(document: document, show_filters: false))
        
        expect(page).not_to have_css('nav[aria-label="Activity filters"]')
      end
    end
  end

  describe 'activities display' do
    let(:audit) { double(
      action: 'create',
      user: user,
      created_at: 2.days.ago,
      audited_changes: {}
    ) }

    before do
      allow(document).to receive(:audits).and_return([audit])
      allow(document).to receive(:validation_requests).and_return([])
      allow(document).to receive(:versions).and_return([])
      allow(document).to receive(:document_shares).and_return([])
    end

    it 'displays activities in timeline format' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('.flow-root')
      expect(page).to have_css('ul[role="list"]')
    end

    it 'shows activity items with proper structure' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('[data-activity-type="document_created"]')
      expect(page).to have_text('created this document')
    end

    it 'displays user information' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text(user.full_name)
    end

    it 'shows relative time' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text('days ago')
    end
  end

  describe 'empty state' do
    before do
      allow(document).to receive(:audits).and_return([])
      allow(document).to receive(:validation_requests).and_return([])
      allow(document).to receive(:versions).and_return([])
      allow(document).to receive(:document_shares).and_return([])
    end

    it 'displays empty state when no activities' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text('No activity yet')
      expect(page).to have_text('Activity will appear here as changes are made')
    end
  end

  describe 'ActivityItem class' do
    let(:activity_item) do
      described_class::ActivityItem.new(
        type: 'document_created',
        action: 'created',
        user: user,
        timestamp: 2.hours.ago,
        details: { field: 'value' },
        icon: 'plus-circle',
        color: 'green'
      )
    end

    describe '#description' do
      it 'returns appropriate description for document creation' do
        expect(activity_item.description).to eq('created this document')
      end

      it 'handles document updates with changes' do
        item = described_class::ActivityItem.new(
          type: 'document_updated',
          action: 'updated',
          user: user,
          timestamp: 1.hour.ago,
          details: { changes: [{ field: 'Title' }] }
        )
        
        expect(item.description).to eq('updated Title')
      end

      it 'handles validation requests' do
        item = described_class::ActivityItem.new(
          type: 'validation_requested',
          action: 'requested validation',
          user: user,
          timestamp: 1.hour.ago,
          details: { validation_type: 'compliance' }
        )
        
        expect(item.description).to eq('requested compliance validation')
      end
    end

    describe '#user_name' do
      it 'returns user full name when user present' do
        expect(activity_item.user_name).to eq(user.full_name)
      end

      it 'returns System when user is nil' do
        item = described_class::ActivityItem.new(
          type: 'system_action',
          action: 'automated',
          user: nil,
          timestamp: 1.hour.ago
        )
        
        expect(item.user_name).to eq('System')
      end
    end

    describe '#time_ago' do
      it 'returns just now for recent activities' do
        recent_item = described_class::ActivityItem.new(
          type: 'recent',
          action: 'action',
          user: user,
          timestamp: 30.seconds.ago
        )
        
        expect(recent_item.time_ago).to eq('just now')
      end

      it 'returns minutes ago for activities within an hour' do
        expect(activity_item.time_ago).to match(/\d+ hours ago/)
      end

      it 'returns formatted date for old activities' do
        old_item = described_class::ActivityItem.new(
          type: 'old',
          action: 'action',
          user: user,
          timestamp: 2.weeks.ago
        )
        
        expect(old_item.time_ago).to match(/\d{2}\/\d{2}\/\d{4}/)
      end
    end

    describe '#color_classes' do
      it 'returns appropriate CSS classes for colors' do
        expect(activity_item.color_classes).to eq('text-green-600 bg-green-100')
      end

      it 'defaults to gray for unknown colors' do
        item = described_class::ActivityItem.new(
          type: 'test',
          action: 'action',
          user: user,
          timestamp: 1.hour.ago,
          color: 'unknown'
        )
        
        expect(item.color_classes).to eq('text-gray-600 bg-gray-100')
      end
    end
  end

  describe 'validation activities' do
    let(:validation_request) do
      double(
        requester: user,
        created_at: 1.day.ago,
        validation_type: 'compliance',
        deadline: 3.days.from_now,
        document_validations: [validation]
      )
    end

    let(:validation) do
      double(
        status: 'approved',
        validator: user,
        created_at: 1.hour.ago,
        comment: 'Looks good!'
      )
    end

    before do
      allow(document).to receive(:audits).and_return([])
      allow(document).to receive(:validation_requests).and_return([validation_request])
      allow(document).to receive(:versions).and_return([])
      allow(document).to receive(:document_shares).and_return([])
      allow(validation_request).to receive(:includes).and_return([validation_request])
    end

    it 'displays validation request activities' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('[data-activity-type="validation_requested"]')
      expect(page).to have_text('requested compliance validation')
    end

    it 'displays validation approval activities' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_css('[data-activity-type="validation_approved"]')
      expect(page).to have_text('approved the document')
    end

    it 'shows validation comments' do
      render_inline(described_class.new(document: document))
      
      expect(page).to have_text('Looks good!')
    end
  end

  describe 'load more functionality' do
    before do
      # Create exactly the limit number of activities to trigger load more
      audits = Array.new(20) do |i|
        double(
          action: 'update',
          user: user,
          created_at: i.hours.ago,
          audited_changes: {}
        )
      end
      
      allow(document).to receive(:audits).and_return(audits)
      allow(document).to receive(:validation_requests).and_return([])
      allow(document).to receive(:versions).and_return([])
      allow(document).to receive(:document_shares).and_return([])
    end

    it 'shows load more button when limit is reached' do
      render_inline(described_class.new(document: document, limit: 20))
      
      expect(page).to have_text('Load more activity')
      expect(page).to have_css('[data-action="click->activity-timeline#loadMore"]')
    end

    it 'does not show load more when under limit' do
      render_inline(described_class.new(document: document, limit: 50))
      
      expect(page).not_to have_text('Load more activity')
    end
  end
end