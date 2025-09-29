# frozen_string_literal: true

require "rails_helper"

RSpec.describe StepperComponent, type: :component, javascript: true do
  let(:teacher_options) { {role: "teacher"} }
  let(:children_options) { {role: "children"} }

  describe "#teacher?" do
    it "returns true for teacher? if role teacher is passed" do
      component = StepperComponent.new(current_step: 1, **teacher_options)
      expect(component.teacher?).to eq(true)
    end

    it "returns false for teacher? if role teacher isn't passed" do
      component = StepperComponent.new(current_step: 1, **children_options)
      expect(component.teacher?).to eq(false)
    end
  end

  describe "#children?" do
    it "returns true for children? if role children is passed" do
      component = StepperComponent.new(current_step: 1, **children_options)
      expect(component.children?).to eq(true)
    end

    it "returns false for children? if role children isn't passed" do
      component = StepperComponent.new(current_step: 1, **teacher_options)
      expect(component.children?).to eq(false)
    end
  end

  context "when user is a teacher" do
    subject(:rendered) { render_inline(described_class.new(current_step: 1, **teacher_options)) }

    it "renders only 3 steps with détails, mot de passe and compétences" do
      expect(rendered.css(".stepper").count).to eq(3)
      expect(rendered).to have_content "Détails"
      expect(rendered).to have_content "Mot de passe"
      expect(rendered).to_not have_content "Disponibilités"
      expect(rendered).to have_content "Compétences"
    end

    describe "first step" do
      it "renders first step" do
        expect(rendered.css(".stepper")[0].text.strip).to eq("Détails")
      end

      it "renders first step with current class" do
        expect(rendered.css(".stepper")[0].attr("class")).to eq("stepper current")
      end
    end
  end

  context "when user is a children" do
    subject(:rendered) { render_inline(described_class.new(current_step: 1, **children_options)) }

    it "renders only 2 steps with détails and compétences" do
      expect(rendered.css(".stepper").count).to eq(2)
      expect(rendered).to have_content "Détails"
      expect(rendered).to_not have_content "Mot de passe"
      expect(rendered).to_not have_content "Disponibilités"
      expect(rendered).to have_content "Compétences"
    end
  end

  context "when user is a tutor" do
    subject(:rendered) { render_inline(described_class.new(current_step: 1)) }

    it "renders 4 steps with détails, mot de passe, disponibilités and compétences" do
      expect(rendered.css(".stepper").count).to eq(4)
      expect(rendered).to have_content "Détails"
      expect(rendered).to have_content "Mot de passe"
      expect(rendered).to have_content "Disponibilités"
      expect(rendered).to have_content "Compétences"
    end
  end
end
