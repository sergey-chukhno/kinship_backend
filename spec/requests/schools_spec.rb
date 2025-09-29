require "rails_helper"

RSpec.describe "Schools", type: :request do
  describe "GET /new" do
    context "when user is not logged in" do
      it "redirects to login page" do
        get new_school_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is logged in" do
      let(:teacher) { create(:user, :teacher) }
      let(:tutor) { create(:user, :tutor) }
      let(:voluntary) { create(:user, :voluntary) }

      before do
        teacher.confirm
        tutor.confirm
        voluntary.confirm
      end

      it "returns http success if user role is teacher" do
        sign_in teacher

        get new_school_path
        expect(response).to have_http_status(:success)
      end

      it "returns http error if user role is tutor" do
        sign_in tutor

        get new_school_path
        expect(response).to have_http_status(:found)
      end

      it "returns http error if user role is voluntary" do
        sign_in voluntary

        get new_school_path
        expect(response).to have_http_status(:found)
      end
    end
  end
end
