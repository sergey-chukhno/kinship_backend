# Availability serializer for API responses
class AvailabilitySerializer < ActiveModel::Serializer
  attributes :id, :monday, :tuesday, :wednesday, :thursday, :friday, :other
end

