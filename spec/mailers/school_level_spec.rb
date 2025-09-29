require "rails_helper"

RSpec.describe SchoolLevelMailer, type: :mailer do
  it "inherits from PostmarkRails::TemplatedMailer" do
    expect(described_class).to be < PostmarkRails::TemplatedMailer
  end

  describe "#school_level_creation_request" do
    let(:user_requestor) { create(:user, :tutor, first_name: "John", last_name: "Doe") }
    let(:school) { create(:school) }
    let(:school_level_wanted) { "terminal B des paquerette" }
    let(:mail) {
      SchoolLevelMailer.school_level_creation_request(
        user_requestor_email: user_requestor.email,
        user_requestor_full_name: user_requestor.full_name,
        school:,
        school_level_wanted:
      )
    }

    it "renders the headers" do
      expect(mail.subject.strip).to include("school-level-creation-request")
      expect(mail.to).to eq(["kinship@drakkar.io"])
      expect(mail.from).to eq(["support@kinshipedu.fr"])
    end

    it "assigns correct template_model" do
      expected_template_model = {
        name: user_requestor.full_name,
        requestor_email: user_requestor.email,
        school_name: school.full_name,
        action_url: new_admin_school_level_url(school_level: {school_id: school.id}),
        school_level_wanted:
      }
      expect(mail.template_model).to eq(expected_template_model)
    end
  end
end
