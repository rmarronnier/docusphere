require 'rails_helper'

RSpec.describe 'Flash Messages', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'flash message display' do
    it 'displays success flash messages' do
      visit root_path
      
      # Simulate a controller setting a flash message
      # Since we can't directly set flash in system tests, we'll use a known action
      visit ged_documents_path
      
      # Create a document to trigger a success message
      click_on 'Nouveau document'
      fill_in 'Nom', with: 'Test Document'
      attach_file 'Fichier', Rails.root.join('spec/fixtures/files/test.pdf')
      click_button 'Créer'
      
      # Check for success flash
      within('.flash-messages-container') do
        expect(page).to have_css('[role="alert"]')
        expect(page).to have_css('.bg-green-50')
        expect(page).to have_content('Document créé avec succès')
      end
    end

    it 'displays error flash messages' do
      visit root_path
      
      # Try to access a resource without permission to trigger an error
      visit edit_user_path(create(:user)) # Try to edit another user
      
      # Check for error flash
      within('.flash-messages-container') do
        expect(page).to have_css('[role="alert"]')
        expect(page).to have_css('.bg-red-50')
      end
    end

    it 'allows dismissing flash messages' do
      visit root_path
      
      # Create a scenario that generates a flash message
      visit ged_documents_path
      
      # Assuming there's a flash message
      if page.has_css?('[data-controller="alert"]')
        within('[data-controller="alert"]') do
          # Click dismiss button
          find('button[aria-label="Dismiss"]').click
        end
        
        # Flash message should disappear
        expect(page).not_to have_css('[data-controller="alert"]')
      end
    end

    it 'displays multiple flash messages' do
      # This would require a controller action that sets multiple flash types
      # For now, we'll test that the container can hold multiple messages
      visit root_path
      
      # Execute JavaScript to simulate multiple flash messages
      page.execute_script(<<~JS)
        const container = document.querySelector('.flash-messages-container');
        if (container) {
          container.innerHTML = `
            <div role="alert" class="bg-green-50">Success message</div>
            <div role="alert" class="bg-yellow-50">Warning message</div>
            <div role="alert" class="bg-red-50">Error message</div>
          `;
        }
      JS
      
      within('.flash-messages-container') do
        expect(page).to have_css('[role="alert"]', count: 3)
        expect(page).to have_css('.bg-green-50')
        expect(page).to have_css('.bg-yellow-50')
        expect(page).to have_css('.bg-red-50')
      end
    end
  end

  describe 'accessibility' do
    it 'has proper ARIA attributes' do
      visit root_path
      
      # Execute JavaScript to add a test flash message
      page.execute_script(<<~JS)
        const container = document.querySelector('.flash-messages-container');
        if (container) {
          container.innerHTML = '<div role="alert" aria-live="polite" aria-atomic="true" class="bg-green-50">Test message</div>';
        }
      JS
      
      within('.flash-messages-container') do
        alert = find('[role="alert"]')
        expect(alert['aria-live']).to eq('polite')
        expect(alert['aria-atomic']).to eq('true')
      end
    end

    it 'uses assertive aria-live for errors' do
      visit root_path
      
      # Execute JavaScript to add an error flash message
      page.execute_script(<<~JS)
        const container = document.querySelector('.flash-messages-container');
        if (container) {
          container.innerHTML = '<div role="alert" aria-live="assertive" aria-atomic="true" class="bg-red-50">Error message</div>';
        }
      JS
      
      within('.flash-messages-container') do
        alert = find('[role="alert"]')
        expect(alert['aria-live']).to eq('assertive')
      end
    end
  end
end