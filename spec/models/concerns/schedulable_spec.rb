require 'rails_helper'

RSpec.describe Schedulable, type: :concern do
  # Create a test class to include the concern
  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'workflows' # Using workflows table which should have date fields
      include Schedulable
      
      def self.name
        'TestSchedulable'
      end
    end
  end

  let(:schedulable_instance) { test_class.new }
  let(:now) { Time.current }
  let(:yesterday) { 1.day.ago }
  let(:tomorrow) { 1.day.from_now }
  let(:next_week) { 1.week.from_now }

  describe 'included module behavior' do
    it 'adds schedule validation when required' do
      schedulable_instance.start_date = nil
      schedulable_instance.end_date = nil
      
      expect(schedulable_instance).not_to be_valid
      expect(schedulable_instance.errors[:start_date]).to include("can't be blank")
      expect(schedulable_instance.errors[:end_date]).to include("can't be blank")
    end

    it 'validates end_date is after start_date' do
      schedulable_instance.start_date = tomorrow
      schedulable_instance.end_date = yesterday
      
      expect(schedulable_instance).not_to be_valid
      expect(schedulable_instance.errors[:end_date]).to include('doit être postérieure à la date de début')
    end

    it 'allows valid date range' do
      schedulable_instance.start_date = yesterday
      schedulable_instance.end_date = tomorrow
      
      expect(schedulable_instance).to be_valid
    end

    it 'adds scopes to the class' do
      expect(test_class).to respond_to(:current)
      expect(test_class).to respond_to(:upcoming)
      expect(test_class).to respond_to(:past)
      expect(test_class).to respond_to(:between_dates)
      expect(test_class).to respond_to(:starting_between)
      expect(test_class).to respond_to(:ending_between)
    end
  end

  describe '#duration' do
    it 'calculates duration between start and end dates' do
      schedulable_instance.start_date = yesterday
      schedulable_instance.end_date = tomorrow
      
      expected_duration = tomorrow - yesterday
      expect(schedulable_instance.duration).to eq(expected_duration)
    end

    it 'returns nil when dates are missing' do
      expect(schedulable_instance.duration).to be_nil
      
      schedulable_instance.start_date = yesterday
      expect(schedulable_instance.duration).to be_nil
    end
  end

  describe '#duration_in_days' do
    it 'returns duration in days' do
      schedulable_instance.start_date = yesterday
      schedulable_instance.end_date = tomorrow
      
      expect(schedulable_instance.duration_in_days).to eq(2)
    end

    it 'returns nil when duration is nil' do
      expect(schedulable_instance.duration_in_days).to be_nil
    end
  end

  describe '#duration_in_hours' do
    it 'returns duration in hours' do
      schedulable_instance.start_date = 2.hours.ago
      schedulable_instance.end_date = 1.hour.from_now
      
      expect(schedulable_instance.duration_in_hours).to eq(3)
    end

    it 'returns nil when duration is nil' do
      expect(schedulable_instance.duration_in_hours).to be_nil
    end
  end

  describe '#current?' do
    it 'returns true when current time is between start and end dates' do
      schedulable_instance.start_date = yesterday
      schedulable_instance.end_date = tomorrow
      
      expect(schedulable_instance.current?).to be true
    end

    it 'returns false when current time is before start date' do
      schedulable_instance.start_date = tomorrow
      schedulable_instance.end_date = next_week
      
      expect(schedulable_instance.current?).to be false
    end

    it 'returns false when current time is after end date' do
      schedulable_instance.start_date = 1.week.ago
      schedulable_instance.end_date = yesterday
      
      expect(schedulable_instance.current?).to be false
    end

    it 'returns false when dates are missing' do
      expect(schedulable_instance.current?).to be false
    end
  end

  describe '#upcoming?' do
    it 'returns true when start date is in the future' do
      schedulable_instance.start_date = tomorrow
      
      expect(schedulable_instance.upcoming?).to be true
    end

    it 'returns false when start date is in the past' do
      schedulable_instance.start_date = yesterday
      
      expect(schedulable_instance.upcoming?).to be false
    end

    it 'returns false when start date is missing' do
      expect(schedulable_instance.upcoming?).to be false
    end
  end

  describe '#past?' do
    it 'returns true when end date is in the past' do
      schedulable_instance.end_date = yesterday
      
      expect(schedulable_instance.past?).to be true
    end

    it 'returns false when end date is in the future' do
      schedulable_instance.end_date = tomorrow
      
      expect(schedulable_instance.past?).to be false
    end

    it 'returns false when end date is missing' do
      expect(schedulable_instance.past?).to be false
    end
  end

  describe '#overlaps_with?' do
    let(:other_schedulable) { test_class.new }

    before do
      schedulable_instance.start_date = yesterday
      schedulable_instance.end_date = tomorrow
    end

    it 'returns true when schedules overlap' do
      other_schedulable.start_date = now
      other_schedulable.end_date = next_week
      
      expect(schedulable_instance.overlaps_with?(other_schedulable)).to be true
    end

    it 'returns true when one schedule contains the other' do
      other_schedulable.start_date = now
      other_schedulable.end_date = now + 2.hours
      
      expect(schedulable_instance.overlaps_with?(other_schedulable)).to be true
    end

    it 'returns false when schedules do not overlap' do
      other_schedulable.start_date = next_week
      other_schedulable.end_date = next_week + 1.day
      
      expect(schedulable_instance.overlaps_with?(other_schedulable)).to be false
    end

    it 'returns false when other object does not respond to date methods' do
      other_object = Object.new
      expect(schedulable_instance.overlaps_with?(other_object)).to be false
    end

    it 'returns false when dates are missing' do
      other_schedulable.start_date = nil
      other_schedulable.end_date = nil
      
      expect(schedulable_instance.overlaps_with?(other_schedulable)).to be false
    end

    it 'handles edge case when schedules touch exactly' do
      other_schedulable.start_date = tomorrow
      other_schedulable.end_date = next_week
      
      expect(schedulable_instance.overlaps_with?(other_schedulable)).to be true
    end
  end

  describe '#progress_percentage' do
    it 'calculates progress percentage for current schedule' do
      travel_to(now) do
        schedulable_instance.start_date = 2.days.ago
        schedulable_instance.end_date = 2.days.from_now
        
        # Should be 50% complete (2 out of 4 days elapsed)
        expect(schedulable_instance.progress_percentage).to eq(50.0)
      end
    end

    it 'returns 0 for upcoming schedule' do
      schedulable_instance.start_date = tomorrow
      schedulable_instance.end_date = next_week
      
      expect(schedulable_instance.progress_percentage).to eq(0)
    end

    it 'returns 0 when dates are missing' do
      expect(schedulable_instance.progress_percentage).to eq(0)
    end

    it 'handles edge cases' do
      travel_to(now) do
        # Schedule that started now
        schedulable_instance.start_date = now
        schedulable_instance.end_date = tomorrow
        
        expect(schedulable_instance.progress_percentage).to eq(0.0)
        
        # Schedule that ends now
        schedulable_instance.start_date = yesterday
        schedulable_instance.end_date = now
        
        expect(schedulable_instance.progress_percentage).to eq(100.0)
      end
    end
  end

  describe '#remaining_time' do
    it 'calculates remaining time for current/future schedule' do
      schedulable_instance.end_date = 2.days.from_now
      
      remaining = schedulable_instance.remaining_time
      expect(remaining).to be_within(1.minute).of(2.days)
    end

    it 'returns 0 for past schedule' do
      schedulable_instance.end_date = yesterday
      
      expect(schedulable_instance.remaining_time).to eq(0)
    end

    it 'returns nil when end_date is missing' do
      expect(schedulable_instance.remaining_time).to be_nil
    end
  end

  describe '#remaining_days' do
    it 'calculates remaining days' do
      schedulable_instance.end_date = 3.days.from_now
      
      expect(schedulable_instance.remaining_days).to eq(3)
    end

    it 'returns nil when remaining_time is nil' do
      expect(schedulable_instance.remaining_days).to be_nil
    end
  end

  describe 'scopes' do
    let!(:current_item) do
      test_class.create!(start_date: yesterday, end_date: tomorrow)
    end
    
    let!(:upcoming_item) do
      test_class.create!(start_date: tomorrow, end_date: next_week)
    end
    
    let!(:past_item) do
      test_class.create!(start_date: 1.week.ago, end_date: yesterday)
    end

    before do
      # Skip these tests if we don't have the actual table structure
      skip "Scopes require actual database table" unless test_class.table_exists?
    end

    describe '.current' do
      it 'returns items that are currently active' do
        current_items = test_class.current
        expect(current_items).to include(current_item)
        expect(current_items).not_to include(upcoming_item, past_item)
      end
    end

    describe '.upcoming' do
      it 'returns items that start in the future' do
        upcoming_items = test_class.upcoming
        expect(upcoming_items).to include(upcoming_item)
        expect(upcoming_items).not_to include(current_item, past_item)
      end
    end

    describe '.past' do
      it 'returns items that have ended' do
        past_items = test_class.past
        expect(past_items).to include(past_item)
        expect(past_items).not_to include(current_item, upcoming_item)
      end
    end

    describe '.between_dates' do
      it 'returns items that overlap with the given date range' do
        items = test_class.between_dates(now, next_week)
        expect(items).to include(current_item, upcoming_item)
        expect(items).not_to include(past_item)
      end
    end

    describe '.starting_between' do
      it 'returns items that start within the given date range' do
        items = test_class.starting_between(yesterday, tomorrow)
        expect(items).to include(current_item)
        expect(items).not_to include(upcoming_item, past_item)
      end
    end

    describe '.ending_between' do
      it 'returns items that end within the given date range' do
        items = test_class.ending_between(yesterday, tomorrow)
        expect(items).to include(current_item, past_item)
        expect(items).not_to include(upcoming_item)
      end
    end
  end

  describe 'private methods' do
    describe '#schedule_required?' do
      it 'returns true by default' do
        expect(schedulable_instance.send(:schedule_required?)).to be true
      end
    end

    describe '#end_date_after_start_date' do
      it 'adds error when end_date is before start_date' do
        schedulable_instance.start_date = tomorrow
        schedulable_instance.end_date = yesterday
        
        schedulable_instance.valid?
        expect(schedulable_instance.errors[:end_date]).to include('doit être postérieure à la date de début')
      end

      it 'does not add error when dates are valid' do
        schedulable_instance.start_date = yesterday
        schedulable_instance.end_date = tomorrow
        
        schedulable_instance.valid?
        expect(schedulable_instance.errors[:end_date]).not_to include('doit être postérieure à la date de début')
      end

      it 'does not add error when dates are missing' do
        schedulable_instance.start_date = nil
        schedulable_instance.end_date = nil
        
        schedulable_instance.send(:end_date_after_start_date)
        expect(schedulable_instance.errors[:end_date]).not_to include('doit être postérieure à la date de début')
      end
    end
  end
end