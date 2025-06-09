require 'rails_helper'

RSpec.describe Immo::Promo::DocumentPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:project) { create(:immo_promo_project, organization: organization) }
  let(:document) { create(:document, documentable: project, uploaded_by: uploader) }
  
  # Users with different roles
  let(:super_admin) { create(:user, role: 'super_admin') }
  let(:admin_user) { create(:user, role: 'admin', organization: organization) }
  let(:uploader) { create(:user, role: 'user', organization: organization) }
  let(:regular_user) { create(:user, role: 'user', organization: organization) }
  let(:external_user) { create(:user, role: 'user', organization: create(:organization)) }
  
  let(:project_manager) { 
    create(:user, 
      role: 'user', 
      organization: organization,
      permissions: { 'immo_promo:access' => true }
    ) 
  }
  let(:project_with_manager) { create(:immo_promo_project, organization: organization, project_manager: project_manager) }
  let(:document_with_manager) { create(:document, documentable: project_with_manager, uploaded_by: uploader) }

  describe 'show?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, document) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with document uploader' do
      subject { described_class.new(uploader, document) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with admin from same organization' do
      subject { described_class.new(admin_user, document) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with user having project access' do
      let(:project_user) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:access' => true }
        ) 
      }
      subject { described_class.new(project_user, document) }
      it { is_expected.to permit_action(:show) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, document) }
      it { is_expected.not_to permit_action(:show) }
    end
    
    context 'with regular user without permissions' do
      subject { described_class.new(regular_user, document) }
      it { is_expected.not_to permit_action(:show) }
    end
  end

  describe 'create?' do
    let(:new_document) { build(:document, documentable: project, uploaded_by: regular_user) }
    
    context 'with super admin' do
      subject { described_class.new(super_admin, new_document) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with admin from same organization' do
      subject { described_class.new(admin_user, new_document) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with user having project update access' do
      let(:project_writer) { 
        create(:user, 
          organization: organization, 
          permissions: { 
            'immo_promo:access' => true,
            'immo_promo:projects:write' => true
          }
        ) 
      }
      subject { described_class.new(project_writer, new_document) }
      it { is_expected.to permit_action(:create) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, new_document) }
      it { is_expected.not_to permit_action(:create) }
    end
    
    context 'with regular user without write permissions' do
      subject { described_class.new(regular_user, new_document) }
      it { is_expected.not_to permit_action(:create) }
    end
  end

  describe 'update?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, document) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with document uploader' do
      subject { described_class.new(uploader, document) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with admin from same organization' do
      subject { described_class.new(admin_user, document) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user having project update access' do
      let(:project_writer) { 
        create(:user, 
          organization: organization, 
          permissions: { 
            'immo_promo:access' => true,
            'immo_promo:projects:write' => true
          }
        ) 
      }
      subject { described_class.new(project_writer, document) }
      it { is_expected.to permit_action(:update) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, document) }
      it { is_expected.not_to permit_action(:update) }
    end
    
    context 'with regular user who did not upload the document' do
      subject { described_class.new(regular_user, document) }
      it { is_expected.not_to permit_action(:update) }
    end
  end

  describe 'destroy?' do
    context 'with super admin' do
      subject { described_class.new(super_admin, document) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with document uploader' do
      subject { described_class.new(uploader, document) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with admin from same organization' do
      subject { described_class.new(admin_user, document) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with user having project update access' do
      let(:project_writer) { 
        create(:user, 
          organization: organization, 
          permissions: { 
            'immo_promo:access' => true,
            'immo_promo:projects:write' => true
          }
        ) 
      }
      subject { described_class.new(project_writer, document) }
      it { is_expected.to permit_action(:destroy) }
    end
    
    context 'with user from different organization' do
      subject { described_class.new(external_user, document) }
      it { is_expected.not_to permit_action(:destroy) }
    end
    
    context 'with regular user who did not upload the document' do
      subject { described_class.new(regular_user, document) }
      it { is_expected.not_to permit_action(:destroy) }
    end
  end

  describe 'download?' do
    context 'with user who can show document' do
      subject { described_class.new(uploader, document) }
      it { is_expected.to permit_action(:download) }
    end
    
    context 'with user who cannot show document' do
      subject { described_class.new(regular_user, document) }
      it { is_expected.not_to permit_action(:download) }
    end
  end

  describe 'share?' do
    context 'with user who can show and has project update access' do
      let(:project_writer) { 
        create(:user, 
          organization: organization, 
          permissions: { 
            'immo_promo:access' => true,
            'immo_promo:projects:write' => true
          }
        ) 
      }
      subject { described_class.new(project_writer, document) }
      it { is_expected.to permit_action(:share) }
    end
    
    context 'with user who can show but cannot update project' do
      let(:project_reader) { 
        create(:user, 
          organization: organization, 
          permissions: { 'immo_promo:access' => true }
        ) 
      }
      subject { described_class.new(project_reader, document) }
      it { is_expected.not_to permit_action(:share) }
    end
    
    context 'with user who cannot show document' do
      subject { described_class.new(regular_user, document) }
      it { is_expected.not_to permit_action(:share) }
    end
  end

  describe 'bulk_upload?' do
    let(:new_document) { build(:document, documentable: project, uploaded_by: regular_user) }
    
    context 'with user who can create documents' do
      let(:project_writer) { 
        create(:user, 
          organization: organization, 
          permissions: { 
            'immo_promo:access' => true,
            'immo_promo:projects:write' => true
          }
        ) 
      }
      subject { described_class.new(project_writer, new_document) }
      it { is_expected.to permit_action(:bulk_upload) }
    end
    
    context 'with user who cannot create documents' do
      subject { described_class.new(regular_user, new_document) }
      it { is_expected.not_to permit_action(:bulk_upload) }
    end
  end

  describe 'search?' do
    context 'with any user' do
      subject { described_class.new(regular_user, document) }
      it { is_expected.to permit_action(:search) }
    end
  end

  describe 'Scope' do
    let!(:user_document) { create(:document, documentable: project, uploaded_by: regular_user) }
    let!(:other_document) { create(:document, documentable: project, uploaded_by: uploader) }
    let!(:external_document) { create(:document, documentable: create(:immo_promo_project)) }
    
    context 'with super admin' do
      subject { described_class::Scope.new(super_admin, Document).resolve }
      
      it 'returns all documents' do
        expect(subject).to include(user_document, other_document, external_document)
      end
    end
    
    context 'with admin user' do
      subject { described_class::Scope.new(admin_user, Document).resolve }
      
      it 'returns all documents' do
        expect(subject).to include(user_document, other_document, external_document)
      end
    end
    
    context 'with regular user' do
      subject { described_class::Scope.new(regular_user, Document).resolve }
      
      it 'returns only documents uploaded by user' do
        expect(subject).to include(user_document)
        expect(subject).not_to include(other_document, external_document)
      end
    end
  end
end