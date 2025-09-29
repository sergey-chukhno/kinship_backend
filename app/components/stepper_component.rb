# frozen_string_literal: true

class StepperComponent < ViewComponent::Base
  def initialize(current_step:, **options)
    @current_step = current_step
    @options = options
  end

  def teacher?
    @options[:role] == "teacher"
  end

  def children?
    @options[:role] == "children"
  end

  def company_form?
    @options[:company_form] == "true"
  end
end
