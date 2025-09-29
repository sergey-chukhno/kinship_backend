# frozen_string_literal: true

require "rails_helper"

RSpec.describe TurboModalComponent, type: :component do
  let(:title) { "Test Title" }
  let(:component) { described_class.new(title:) }

  subject(:rendered_component) { render_inline(component) }

  it "renders turbo frame tag" do
    expect(rendered_component).to have_css 'turbo-frame[id="modal"]'
  end

  it "renders div with correct data attributes" do
    expect(rendered_component).to have_css('div[data-controller="turbo-modal"][data-turbo-modal-target="modal"]')
  end

  it "renders div with modal-content class" do
    expect(rendered_component).to have_css("div.modal-content")
  end

  it "renders link to close modal" do
    expect(rendered_component).to have_css('a[data-action="turbo-modal#hideModal"]')
  end

  it "renders title" do
    expect(rendered_component).to have_text(title)
  end
end
