require "rails_helper"

RSpec.describe RegistrationService, type: :service do
  describe "#call" do
    describe "personal_user registration" do
      let(:valid_params) do
        {
          registration_type: "personal_user",
          user: {
            email: "parent@example.com",
            password: "Password123!",
            password_confirmation: "Password123!",
            first_name: "John",
            last_name: "Doe",
            birthday: "1990-01-01",
            role: "parent",
            accept_privacy_policy: true
          }
        }
      end

      context "with valid data" do
        it "creates user successfully" do
          result = RegistrationService.new(valid_params).call
          
          expect(result[:success]).to be true
          expect(result[:user]).to be_persisted
          expect(result[:user].email).to eq("parent@example.com")
          expect(result[:user].role).to eq("parent")
          expect(result[:user].role_additional_information).to eq("Parent")
        end

        it "sends confirmation email" do
          expect_any_instance_of(User).to receive(:send_confirmation_instructions).at_least(:once)
          RegistrationService.new(valid_params).call
        end

        it "auto-populates role_additional_information" do
          result = RegistrationService.new(valid_params).call
          expect(result[:user].role_additional_information).to eq("Parent")
        end
      end

      context "with children_info" do
        let(:params_with_children) do
          valid_params.deep_merge(
            children_info: [
              {
                first_name: "Alice",
                last_name: "Doe",
                birthday: "2010-05-15"
              }
            ]
          )
        end

        it "creates ParentChildInfo records" do
          result = RegistrationService.new(params_with_children).call
          
          expect(result[:success]).to be true
          expect(result[:user].parent_child_infos.count).to eq(1)
          expect(result[:user].parent_child_infos.first.first_name).to eq("Alice")
        end
      end

      context "with joining schools and companies" do
        let!(:school) { create(:school, :confirmed) }
        let!(:company) { create(:company, status: :confirmed) }
        let(:params_with_orgs) do
          valid_params.deep_merge(
            join_school_ids: [school.id],
            join_company_ids: [company.id]
          )
        end

        it "creates pending UserSchool records" do
          result = RegistrationService.new(params_with_orgs).call
          
          expect(result[:success]).to be true
          user_school = result[:user].user_schools.find_by(school: school)
          expect(user_school).to be_present
          expect(user_school.status).to eq("pending")
          expect(user_school.role).to eq("member")
        end

        it "creates pending UserCompany records" do
          result = RegistrationService.new(params_with_orgs).call
          
          expect(result[:success]).to be true
          user_company = result[:user].user_company.find_by(company: company)
          expect(user_company).to be_present
          expect(user_company.status).to eq("pending")
          expect(user_company.role).to eq("member")
        end
      end

      context "with invalid data" do
        it "returns errors for invalid email" do
          params = valid_params.deep_merge(user: { email: "invalid_email" })
          result = RegistrationService.new(params).call
          
          expect(result[:success]).to be false
          expect(result[:errors]).to be_present
        end

        it "returns errors for weak password" do
          params = valid_params.deep_merge(user: { password: "weak" })
          result = RegistrationService.new(params).call
          
          expect(result[:success]).to be false
          expect(result[:errors]).to be_present
        end

        it "returns errors for user under 13" do
          params = valid_params.deep_merge(user: { birthday: Date.today - 10.years })
          result = RegistrationService.new(params).call
          
          expect(result[:success]).to be false
          expect(result[:errors]).to be_present
        end

        it "returns errors for academic email with personal user role" do
          params = valid_params.deep_merge(user: { email: "user@ac-nantes.fr" })
          result = RegistrationService.new(params).call
          
          expect(result[:success]).to be false
          expect(result[:errors]).to include(match(/academic email/))
        end
      end
    end

    describe "teacher registration" do
      let(:valid_params) do
        {
          registration_type: "teacher",
          user: {
            email: "teacher@ac-nantes.fr",
            password: "Password123!",
            password_confirmation: "Password123!",
            first_name: "Jane",
            last_name: "Smith",
            birthday: "1985-03-20",
            role: "school_teacher",
            accept_privacy_policy: true
          }
        }
      end

      context "with valid data" do
        it "creates user successfully" do
          result = RegistrationService.new(valid_params).call
          
          expect(result[:success]).to be true
          expect(result[:user]).to be_persisted
          expect(result[:user].role).to eq("school_teacher")
          expect(User.is_teacher_role?(result[:user].role)).to be true
        end

        it "auto-creates IndependentTeacher" do
          result = RegistrationService.new(valid_params).call
          
          expect(result[:user].independent_teacher).to be_present
          expect(result[:user].independent_teacher.status).to eq("active")
        end

        it "requires academic email" do
          params = valid_params.deep_merge(user: { email: "teacher@example.com" })
          result = RegistrationService.new(params).call
          
          expect(result[:success]).to be false
          expect(result[:errors]).to include(match(/academic email/))
        end
      end
    end

    describe "school registration" do
      let(:valid_params) do
        {
          registration_type: "school",
          user: {
            email: "director@ac-nantes.fr",
            password: "Password123!",
            password_confirmation: "Password123!",
            first_name: "Marie",
            last_name: "Dupont",
            birthday: "1975-06-15",
            role: "school_director",
            accept_privacy_policy: true
          },
          school: {
            name: "Test School",
            zip_code: "44000",
            city: "Nantes",
            school_type: "lycee"
          }
        }
      end

      context "with valid data" do
        it "creates user and school successfully" do
          result = RegistrationService.new(valid_params).call
          
          expect(result[:success]).to be true
          expect(result[:user]).to be_persisted
          expect(result[:school]).to be_persisted
          expect(result[:school].name).to eq("Test School")
          expect(result[:school].status).to eq("pending")
        end

        it "creates UserSchool as superadmin (pending)" do
          result = RegistrationService.new(valid_params).call
          
          user_school = result[:user].user_schools.find_by(school: result[:school])
          expect(user_school).to be_present
          expect(user_school.role).to eq("superadmin")
          expect(user_school.status).to eq("pending")
        end
      end
    end

    describe "company registration" do
      let!(:company_type) { create(:company_type) }
      let(:valid_params) do
        {
          registration_type: "company",
          user: {
            email: "ceo@example.com",
            password: "Password123!",
            password_confirmation: "Password123!",
            first_name: "Sophie",
            last_name: "Bernard",
            birthday: "1980-01-01",
            role: "company_director",
            accept_privacy_policy: true
          },
          company: {
            name: "Test Company",
            description: "A test company",
            zip_code: "75001",
            city: "Paris",
            company_type_id: company_type.id,
            referent_phone_number: "0123456789"
          }
        }
      end

      context "with valid data" do
        it "creates user and company successfully" do
          result = RegistrationService.new(valid_params).call
          
          expect(result[:success]).to be true
          expect(result[:user]).to be_persisted
          expect(result[:company]).to be_persisted
          expect(result[:company].name).to eq("Test Company")
          expect(result[:company].status).to eq("confirmed")
        end

        it "creates UserCompany as superadmin (pending)" do
          result = RegistrationService.new(valid_params).call
          
          user_company = result[:user].user_company.find_by(company: result[:company])
          expect(user_company).to be_present
          expect(user_company.role).to eq("superadmin")
          expect(user_company.status).to eq("pending")
        end
      end

      context "with branch request" do
        let!(:main_company) { create(:company, status: :confirmed) }
        let(:params_with_branch) do
          valid_params.deep_merge(
            company: {
              branch_request_to_company_id: main_company.id
            }
          )
        end

        it "creates BranchRequest" do
          result = RegistrationService.new(params_with_branch).call
          
          expect(result[:success]).to be true
          branch_request = BranchRequest.find_by(child: result[:company], parent: main_company)
          expect(branch_request).to be_present
          expect(branch_request.status).to eq("pending")
          expect(branch_request.initiator).to eq(result[:company])
        end
      end
    end

    describe "validation errors" do
      it "returns error for invalid registration_type" do
        params = { registration_type: "invalid_type", user: {} }
        result = RegistrationService.new(params).call
        
        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Invalid registration_type/))
      end

      it "returns error for wrong role for registration type" do
        params = {
          registration_type: "teacher",
          user: {
            email: "teacher@ac-nantes.fr",
            password: "Password123!",
            first_name: "Test",
            last_name: "User",
            birthday: "1990-01-01",
            role: "parent",
            accept_privacy_policy: true
          }
        }
        result = RegistrationService.new(params).call
        
        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Invalid role for teacher registration/))
      end
    end

    describe "transaction rollback" do
      it "rolls back all changes on error" do
        params = {
          registration_type: "school",
          user: {
            email: "director@ac-nantes.fr",
            password: "Password123!",
            first_name: "Test",
            last_name: "User",
            birthday: "1990-01-01",
            role: "school_director",
            accept_privacy_policy: true
          },
          school: {
            name: nil, # Invalid - will cause error
            zip_code: "44000",
            city: "Nantes"
          }
        }

        user_count_before = User.count
        school_count_before = School.count

        result = RegistrationService.new(params).call
        
        expect(result[:success]).to be false
        expect(User.count).to eq(user_count_before)
        expect(School.count).to eq(school_count_before)
      end
    end
  end
end

