# frozen_string_literal: true

class Ui::ButtonComponentPreview < ViewComponent::Preview
  layout "lookbook"

  # @!group Primary
  def medium_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      size: :md
    ).with_content("Medium"))
  end

  def square_medium_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      size: :md,
      square: true
    ))
  end

  def rounded_medium_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      size: :md,
      rounded: true
    ).with_content("Medium"))
  end

  def square_rounded_medium_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      size: :md,
      rounded: true,
      square: true
    ))
  end

  def small_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      size: :sm
    ).with_content("Small"))
  end

  def square_small_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      size: :sm,
      square: true
    ))
  end

  def rounded_small_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      size: :sm,
      rounded: true
    ).with_content("Small"))
  end

  def square_rounded_small_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      size: :sm,
      rounded: true,
      square: true
    ))
  end

  def disabled_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      disabled: true
    ).with_content("Disabled"))
  end

  def full_primary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :primary,
      full: true
    ).with_content("Full"))
  end

  # @!endgroup

  # @!group Secondary
  def medium_secondary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :secondary,
      size: :md
    ).with_content("Medium"))
  end

  def small_secondary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :secondary,
      size: :sm
    ).with_content("Small"))
  end

  def disabled_secondary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :secondary,
      disabled: true
    ).with_content("Disabled"))
  end

  def full_secondary
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :secondary,
      full: true
    ).with_content("Full"))
  end
  # @!endgroup

  # @!group Ghost
  def medium_ghost
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :ghost,
      size: :md
    ).with_content("Medium"))
  end

  def small_ghost
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :ghost,
      size: :sm
    ).with_content("Small"))
  end

  def disabled_ghost
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :ghost,
      disabled: true
    ).with_content("Disabled"))
  end

  def full_ghost
    render(Ui::Button::ButtonComponent.new(
      builder: :button,
      style: :ghost,
      full: true
    ).with_content("Full"))
  end
  # @!endgroup
end
