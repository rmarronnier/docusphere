require 'rails_helper'

RSpec.describe NotificationPolicy, type: :policy do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:other_user) { create(:user, organization: organization) }
  let(:notification) { create(:notification, user: user) }
  let(:other_notification) { create(:notification, user: other_user) }

  subject { described_class }

  permissions :index? do
    it 'allows authenticated users' do
      expect(subject).to permit(user, Notification)
    end

    it 'denies unauthenticated users' do
      expect(subject).not_to permit(nil, Notification)
    end
  end

  permissions :show? do
    it 'allows user to view their own notification' do
      expect(subject).to permit(user, notification)
    end

    it 'denies user from viewing other users notification' do
      expect(subject).not_to permit(user, other_notification)
    end

    it 'denies unauthenticated users' do
      expect(subject).not_to permit(nil, notification)
    end
  end

  permissions :mark_as_read? do
    it 'allows user to mark their own notification as read' do
      expect(subject).to permit(user, notification)
    end

    it 'denies user from marking other users notification as read' do
      expect(subject).not_to permit(user, other_notification)
    end
  end

  permissions :destroy? do
    it 'allows user to delete their own notification' do
      expect(subject).to permit(user, notification)
    end

    it 'denies user from deleting other users notification' do
      expect(subject).not_to permit(user, other_notification)
    end
  end

  permissions :mark_all_as_read?, :bulk_mark_as_read?, :bulk_destroy? do
    it 'allows authenticated users' do
      expect(subject).to permit(user, Notification)
    end

    it 'denies unauthenticated users' do
      expect(subject).not_to permit(nil, Notification)
    end
  end

  permissions :dropdown?, :urgent?, :stats? do
    it 'allows authenticated users' do
      expect(subject).to permit(user, Notification)
    end

    it 'denies unauthenticated users' do
      expect(subject).not_to permit(nil, Notification)
    end
  end

  permissions :immo_promo_notifications? do
    context 'when user has immo_promo access' do
      before do
        user.add_permission('immo_promo:access')
      end

      it 'allows access' do
        expect(subject).to permit(user, Notification)
      end
    end

    context 'when user does not have immo_promo access' do
      it 'denies access' do
        expect(subject).not_to permit(user, Notification)
      end
    end

    it 'denies unauthenticated users' do
      expect(subject).not_to permit(nil, Notification)
    end
  end

  permissions :project_notifications? do
    context 'when user has immo_promo access' do
      before do
        user.add_permission('immo_promo:access')
      end

      it 'allows access' do
        expect(subject).to permit(user, Notification)
      end
    end

    context 'when user does not have immo_promo access' do
      it 'denies access' do
        expect(subject).not_to permit(user, Notification)
      end
    end
  end

  describe NotificationPolicy::Scope do
    let!(:user_notification1) { create(:notification, user: user) }
    let!(:user_notification2) { create(:notification, user: user) }
    let!(:other_user_notification) { create(:notification, user: other_user) }

    it 'includes only user notifications' do
      scope = NotificationPolicy::Scope.new(user, Notification).resolve
      expect(scope).to include(user_notification1, user_notification2)
      expect(scope).not_to include(other_user_notification)
    end

    it 'returns empty scope for unauthenticated users' do
      scope = NotificationPolicy::Scope.new(nil, Notification).resolve
      expect(scope).to be_empty
    end

    describe '#immo_promo_scope' do
      let!(:document_notification) { create(:notification, user: user, notification_type: 'document_shared') }
      let!(:project_notification) { create(:notification, user: user, notification_type: 'project_created') }

      context 'when user has immo_promo access' do
        before do
          user.add_permission('immo_promo:access')
        end

        it 'includes only immo_promo related notifications' do
          scope = NotificationPolicy::Scope.new(user, Notification).immo_promo_scope
          expect(scope).to include(project_notification)
          expect(scope).not_to include(document_notification)
        end
      end

      context 'when user does not have immo_promo access' do
        it 'returns empty scope' do
          scope = NotificationPolicy::Scope.new(user, Notification).immo_promo_scope
          expect(scope).to be_empty
        end
      end
    end

    describe '#project_scope' do
      let(:project) { double('Project', id: 1) }
      let(:project_policy) { double('ProjectPolicy', show?: true) }
      
      before do
        allow(Pundit).to receive(:policy).with(user, project).and_return(project_policy)
        allow(project).to receive(:phases).and_return([])
        allow(project).to receive(:tasks).and_return([])
        allow(project).to receive(:stakeholders).and_return([])
        allow(project).to receive(:permits).and_return([])
        allow(project).to receive(:budgets).and_return([])
        allow(project).to receive(:risks).and_return([])
      end

      context 'when user can access project' do
        it 'returns notifications related to project' do
          scope_instance = NotificationPolicy::Scope.new(user, Notification.joins(:notifiable))
          scope = scope_instance.project_scope(project)
          expect(scope).to be_a(ActiveRecord::Relation)
        end
      end

      context 'when user cannot access project' do
        before do
          allow(project_policy).to receive(:show?).and_return(false)
        end

        it 'returns empty scope' do
          scope_instance = NotificationPolicy::Scope.new(user, Notification)
          scope = scope_instance.project_scope(project)
          expect(scope).to eq(Notification.none)
        end
      end

      context 'when project is nil' do
        it 'returns empty scope' do
          scope_instance = NotificationPolicy::Scope.new(user, Notification)
          scope = scope_instance.project_scope(nil)
          expect(scope).to eq(Notification.none)
        end
      end
    end
  end

  describe 'private helper methods' do
    let(:policy) { described_class.new(user, notification) }

    describe '#notification_belongs_to_user?' do
      it 'returns true for own notification' do
        expect(policy.send(:notification_belongs_to_user?)).to be true
      end

      it 'returns false for other user notification' do
        other_policy = described_class.new(user, other_notification)
        expect(other_policy.send(:notification_belongs_to_user?)).to be false
      end
    end

    describe '#can_access_immo_promo_notification?' do
      context 'with non-immo-promo notification' do
        let(:document_notification) { create(:notification, user: user, notification_type: 'document_shared') }
        let(:policy) { described_class.new(user, document_notification) }

        it 'returns true' do
          expect(policy.send(:can_access_immo_promo_notification?)).to be true
        end
      end

      context 'with immo-promo notification' do
        let(:project_notification) { create(:notification, user: user, notification_type: 'project_created') }
        let(:policy) { described_class.new(user, project_notification) }

        context 'when user has immo_promo access' do
          before do
            user.add_permission('immo_promo:access')
          end

          it 'returns true' do
            expect(policy.send(:can_access_immo_promo_notification?)).to be true
          end
        end

        context 'when user does not have immo_promo access' do
          it 'returns false' do
            expect(policy.send(:can_access_immo_promo_notification?)).to be false
          end
        end
      end
    end
  end
end