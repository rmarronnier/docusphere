module Immo
  module Promo
    class StakeholderMailer < ApplicationMailer
      def notification_email(stakeholder, notification)
        @stakeholder = stakeholder
        @notification = notification
        @project = stakeholder.project
        
        mail(
          to: stakeholder.email,
          subject: "[#{@project.name}] #{@notification.title}"
        )
      end
    end
  end
end