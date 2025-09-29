# frozen_string_literal: true

RSpec::Matchers.define :have_a_valid_factory do
  match { |model_klass| build(model_klass.class.to_s.underscore.to_sym).valid? }
end
