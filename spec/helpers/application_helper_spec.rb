require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#format_date' do
    it 'formats date in French locale' do
      date = Date.new(2025, 6, 11)
      expect(helper.format_date(date)).to eq('11 juin 2025')
    end
    
    it 'returns empty string for nil' do
      expect(helper.format_date(nil)).to eq('')
    end
    
    it 'accepts custom format' do
      date = Date.new(2025, 6, 11)
      expect(helper.format_date(date, '%d/%m/%Y')).to eq('11/06/2025')
    end
  end
  
  describe '#format_datetime' do
    it 'formats datetime with time' do
      datetime = DateTime.new(2025, 6, 11, 14, 30)
      expect(helper.format_datetime(datetime)).to include('14:30')
    end
    
    it 'returns empty string for nil' do
      expect(helper.format_datetime(nil)).to eq('')
    end
  end
  
  describe '#format_currency' do
    it 'formats cents to euros' do
      expect(helper.format_currency(150000)).to eq('€1 500,00')
    end
    
    it 'handles zero' do
      expect(helper.format_currency(0)).to eq('€0,00')
    end
    
    it 'handles nil' do
      expect(helper.format_currency(nil)).to eq('€0,00')
    end
  end
  
  describe '#format_file_size' do
    it 'formats bytes to human readable' do
      expect(helper.format_file_size(1024)).to eq('1 KB')
      expect(helper.format_file_size(1024 * 1024)).to eq('1 MB')
      expect(helper.format_file_size(1024 * 1024 * 1024)).to eq('1 GB')
    end
    
    it 'handles small sizes' do
      expect(helper.format_file_size(100)).to eq('100 Bytes')
    end
    
    it 'handles nil' do
      expect(helper.format_file_size(nil)).to eq('0 Bytes')
    end
  end
  
  describe '#active_class' do
    it 'returns active class when controller matches' do
      allow(controller).to receive(:controller_name).and_return('documents')
      expect(helper.active_class('documents')).to eq('active')
    end
    
    it 'returns empty string when controller does not match' do
      allow(controller).to receive(:controller_name).and_return('documents')
      expect(helper.active_class('users')).to eq('')
    end
    
    it 'accepts multiple controllers' do
      allow(controller).to receive(:controller_name).and_return('users')
      expect(helper.active_class(['documents', 'users', 'folders'])).to eq('active')
    end
  end
  
  describe '#breadcrumb_link' do
    it 'creates a breadcrumb link' do
      result = helper.breadcrumb_link('Home', root_path)
      expect(result).to have_link('Home', href: root_path)
    end
    
    it 'marks last item as current' do
      result = helper.breadcrumb_link('Current Page', nil, current: true)
      expect(result).to have_css('.current')
      expect(result).not_to have_link('Current Page')
    end
  end
  
  describe '#flash_class' do
    it 'returns appropriate CSS class for flash type' do
      expect(helper.flash_class('notice')).to eq('alert-info')
      expect(helper.flash_class('alert')).to eq('alert-warning')
      expect(helper.flash_class('error')).to eq('alert-danger')
      expect(helper.flash_class('success')).to eq('alert-success')
    end
    
    it 'returns default class for unknown type' do
      expect(helper.flash_class('unknown')).to eq('alert-info')
    end
  end
  
  describe '#time_ago' do
    it 'returns relative time' do
      expect(helper.time_ago(1.hour.ago)).to include('1 heure')
      expect(helper.time_ago(2.days.ago)).to include('2 jours')
    end
    
    it 'returns empty for nil' do
      expect(helper.time_ago(nil)).to eq('')
    end
  end
  
  describe '#truncate_middle' do
    it 'truncates long strings in the middle' do
      long_string = 'This is a very long filename that needs to be truncated.pdf'
      result = helper.truncate_middle(long_string, 30)
      
      expect(result.length).to be <= 30
      expect(result).to include('...')
      expect(result).to end_with('.pdf')
    end
    
    it 'returns original string if shorter than limit' do
      short_string = 'short.pdf'
      expect(helper.truncate_middle(short_string, 30)).to eq(short_string)
    end
  end
  
  describe '#status_badge' do
    it 'returns badge HTML for status' do
      result = helper.status_badge('active')
      expect(result).to have_css('.badge.badge-success')
      expect(result).to have_content('Active')
    end
    
    it 'handles different statuses' do
      expect(helper.status_badge('pending')).to have_css('.badge-warning')
      expect(helper.status_badge('rejected')).to have_css('.badge-danger')
      expect(helper.status_badge('completed')).to have_css('.badge-success')
    end
  end
  
  describe '#icon' do
    it 'returns icon HTML' do
      result = helper.icon('document')
      expect(result).to have_css('i.icon-document')
    end
    
    it 'accepts additional classes' do
      result = helper.icon('user', class: 'text-primary')
      expect(result).to have_css('i.icon-user.text-primary')
    end
  end
  
  describe '#user_avatar' do
    let(:user) { create(:user, first_name: 'Jean', last_name: 'Dupont') }
    
    it 'returns avatar with initials' do
      result = helper.user_avatar(user)
      expect(result).to have_css('.avatar')
      expect(result).to have_content('JD')
    end
    
    it 'accepts size parameter' do
      result = helper.user_avatar(user, size: 'large')
      expect(result).to have_css('.avatar.avatar-large')
    end
  end
  
  describe '#page_title' do
    it 'sets and returns page title' do
      helper.page_title('Documents')
      expect(helper.page_title).to eq('Documents - DocuSphere')
    end
    
    it 'returns default title when not set' do
      expect(helper.page_title).to eq('DocuSphere')
    end
  end
end