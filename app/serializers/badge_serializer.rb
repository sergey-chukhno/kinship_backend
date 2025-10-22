# Badge serializer for API responses
# Includes series information (from Change #1)
class BadgeSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :level, :series
end

