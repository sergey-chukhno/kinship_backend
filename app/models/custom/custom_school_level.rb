module Custom
  class CustomSchoolLevel
    include ActiveModel::Model
    attr_accessor :level, :name, :school_id

    validates :level, :name, :school_id, presence: true

    def full_name
      "#{level} #{name}"
    end
  end
end
