RSpec.shared_examples 'schedulable' do
  describe 'schedulable fields' do
    it { is_expected.to respond_to(:start_date) }
    it { is_expected.to respond_to(:end_date) }
  end

  describe 'validations' do
    context 'when end_date is before start_date' do
      it 'is invalid' do
        subject.start_date = Date.today
        subject.end_date = Date.yesterday
        subject.valid?
        expect(subject.errors[:end_date]).to include("must be after or equal to #{subject.start_date}")
      end
    end

    context 'when end_date equals start_date' do
      it 'is valid' do
        subject.start_date = Date.today
        subject.end_date = Date.today
        expect(subject).to be_valid
      end
    end

    context 'when end_date is after start_date' do
      it 'is valid' do
        subject.start_date = Date.today
        subject.end_date = Date.tomorrow
        expect(subject).to be_valid
      end
    end
  end

  describe '#duration' do
    context 'when both dates are present' do
      it 'returns the number of days between start and end dates' do
        subject.start_date = Date.new(2025, 1, 1)
        subject.end_date = Date.new(2025, 1, 10)
        expect(subject.duration).to eq(9)
      end

      it 'returns 0 when start and end dates are the same' do
        subject.start_date = Date.today
        subject.end_date = Date.today
        expect(subject.duration).to eq(0)
      end
    end

    context 'when dates are missing' do
      it 'returns nil when start_date is missing' do
        subject.start_date = nil
        subject.end_date = Date.today
        expect(subject.duration).to be_nil
      end

      it 'returns nil when end_date is missing' do
        subject.start_date = Date.today
        subject.end_date = nil
        expect(subject.duration).to be_nil
      end

      it 'returns nil when both dates are missing' do
        subject.start_date = nil
        subject.end_date = nil
        expect(subject.duration).to be_nil
      end
    end
  end

  describe '#scheduled?' do
    it 'returns true when both dates are present' do
      subject.start_date = Date.today
      subject.end_date = Date.tomorrow
      expect(subject.scheduled?).to be true
    end

    it 'returns false when start_date is missing' do
      subject.start_date = nil
      subject.end_date = Date.today
      expect(subject.scheduled?).to be false
    end

    it 'returns false when end_date is missing' do
      subject.start_date = Date.today
      subject.end_date = nil
      expect(subject.scheduled?).to be false
    end
  end

  describe '#in_progress?' do
    it 'returns true when current date is between start and end dates' do
      subject.start_date = Date.yesterday
      subject.end_date = Date.tomorrow
      expect(subject.in_progress?).to be true
    end

    it 'returns true when current date equals start date' do
      subject.start_date = Date.today
      subject.end_date = Date.tomorrow
      expect(subject.in_progress?).to be true
    end

    it 'returns true when current date equals end date' do
      subject.start_date = Date.yesterday
      subject.end_date = Date.today
      expect(subject.in_progress?).to be true
    end

    it 'returns false when current date is before start date' do
      subject.start_date = Date.tomorrow
      subject.end_date = Date.tomorrow + 10
      expect(subject.in_progress?).to be false
    end

    it 'returns false when current date is after end date' do
      subject.start_date = Date.yesterday - 10
      subject.end_date = Date.yesterday
      expect(subject.in_progress?).to be false
    end

    it 'returns false when dates are not set' do
      subject.start_date = nil
      subject.end_date = nil
      expect(subject.in_progress?).to be false
    end
  end

  describe '#past?' do
    it 'returns true when end date is in the past' do
      subject.start_date = Date.yesterday - 10
      subject.end_date = Date.yesterday
      expect(subject.past?).to be true
    end

    it 'returns false when end date is today' do
      subject.start_date = Date.yesterday
      subject.end_date = Date.today
      expect(subject.past?).to be false
    end

    it 'returns false when end date is in the future' do
      subject.start_date = Date.today
      subject.end_date = Date.tomorrow
      expect(subject.past?).to be false
    end

    it 'returns false when end date is not set' do
      subject.start_date = Date.yesterday
      subject.end_date = nil
      expect(subject.past?).to be false
    end
  end

  describe '#future?' do
    it 'returns true when start date is in the future' do
      subject.start_date = Date.tomorrow
      subject.end_date = Date.tomorrow + 10
      expect(subject.future?).to be true
    end

    it 'returns false when start date is today' do
      subject.start_date = Date.today
      subject.end_date = Date.tomorrow
      expect(subject.future?).to be false
    end

    it 'returns false when start date is in the past' do
      subject.start_date = Date.yesterday
      subject.end_date = Date.today
      expect(subject.future?).to be false
    end

    it 'returns false when start date is not set' do
      subject.start_date = nil
      subject.end_date = Date.tomorrow
      expect(subject.future?).to be false
    end
  end
end