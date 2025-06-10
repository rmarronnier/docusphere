require 'rails_helper'

RSpec.describe ProfileSwitcherComponent, type: :component do
  let(:user) { create(:user) }
  let(:organization) { user.organization }
  
  before do
    # Create multiple profiles for the user
    @direction_profile = create(:user_profile, 
      user: user, 
      profile_type: 'direction',
      active: true
    )
    @chef_projet_profile = create(:user_profile, 
      user: user, 
      profile_type: 'chef_projet',
      active: false
    )
    @juriste_profile = create(:user_profile, 
      user: user, 
      profile_type: 'juriste',
      active: false
    )
  end
  
  context 'with multiple profiles' do
    it 'renders profile switcher' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_css('.profile-switcher')
    end
    
    it 'shows current active profile' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('Direction')
      expect(page).to have_css('[data-current-profile="true"]')
    end
    
    it 'lists all available profiles' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('Direction')
      expect(page).to have_text('Chef de projet')
      expect(page).to have_text('Juriste')
    end
    
    it 'indicates active profile' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_css('[data-profile-type="direction"][data-active="true"]')
      expect(page).to have_css('[data-profile-type="chef_projet"][data-active="false"]')
      expect(page).to have_css('[data-profile-type="juriste"][data-active="false"]')
    end
    
    it 'includes switch links for inactive profiles' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_link('Chef de projet', href: "/profiles/#{@chef_projet_profile.id}/activate")
      expect(page).to have_link('Juriste', href: "/profiles/#{@juriste_profile.id}/activate")
    end
    
    it 'does not include switch link for active profile' do
      render_inline(described_class.new(user: user))
      
      expect(page).not_to have_link('Direction', href: "/profiles/#{@direction_profile.id}/activate")
    end
    
    it 'shows profile icons' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_css('[data-profile-icon="direction"]')
      expect(page).to have_css('[data-profile-icon="chef_projet"]')
      expect(page).to have_css('[data-profile-icon="juriste"]')
    end
    
    it 'applies dropdown styling' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_css('[data-controller="dropdown"]')
      expect(page).to have_css('.dropdown-toggle')
      expect(page).to have_css('.dropdown-menu')
    end
  end
  
  context 'with single profile' do
    before do
      # Remove extra profiles
      @chef_projet_profile.destroy
      @juriste_profile.destroy
    end
    
    it 'does not render switcher' do
      render_inline(described_class.new(user: user))
      
      expect(page).not_to have_css('.profile-switcher')
    end
    
    it 'shows static profile badge' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_css('.profile-badge')
      expect(page).to have_text('Direction')
    end
  end
  
  context 'with no profiles' do
    before do
      user.user_profiles.destroy_all
    end
    
    it 'does not render anything' do
      render_inline(described_class.new(user: user))
      
      expect(page.text).to be_blank
    end
  end
  
  context 'with custom display options' do
    it 'can show as compact mode' do
      render_inline(described_class.new(user: user, compact: true))
      
      expect(page).to have_css('.profile-switcher--compact')
    end
    
    it 'can hide profile descriptions' do
      render_inline(described_class.new(user: user, show_descriptions: false))
      
      expect(page).not_to have_text('Gestion stratégique')
      expect(page).not_to have_text('Pilotage opérationnel')
    end
  end
  
  context 'with profile permissions' do
    before do
      @architecte_profile = create(:user_profile, 
        user: user, 
        profile_type: 'architecte',
        active: false
      )
      # Define can_switch_to_profile? method
      def user.can_switch_to_profile?(profile_type)
        profile_type != 'architecte'
      end
    end
    
    it 'only shows profiles user can switch to' do
      render_inline(described_class.new(user: user))
      
      expect(page).to have_text('Direction')
      expect(page).to have_text('Chef de projet')
      expect(page).to have_text('Juriste')
      expect(page).not_to have_text('Architecte')
    end
  end
end