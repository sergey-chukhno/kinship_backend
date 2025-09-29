require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  it "inherits from PostmarkRails::TemplatedMailer" do
    expect(described_class).to be < PostmarkRails::TemplatedMailer
  end

  describe "#reset_password_instructions" do
    let(:user) { create(:user, :teacher, email: "notcontact@ac-nice.fr", contact_email: "contact@mail.com") }
    let(:token) { "token" }
    let(:mail) { UserMailer.reset_password_instructions(user, token) }

    it "renders the headers" do
      expect(mail.subject.strip).to include("reset-password-instructions")
      expect(mail.to).to eq([user.preferred_email])
      expect(mail.from).to eq(["support@kinshipedu.fr"])
    end

    it "assigns correct template_model" do
      expected_template_model = {
        name: "#{user[:first_name]} #{user[:last_name]}",
        action_url: "http://localhost:3000/auth/password/edit?reset_password_token=token"
      }
      expect(mail.template_model).to eq(expected_template_model)
    end
  end

  describe "#request_participation_to_project" do
    let(:owner) { create(:user, :teacher, first_name: "John", last_name: "Doe", email: "teacher@ac-nice.fr") }
    let(:participant) { create(:user, :tutor, first_name: "Jane", last_name: "Fonda") }
    let(:project) { create(:project, title: "Mon super projet") }
    let(:message) { "Je veux participer à ton projet" }
    let(:mail) { UserMailer.request_participation_to_project(owner:, participant:, message:, project:) }
    let(:mail_without_project) { UserMailer.request_participation_to_project(owner:, participant:, message:) }

    context "With project" do
      it "renders the headers" do
        expect(mail.subject.strip).to include("request-participation-to-project")
        expect(mail.to).to eq([participant.preferred_email])
        expect(mail.from).to eq(["support@kinshipedu.fr"])
      end

      it "assigns correct template_model" do
        expected_template_model = {
          name: participant.full_name,
          owner_name: owner.full_name,
          owner_email: owner.preferred_email,
          project_name: project.title,
          message:
        }
        expect(mail.template_model).to eq(expected_template_model)
      end
    end

    context "Without project" do
      it "renders the headers" do
        expect(mail_without_project.subject.strip).to include("request-participation-to-project")
        expect(mail_without_project.to).to eq([participant.preferred_email])
        expect(mail_without_project.from).to eq(["support@kinshipedu.fr"])
      end

      it "assigns correct template_model" do
        expected_template_model = {
          name: participant.full_name,
          owner_name: owner.full_name,
          owner_email: owner.preferred_email,
          project_name: "Projet en cours de création",
          message:
        }
        expect(mail_without_project.template_model).to eq(expected_template_model)
      end
    end
  end

  describe "#send_welcome_email" do
    let(:user) { create(:user, :teacher, first_name: "John", last_name: "Doe", email: "john@ac-nice.Fr") }
    let(:mail) { UserMailer.send_welcome_email(user) }

    it "renders the headers" do
      expect(mail.subject.strip).to include("welcome")
      expect(mail.to).to eq([user.preferred_email])
      expect(mail.from).to eq(["support@kinshipedu.fr"])
    end

    it "assigns correct template_model" do
      expected_template_model = {
        name: user.full_name,
        email: user.preferred_email
      }
      expect(mail.template_model).to eq(expected_template_model)
    end
  end
end
