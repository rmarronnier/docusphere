RSpec.shared_examples 'addressable' do
  describe 'addressable fields' do
    it { is_expected.to respond_to(:address) }
    it { is_expected.to respond_to(:city) }
    it { is_expected.to respond_to(:postal_code) }
    it { is_expected.to respond_to(:country) }
    it { is_expected.to respond_to(:latitude) }
    it { is_expected.to respond_to(:longitude) }
  end

  describe '#full_address' do
    it 'returns the full address as a formatted string' do
      subject.address = '123 Main Street'
      subject.city = 'Paris'
      subject.postal_code = '75001'
      subject.country = 'France'
      
      expected_address = "123 Main Street, Paris, 75001, France"
      expect(subject.full_address).to eq(expected_address)
    end

    it 'handles missing optional fields gracefully' do
      subject.address = '123 Main Street'
      subject.city = 'Paris'
      subject.postal_code = '75001'
      
      expected_address = "123 Main Street, Paris, 75001"
      expect(subject.full_address).to eq(expected_address)
    end

    it 'returns empty string when no address fields are set' do
      expect(subject.full_address).to eq('')
    end
  end

  describe '#coordinates' do
    it 'returns coordinates array when latitude and longitude are present' do
      subject.latitude = 48.8566
      subject.longitude = 2.3522
      expect(subject.coordinates).to eq([48.8566, 2.3522])
    end

    it 'returns nil when coordinates are not set' do
      expect(subject.coordinates).to be_nil
    end
  end

  describe '#distance_to' do
    let(:other) { subject.class.new }

    it 'calculates distance between two addressable objects' do
      subject.latitude = 48.8566
      subject.longitude = 2.3522
      other.latitude = 51.5074
      other.longitude = -0.1278
      
      distance = subject.distance_to(other)
      expect(distance).to be_within(10).of(344) # ~344 km between Paris and London
    end

    it 'returns nil when coordinates are missing' do
      expect(subject.distance_to(other)).to be_nil
    end
  end
end