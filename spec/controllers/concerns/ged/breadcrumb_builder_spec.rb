require 'rails_helper'

RSpec.describe Ged::BreadcrumbBuilder, type: :controller do
  controller(ApplicationController) do
    include Ged::BreadcrumbBuilder
    
    def index
      # Dummy action for routing
      render json: { status: 'ok' }
    end
    
    def build_test_folder_breadcrumbs(folder)
      build_folder_breadcrumbs(folder)
    end
    
    def build_test_document_breadcrumbs(document)
      build_document_breadcrumbs(document)
    end
  end

  let(:user) { create(:user) }
  let(:space) { create(:space, name: 'Test Space') }
  let(:parent_folder) { create(:folder, name: 'Parent', space: space) }
  let(:child_folder) { create(:folder, name: 'Child', space: space, parent: parent_folder) }
  let(:document) { create(:document, title: 'Test Doc', space: space, folder: child_folder) }

  before do
    sign_in user
    allow(controller).to receive(:ged_dashboard_path).and_return('/ged')
    allow(controller).to receive(:ged_space_path).and_return('/ged/spaces/1')
    allow(controller).to receive(:ged_folder_path) { |f| "/ged/folders/#{f.id}" }
    allow(controller).to receive(:ged_document_path).and_return('/ged/documents/1')
  end

  describe '#build_folder_breadcrumbs' do
    it 'builds breadcrumbs for root folder' do
      root_folder = create(:folder, name: 'Root', space: space)
      
      breadcrumbs = controller.build_test_folder_breadcrumbs(root_folder)
      
      expect(breadcrumbs.size).to eq(3)
      expect(breadcrumbs[0][:name]).to eq('GED')
      expect(breadcrumbs[1][:name]).to eq('Test Space')
      expect(breadcrumbs[2][:name]).to eq('Root')
    end

    it 'builds breadcrumbs for nested folder' do
      breadcrumbs = controller.build_test_folder_breadcrumbs(child_folder)
      
      expect(breadcrumbs.size).to eq(4)
      expect(breadcrumbs[0][:name]).to eq('GED')
      expect(breadcrumbs[1][:name]).to eq('Test Space')
      expect(breadcrumbs[2][:name]).to eq('Parent')
      expect(breadcrumbs[3][:name]).to eq('Child')
    end
  end

  describe '#build_document_breadcrumbs' do
    it 'builds breadcrumbs for document in folder' do
      breadcrumbs = controller.build_test_document_breadcrumbs(document)
      
      expect(breadcrumbs.size).to eq(5)
      expect(breadcrumbs[0][:name]).to eq('GED')
      expect(breadcrumbs[1][:name]).to eq('Test Space')
      expect(breadcrumbs[2][:name]).to eq('Parent')
      expect(breadcrumbs[3][:name]).to eq('Child')
      expect(breadcrumbs[4][:name]).to eq('Test Doc')
    end

    it 'builds breadcrumbs for document without folder' do
      document_no_folder = create(:document, title: 'No Folder Doc', space: space, folder: nil)
      breadcrumbs = controller.build_test_document_breadcrumbs(document_no_folder)
      
      expect(breadcrumbs.size).to eq(3)
      expect(breadcrumbs[0][:name]).to eq('GED')
      expect(breadcrumbs[1][:name]).to eq('Test Space')
      expect(breadcrumbs[2][:name]).to eq('No Folder Doc')
    end
  end
end