module Immo
  module Promo
    class PermitMailer < ApplicationMailer
      def status_change_notification(permit, old_status, new_status)
        @permit = permit
        @project = permit.project
        @old_status = old_status
        @new_status = new_status
        
        recipients = notification_recipients(permit)
        
        mail(
          to: recipients,
          subject: "[#{@project.name}] Changement de statut - #{@permit.permit_type.humanize}"
        )
      end
      
      def deadline_reminder(permit, deadline_type)
        @permit = permit
        @project = permit.project
        @deadline_type = deadline_type
        @days_remaining = permit.days_until_expiry
        
        recipients = notification_recipients(permit)
        
        mail(
          to: recipients,
          subject: "[#{@project.name}] Rappel échéance - #{@permit.permit_type.humanize}"
        )
      end
      
      private
      
      def notification_recipients(permit)
        recipients = []
        
        # Project manager
        recipients << permit.project.project_manager&.email
        
        # Permit submitter
        recipients << permit.submitted_by&.email
        
        # Organization admins
        recipients.concat(
          permit.project.organization.users.where(role: 'admin').pluck(:email)
        )
        
        recipients.compact.uniq
      end
    end
  end
end