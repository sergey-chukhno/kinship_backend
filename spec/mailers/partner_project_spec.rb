require "rails_helper"

RSpec.describe PartnerProjectMailer, type: :mailer do
  describe "notify_new_partner_project" do
    let(:mail) { PartnerProjectMailer.notify_new_partner_project }

    it "renders the headers" do
      expect(mail.subject).to eq("Notify new partner project")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
