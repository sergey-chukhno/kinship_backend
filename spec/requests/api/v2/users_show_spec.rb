require "swagger_helper"

RSpec.describe "API V2 Users Show", type: :request do
  path "/api/v2/users/{id}" do
    get "Get user details" do
      tags "Users (V2)"
      produces "application/json"
      security [ApiKeyAuth: []]
      description <<~DESC
        Returns detailed information about a specific user including their skills, badges received, 
        and project participation. Access is restricted to users who are confirmed members of 
        companies associated with the API access token.
      DESC

      parameter name: :id,
        in: :path,
        type: :integer,
        required: true,
        description: "User ID",
        example: 1

      parameter name: :token,
        in: :query,
        type: :string,
        required: true,
        description: "API access token for authentication",
        example: "your-api-token-here"

      response "200", "successful" do
        schema type: :object,
          properties: {
            id: {type: :integer},
            first_name: {type: :string},
            last_name: {type: :string},
            email: {type: :string, format: :email},
            role: {type: :string},
            birthday: {type: :string, format: :date, nullable: true},
            role_additional_information: {type: :string, nullable: true},
            job: {type: :string, nullable: true},
            company_name: {type: :string, nullable: true},
            certify: {type: :boolean},
            skills: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  name: {type: :string}
                }
              }
            },
            badges_received: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  project_title: {type: :string},
                  project_description: {type: :string},
                  created_at: {type: :string, format: "date-time"},
                  badge: {
                    type: :object,
                    properties: {
                      id: {type: :integer},
                      name: {type: :string},
                      level: {type: :string},
                      badge_skills: {
                        type: :array,
                        items: {
                          type: :object,
                          properties: {
                            name: {type: :string},
                            category: {type: :string}
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            project_members: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  project: {
                    type: :object,
                    properties: {
                      id: {type: :integer},
                      title: {type: :string},
                      description: {type: :string},
                      skills: {
                        type: :array,
                        items: {
                          type: :object,
                          properties: {
                            name: {type: :string}
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

        let!(:company_type) { create(:company_type) }
        let!(:company) { create(:company, :confirmed, company_type: company_type) }
        let!(:api_access) { create(:api_access, name: "Test API Access", token: "test-token-123") }
        let!(:company_api_access) { create(:company_api_access, api_access: api_access, company: company) }

        context "with valid API token and authorized user" do
          let(:token) { api_access.token }

          let!(:skill1) { create(:skill, name: "Mathematics") }
          let!(:skill2) { create(:skill, name: "Programming") }

          let!(:user) do
            user = create(:user, :confirmed,
              first_name: "John",
              last_name: "Doe",
              email: "john.doe@ac-nantes.fr",
              role: :teacher,
              birthday: Date.parse("1985-05-15"),
              role_additional_information: "Mathematics specialist",
              job: "Senior Teacher",
              company_name: "Tech High School",
              certify: true)
            create(:user_company, user: user, company: company, status: :confirmed)
            create(:user_skill, user: user, skill: skill1)
            create(:user_skill, user: user, skill: skill2)
            user
          end

          let!(:badge) do
            create(:badge, name: "AI Mentor", level: :level_2)
          end

          let!(:badge_skill) do
            create(:badge_skill, badge: badge, name: "Artificial Intelligence", category: :domain)
          end

          let!(:school) { create(:school, status: :confirmed, school_type: :college) }
          let!(:school_level) { create(:school_level, school: school, level: :sixieme) }

          let!(:project) do
            create(:project,
              title: "Web Development Course",
              description: "Learn modern web development",
              owner: user,
              start_date: 1.month.ago,
              end_date: 1.month.from_now,
              project_school_levels_attributes: [{school_level_id: school_level.id}])
          end

          let!(:project_skill) do
            create(:project_skill, project: project, skill: skill1)
          end

          let!(:user_badge) do
            create(:user_badge, :level_2, :approved,
              receiver: user,
              sender: create(:user, :confirmed),
              badge: badge,
              project_title: "AI Workshop",
              project_description: "Introduction to AI concepts",
              organization: company)
          end

          let!(:project_member) do
            create(:project_member, user: user, project: project, status: :confirmed)
          end

          let(:id) { user.id }

          run_test! do |response|
            json_response = JSON.parse(response.body)

            # Basic user info
            expect(json_response["id"]).to eq(user.id)
            expect(json_response["first_name"]).to eq("John")
            expect(json_response["last_name"]).to eq("Doe")
            expect(json_response["email"]).to eq("john.doe@ac-nantes.fr")
            expect(json_response["role"]).to eq("teacher")
            expect(json_response["certify"]).to be true

            # Skills
            expect(json_response["skills"]).to be_an(Array)
            expect(json_response["skills"].size).to eq(2)
            skill_names = json_response["skills"].map { |s| s["name"] }
            expect(skill_names).to contain_exactly("Mathematics", "Programming")

            # Badges
            expect(json_response["badges_received"]).to be_an(Array)
            expect(json_response["badges_received"].size).to eq(1)
            badge_data = json_response["badges_received"].first
            expect(badge_data["project_title"]).to eq("AI Workshop")
            expect(badge_data["badge"]["name"]).to eq("AI Mentor")

            # Projects
            expect(json_response["project_members"]).to be_an(Array)
            expect(json_response["project_members"].size).to eq(1)
            project_data = json_response["project_members"].first["project"]
            expect(project_data["title"]).to eq("Web Development Course")
          end
        end
      end

      response "401", "unauthorized" do
        schema type: :object,
          properties: {
            error: {type: :string}
          }

        let!(:company_type) { create(:company_type) }
        let!(:company) { create(:company, :confirmed, company_type: company_type) }
        let!(:api_access) { create(:api_access, name: "Test API Access", token: "test-token-123") }
        let!(:company_api_access) { create(:company_api_access, api_access: api_access, company: company) }

        context "with invalid API token" do
          let(:token) { "invalid-token" }
          let!(:user) do
            user = create(:user, :confirmed)
            create(:user_company, user: user, company: company, status: :confirmed)
            user
          end
          let(:id) { user.id }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["error"]).to eq("Invalid API token")
          end
        end

        context "with valid token but unauthorized user access" do
          let(:token) { api_access.token }
          let!(:other_company) { create(:company, :confirmed, company_type: company_type) }
          let!(:unauthorized_user) do
            user = create(:user, :confirmed)
            create(:user_company, user: user, company: other_company, status: :confirmed)
            user
          end
          let(:id) { unauthorized_user.id }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["error"]).to eq("Unauthorized")
          end
        end
      end
    end
  end
end

