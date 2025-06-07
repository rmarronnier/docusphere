require 'rails_helper'

RSpec.describe Immo::Promo::ProjectCardComponent, type: :component do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:project) { create(:immo_promo_project, organization: organization, project_manager: user) }
  
  subject(:component) { described_class.new(project: project, show_actions: true) }

  describe '#initialize' do
    it 'sets project and show_actions' do
      expect(component.instance_variable_get(:@project)).to eq(project)
      expect(component.instance_variable_get(:@show_actions)).to eq(true)
    end
  end

  describe '#render' do
    before do
      # Stub the policy helper to avoid Devise/Pundit issues in component tests
      allow_any_instance_of(described_class).to receive(:helpers).and_return(
        double(policy: double(edit?: false, destroy?: false))
      )
    end
    
    it 'renders without error' do
      expect { render_inline(component) }.not_to raise_error
    end

    it 'displays project name' do
      render_inline(component)
      expect(page).to have_text(project.name)
    end

    it 'displays project reference' do
      render_inline(component)
      expect(page).to have_text(project.reference)
    end

    it 'displays project type' do
      render_inline(component)
      expect(page).to have_text(project.project_type.humanize)
    end

    it 'displays project status' do
      render_inline(component)
      expect(page).to have_text(project.status.humanize)
    end
  end

  describe '#status_class' do
    it 'returns correct CSS class for planning status' do
      project.update(status: 'planning')
      expect(component.send(:status_class)).to include('bg-blue')
    end

    it 'returns correct CSS class for development status' do
      project.update(status: 'development')
      expect(component.send(:status_class)).to include('bg-purple')
    end

    it 'returns correct CSS class for construction status' do
      project.update(status: 'construction')
      expect(component.send(:status_class)).to include('bg-yellow')
    end

    it 'returns correct CSS class for delivery status' do
      project.update(status: 'delivery')
      expect(component.send(:status_class)).to include('bg-orange')
    end

    it 'returns correct CSS class for completed status' do
      project.update(status: 'completed')
      expect(component.send(:status_class)).to include('bg-green')
    end
  end

  describe '#progress_color' do
    context 'when completion is low (0-25%)' do
      before { allow(project).to receive(:completion_percentage).and_return(20) }
      
      it 'returns red color class' do
        expect(component.send(:progress_color)).to eq('bg-red-600')
      end
    end

    context 'when completion is medium-low (26-50%)' do
      before { allow(project).to receive(:completion_percentage).and_return(40) }
      
      it 'returns yellow color class' do
        expect(component.send(:progress_color)).to eq('bg-yellow-600')
      end
    end

    context 'when completion is medium-high (51-75%)' do
      before { allow(project).to receive(:completion_percentage).and_return(60) }
      
      it 'returns blue color class' do
        expect(component.send(:progress_color)).to eq('bg-blue-600')
      end
    end

    context 'when completion is high (76-100%)' do
      before { allow(project).to receive(:completion_percentage).and_return(80) }
      
      it 'returns green color class' do
        expect(component.send(:progress_color)).to eq('bg-green-600')
      end
    end
  end

  describe '#is_delayed?' do
    context 'when project is delayed' do
      before { allow(project).to receive(:is_delayed?).and_return(true) }
      
      it 'returns true' do
        expect(component.send(:is_delayed?)).to be true
      end
    end

    context 'when project is not delayed' do
      before { allow(project).to receive(:is_delayed?).and_return(false) }
      
      it 'returns false' do
        expect(component.send(:is_delayed?)).to be false
      end
    end
  end

  describe '#formatted_surface_area' do
    context 'when project has surface area' do
      before { allow(project).to receive(:total_surface_area).and_return(1234.56) }
      
      it 'formats with delimiter' do
        expect(component.send(:formatted_surface_area)).to eq('1 234')
      end
    end

    context 'when project has no surface area' do
      before { allow(project).to receive(:total_surface_area).and_return(nil) }
      
      it 'returns nil' do
        expect(component.send(:formatted_surface_area)).to be_nil
      end
    end
  end

  describe '#formatted_start_date' do
    context 'when project has start date' do
      before { project.update(start_date: Date.new(2024, 1, 15)) }
      
      it 'formats date as dd/mm/yyyy' do
        expect(component.send(:formatted_start_date)).to eq('15/01/2024')
      end
    end

    context 'when project has no start date' do
      before { project.update(start_date: nil) }
      
      it 'returns "À définir"' do
        expect(component.send(:formatted_start_date)).to eq('À définir')
      end
    end
  end

  describe '#formatted_end_date' do
    context 'when project has end date' do
      before { project.update(end_date: Date.new(2025, 12, 31)) }
      
      it 'formats date as dd/mm/yyyy' do
        expect(component.send(:formatted_end_date)).to eq('31/12/2025')
      end
    end

    context 'when project has no end date' do
      before { project.update(end_date: nil) }
      
      it 'returns "À définir"' do
        expect(component.send(:formatted_end_date)).to eq('À définir')
      end
    end
  end
end