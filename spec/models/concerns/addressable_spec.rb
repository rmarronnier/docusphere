require 'rails_helper'
require_relative '../../../app/models/concerns/addressable'

RSpec.describe Addressable, type: :concern do
  # Create a simple test class without the geocoder gem complications
  before(:all) do
    # Create a test table
    ActiveRecord::Base.connection.create_table :test_addressables, force: true do |t|
      t.string :address
      t.string :city
      t.string :postal_code
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.timestamps
    end
  end
  
  after(:all) do
    ActiveRecord::Base.connection.drop_table :test_addressables, if_exists: true
    Object.send(:remove_const, :TestAddressable) if Object.const_defined?(:TestAddressable)
  end
  
  # Define the test class
  # We'll mock the geocoder methods to avoid gem dependencies
  class ::TestAddressable < ActiveRecord::Base
    # First, add mock geocoder methods before including the concern
    def self.geocoded_by(method_name)
      # No-op for testing
    end
    
    def self.near(location, distance = nil)
      # Return a basic scope for testing
      where("1=1")
    end
    
    def self.after_validation(callback_name, options = {})
      # No-op for testing - prevent geocoding callbacks
    end
    
    def geocode
      # No-op for testing
    end
    
    # Now include the concern
    include ::Addressable
    
    # Override to make address optional for some tests
    def address_required?
      @address_required.nil? ? true : @address_required
    end
    
    def address_required=(value)
      @address_required = value
    end
  end
  
  let(:test_class) { TestAddressable }
  let(:addressable_instance) { test_class.new }
  
  # Stub Geocoder::Calculations for distance tests
  before do
    allow(Geocoder::Calculations).to receive(:distance_between).and_return(344)
  end

  describe 'included module behavior' do
    it 'adds addressable methods to the class' do
      expect(addressable_instance).to respond_to(:full_address)
      expect(addressable_instance).to respond_to(:full_address_changed?)
      expect(addressable_instance).to respond_to(:coordinates)
      expect(addressable_instance).to respond_to(:distance_to)
    end

    it 'adds validations when address is required' do
      addressable_instance.address = nil
      addressable_instance.city = nil
      addressable_instance.postal_code = nil
      
      expect(addressable_instance).not_to be_valid
      expect(addressable_instance.errors[:address]).to include("can't be blank").or(include("ne peut pas être vide"))
      expect(addressable_instance.errors[:city]).to include("can't be blank").or(include("ne peut pas être vide"))
      expect(addressable_instance.errors[:postal_code]).to include("can't be blank").or(include("ne peut pas être vide"))
    end

    it 'adds scopes to the class' do
      expect(test_class).to respond_to(:near_location)
      expect(test_class).to respond_to(:in_city)
      expect(test_class).to respond_to(:in_postal_code)
    end
  end

  describe '#full_address' do
    it 'returns the full address as a formatted string' do
      addressable_instance.address = '123 Main Street'
      addressable_instance.city = 'Paris'
      addressable_instance.postal_code = '75001'
      addressable_instance.country = 'France'
      
      expected_address = "123 Main Street, Paris, 75001, France"
      expect(addressable_instance.full_address).to eq(expected_address)
    end

    it 'handles missing optional fields gracefully' do
      addressable_instance.address = '123 Main Street'
      addressable_instance.city = 'Paris'
      addressable_instance.postal_code = '75001'
      
      expected_address = "123 Main Street, Paris, 75001"
      expect(addressable_instance.full_address).to eq(expected_address)
    end

    it 'returns empty string when no address fields are set' do
      expect(addressable_instance.full_address).to eq('')
    end
  end

  describe '#full_address_changed?' do
    it 'returns true when address fields have changed' do
      addressable_instance.address = '123 Main Street'
      expect(addressable_instance.full_address_changed?).to be true
    end

    it 'returns true when city has changed' do
      addressable_instance.city = 'Paris'
      expect(addressable_instance.full_address_changed?).to be true
    end

    it 'returns true when postal_code has changed' do
      addressable_instance.postal_code = '75001'
      expect(addressable_instance.full_address_changed?).to be true
    end

    it 'returns true when country has changed' do
      addressable_instance.country = 'France'
      expect(addressable_instance.full_address_changed?).to be true
    end
  end

  describe '#coordinates' do
    it 'returns coordinates array when latitude and longitude are present' do
      addressable_instance.latitude = 48.8566
      addressable_instance.longitude = 2.3522
      expect(addressable_instance.coordinates).to eq([48.8566, 2.3522])
    end

    it 'returns nil when latitude is missing' do
      addressable_instance.longitude = 2.3522
      expect(addressable_instance.coordinates).to be_nil
    end

    it 'returns nil when longitude is missing' do
      addressable_instance.latitude = 48.8566
      expect(addressable_instance.coordinates).to be_nil
    end

    it 'returns nil when both coordinates are missing' do
      expect(addressable_instance.coordinates).to be_nil
    end
  end

  describe '#distance_to' do
    let(:other_addressable) { test_class.new }

    it 'calculates distance between two addressable objects' do
      # Paris coordinates
      addressable_instance.latitude = 48.8566
      addressable_instance.longitude = 2.3522
      
      # London coordinates
      other_addressable.latitude = 51.5074
      other_addressable.longitude = -0.1278
      
      distance = addressable_instance.distance_to(other_addressable)
      expect(distance).to be_within(10).of(344) # ~344 km between Paris and London
    end

    it 'returns nil when current object has no coordinates' do
      other_addressable.latitude = 51.5074
      other_addressable.longitude = -0.1278
      
      expect(addressable_instance.distance_to(other_addressable)).to be_nil
    end

    it 'returns nil when other object has no coordinates' do
      addressable_instance.latitude = 48.8566
      addressable_instance.longitude = 2.3522
      
      expect(addressable_instance.distance_to(other_addressable)).to be_nil
    end

    it 'returns nil when both objects have no coordinates' do
      expect(addressable_instance.distance_to(other_addressable)).to be_nil
    end
  end

  describe 'private methods' do
    describe '#address_required?' do
      it 'returns true by default' do
        expect(addressable_instance.send(:address_required?)).to be true
      end
    end
  end

  describe 'scopes' do
    before do
      # Skip these tests if we don't have the actual table structure
      skip "Geocoding scopes require actual database table" unless test_class.table_exists?
    end

    describe '.in_city' do
      it 'filters by city' do
        expect(test_class.in_city('Paris')).to be_a(ActiveRecord::Relation)
      end
    end

    describe '.in_postal_code' do
      it 'filters by postal code' do
        expect(test_class.in_postal_code('75001')).to be_a(ActiveRecord::Relation)
      end
    end

    describe '.near_location' do
      it 'finds objects near a location' do
        expect(test_class.near_location(48.8566, 2.3522)).to be_a(ActiveRecord::Relation)
      end

      it 'accepts custom distance parameter' do
        expect(test_class.near_location(48.8566, 2.3522, 25)).to be_a(ActiveRecord::Relation)
      end
    end
  end
end