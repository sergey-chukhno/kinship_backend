module AssignBadgeStepper
  class SecondStep
    include ActiveModel::Model
    include ActiveModel::Translation

    attr_accessor :project_id
  end
end
