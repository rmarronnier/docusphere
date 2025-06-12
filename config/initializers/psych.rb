# Allow Time class to be deserialized by Psych (YAML)
# This is needed for PaperTrail to deserialize version objects

# Configure YAML safe loading for Rails 7.1+
Rails.application.config.active_record.yaml_column_permitted_classes = [
  Time,
  Date,
  DateTime,
  ActiveSupport::TimeWithZone,
  ActiveSupport::TimeZone,
  Symbol,
  ActiveRecord::Type::Time::Value,
  BigDecimal
]

# Configure PaperTrail serializer if available
Rails.application.config.after_initialize do
  if defined?(PaperTrail) && PaperTrail.respond_to?(:serializer)
    # PaperTrail will use the Rails YAML config automatically
    PaperTrail.serializer = PaperTrail::Serializers::YAML
  end
end