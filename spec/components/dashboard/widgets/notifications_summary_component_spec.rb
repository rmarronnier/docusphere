require 'rails_helper'

RSpec.describe Dashboard::Widgets::NotificationsSummaryComponent, type: :component do
  let(:summary_with_notifications) do
    {
      total_unread: 5,
      by_type: {
        'document_processing_completed' => 3,
        'validation_request' => 1,
        'system_announcement' => 1
      },
      by_priority: {
        'urgent' => 1,
        'high' => 2,
        'normal' => 2
      },
      recent: [
        {
          id: 1,
          title: 'Validation requise',
          message: 'Un document nécessite votre validation',
          notification_type: 'validation_request',
          priority: 'urgent',
          created_at: 1.hour.ago
        },
        {
          id: 2,
          title: 'Traitement terminé',
          message: 'Le document a été traité avec succès',
          notification_type: 'document_processing_completed',
          priority: 'normal',
          created_at: 2.hours.ago
        }
      ]
    }
  end

  let(:empty_summary) do
    {
      total_unread: 0,
      by_type: {},
      by_priority: {},
      recent: []
    }
  end

  describe "with notifications" do
    subject { render_inline(described_class.new(summary: summary_with_notifications)) }

    it "shows total unread count" do
      expect(subject).to have_text("5 notifications non lues")
    end

    it "displays priority distribution" do
      expect(subject).to have_text("Par priorité")
      expect(subject).to have_text("1 urgent")
      expect(subject).to have_text("2 élevée")
      expect(subject).to have_text("2 normale")
    end

    it "shows type distribution" do
      expect(subject).to have_text("Par type")
      expect(subject).to have_text("Traitement terminé")
      expect(subject).to have_text("Validation requise")
      expect(subject).to have_text("Annonce système")
      expect(subject).to have_text("3") # count for document_processing_completed
      expect(subject).to have_text("1") # count for others
    end

    it "displays recent notifications" do
      expect(subject).to have_text("Récentes")
      expect(subject).to have_text("Validation requise")
      expect(subject).to have_text("Un document nécessite votre validation")
      expect(subject).to have_text("Traitement terminé")
      expect(subject).to have_text("Le document a été traité avec succès")
    end

    it "shows timestamps for recent notifications" do
      expect(subject).to have_text("il y a 1h")
      expect(subject).to have_text("il y a 2h")
    end

    it "includes view all link" do
      expect(subject).to have_link("Voir tout", href: "/notifications")
    end

    it "shows priority indicators" do
      expect(subject).to have_css(".text-red-600") # urgent priority
      expect(subject).to have_css(".text-blue-600") # normal priority
    end
  end

  describe "without notifications" do
    subject { render_inline(described_class.new(summary: empty_summary)) }

    it "shows zero count" do
      expect(subject).to have_text("0 notification non lue")
    end

    it "shows empty state" do
      expect(subject).to have_css("svg")
      expect(subject).to have_text("Aucune notification")
      expect(subject).to have_text("Vous êtes à jour !")
    end

    it "does not show distribution sections" do
      expect(subject).not_to have_text("Par priorité")
      expect(subject).not_to have_text("Par type")
      expect(subject).not_to have_text("Récentes")
    end

    it "does not show view all link" do
      expect(subject).not_to have_link("Voir tout")
    end
  end

  describe "with nil summary" do
    subject { render_inline(described_class.new(summary: nil)) }

    it "shows empty state" do
      expect(subject).to have_text("0 notification non lue")
      expect(subject).to have_text("Aucune notification")
    end
  end

  describe "notification type labels" do
    let(:component) { described_class.new(summary: {}) }

    it "returns correct French labels for notification types" do
      expect(component.send(:notification_type_label, 'document_processing_completed')).to eq('Traitement terminé')
      expect(component.send(:notification_type_label, 'document_shared')).to eq('Document partagé')
      expect(component.send(:notification_type_label, 'validation_request')).to eq('Validation requise')
      expect(component.send(:notification_type_label, 'system_announcement')).to eq('Annonce système')
      expect(component.send(:notification_type_label, nil)).to eq('Notification')
    end
  end

  describe "priority labels and colors" do
    let(:component) { described_class.new(summary: {}) }

    it "returns correct French labels for priorities" do
      expect(component.send(:priority_label, 'urgent')).to eq('Urgent')
      expect(component.send(:priority_label, 'high')).to eq('Élevée')
      expect(component.send(:priority_label, 'normal')).to eq('Normale')
      expect(component.send(:priority_label, 'low')).to eq('Faible')
      expect(component.send(:priority_label, nil)).to eq('Normale')
    end

    it "returns correct CSS classes for priorities" do
      expect(component.send(:priority_color_class, 'urgent')).to eq('text-red-600 bg-red-100')
      expect(component.send(:priority_color_class, 'high')).to eq('text-orange-600 bg-orange-100')
      expect(component.send(:priority_color_class, 'normal')).to eq('text-blue-600 bg-blue-100')
      expect(component.send(:priority_color_class, 'low')).to eq('text-gray-600 bg-gray-100')
      expect(component.send(:priority_color_class, 'unknown')).to eq('text-blue-600 bg-blue-100')
    end
  end

  describe "timestamp formatting" do
    let(:component) { described_class.new(summary: {}) }

    it "formats timestamps correctly" do
      expect(component.send(:format_timestamp, 30.minutes.ago)).to match(/il y a \d+ min/)
      expect(component.send(:format_timestamp, 2.hours.ago)).to match(/il y a \d+h/)
      expect(component.send(:format_timestamp, 1.day.ago)).to eq("hier")
      expect(component.send(:format_timestamp, 3.days.ago)).to match(/\d{2}\/\d{2}/)
      expect(component.send(:format_timestamp, nil)).to eq("à l'instant")
    end
  end
end