require 'rails_helper'

RSpec.describe Dashboard::Widgets::RecentActivityComponent, type: :component do
  let(:activities) do
    [
      {
        type: 'document_uploaded',
        title: 'Document ajouté : Rapport mensuel',
        user: 'Jean Dupont',
        timestamp: 1.hour.ago,
        path: '/ged/documents/1'
      },
      {
        type: 'notification',
        title: 'Validation requise',
        user: 'Marie Martin',
        timestamp: 2.hours.ago,
        path: '/notifications'
      },
      {
        type: 'document_shared',
        title: 'Document partagé : Contrat client',
        user: 'Pierre Durand',
        timestamp: 1.day.ago,
        path: '/ged/documents/2'
      }
    ]
  end

  describe "with activities" do
    subject { render_inline(described_class.new(activities: activities)) }

    it "renders all activities" do
      expect(subject).to have_css(".space-y-3")
      expect(subject).to have_text("Rapport mensuel")
      expect(subject).to have_text("Validation requise")
      expect(subject).to have_text("Contrat client")
    end

    it "shows user information" do
      expect(subject).to have_text("par Jean Dupont")
      expect(subject).to have_text("par Marie Martin")
      expect(subject).to have_text("par Pierre Durand")
    end

    it "displays timestamps" do
      expect(subject).to have_text("il y a 1 heure")
      expect(subject).to have_text("il y a 2 heures")
      expect(subject).to have_text("hier")
    end

    it "shows correct icons" do
      expect(subject).to have_css(".text-green-600") # upload icon
      expect(subject).to have_css(".text-blue-600")  # notification icon
      expect(subject).to have_css(".text-yellow-600") # share icon
    end

    it "creates links for document activities" do
      expect(subject).to have_link(href: "/ged/documents/1")
      expect(subject).to have_link(href: "/ged/documents/2")
    end

    it "does not create links for notification activities" do
      # Notifications should not have clickable links to /notifications
      notification_elements = subject.css('*:contains("Validation requise")')
      expect(notification_elements).not_to have_link(href: "/notifications")
    end
  end

  describe "without activities" do
    subject { render_inline(described_class.new(activities: [])) }

    it "shows empty state" do
      expect(subject).to have_css("svg")
      expect(subject).to have_text("Aucune activité récente")
      expect(subject).to have_text("L'activité de votre équipe apparaîtra ici")
    end

    it "does not show activity items" do
      expect(subject).not_to have_text("par Jean")
      expect(subject).not_to have_text("il y a")
    end
  end

  describe "with nil activities" do
    subject { render_inline(described_class.new(activities: nil)) }

    it "shows empty state" do
      expect(subject).to have_text("Aucune activité récente")
    end
  end

  describe "icon selection" do
    let(:component) { described_class.new(activities: []) }

    it "returns correct icons for each activity type" do
      expect(component.send(:activity_icon, { type: 'document_uploaded' })).to eq('upload')
      expect(component.send(:activity_icon, { type: 'notification' })).to eq('bell')
      expect(component.send(:activity_icon, { type: 'document_viewed' })).to eq('eye')
      expect(component.send(:activity_icon, { type: 'document_shared' })).to eq('share')
      expect(component.send(:activity_icon, { type: 'unknown' })).to eq('activity')
    end
  end

  describe "color classes" do
    let(:component) { described_class.new(activities: []) }

    it "returns correct color classes for each icon" do
      expect(component.send(:activity_color_class, 'upload')).to eq('text-green-600 bg-green-100')
      expect(component.send(:activity_color_class, 'bell')).to eq('text-blue-600 bg-blue-100')
      expect(component.send(:activity_color_class, 'eye')).to eq('text-purple-600 bg-purple-100')
      expect(component.send(:activity_color_class, 'share')).to eq('text-yellow-600 bg-yellow-100')
      expect(component.send(:activity_color_class, 'unknown')).to eq('text-gray-600 bg-gray-100')
    end
  end

  describe "timestamp formatting" do
    let(:component) { described_class.new(activities: []) }

    it "formats timestamps correctly" do
      expect(component.send(:format_timestamp, 30.seconds.ago)).to match(/il y a \d+ secondes/)
      expect(component.send(:format_timestamp, 30.minutes.ago)).to match(/il y a \d+ minutes?/)
      expect(component.send(:format_timestamp, 2.hours.ago)).to match(/il y a \d+ heures?/)
      expect(component.send(:format_timestamp, 1.day.ago)).to eq("hier")
      expect(component.send(:format_timestamp, 3.days.ago)).to eq("il y a 3 jours")
      expect(component.send(:format_timestamp, 1.week.ago)).to match(/le \d{2}\/\d{2}\/\d{4}/)
      expect(component.send(:format_timestamp, nil)).to eq("à l'instant")
    end
  end
end