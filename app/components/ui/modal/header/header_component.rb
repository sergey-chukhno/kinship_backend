# frozen_string_literal: true

class Ui::Modal::Header::HeaderComponent < ViewComponent::Base
  def initialize(back_link: nil, title: nil)
    @back_link = back_link
    @title = title
  end
end
