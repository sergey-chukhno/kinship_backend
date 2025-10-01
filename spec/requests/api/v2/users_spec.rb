require "swagger_helper"

RSpec.describe "API V2 Users", type: :request do
  path "/api/v2/users" do
    get "List users with pagination" do
      tags "Users (V2)"
      produces "application/json"
      security [ApiKeyAuth: []]
      description <<~DESC
        Returns a paginated list of users accessible to the API token holder.
        Only users who are confirmed members of companies associated with the API access token are returned.
        Supports search by first name or last name.
      DESC

      parameter name: :token,
        in: :query,
        type: :string,
        required: true,
        description: "API access token for authentication",
        example: "your-api-token-here"

      parameter name: :query,
        in: :query,
        type: :string,
        required: false,
        description: "Search query for filtering users by first name or last name",
        example: "John Doe"

      parameter name: :page,
        in: :query,
        type: :integer,
        required: false,
        description: "Page number for pagination",
        default: 1

      response "200", "successful" do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: {type: :integer, description: "User ID"},
                  first_name: {type: :string, description: "User's first name"},
                  last_name: {type: :string, description: "User's last name"},
                  email: {type: :string, format: :email, description: "User's email address"},
                  role: {
                    type: :string,
                    description: "User's role in the system",
                    enum: ["teacher", "tutor", "voluntary", "children"]
                  }
                }
              }
            },
            meta: {
              type: :object,
              properties: {
                count: {type: :integer, description: "Total number of users"},
                pages: {type: :integer, description: "Total number of pages"},
                prev: {type: :integer, nullable: true, description: "Previous page number"},
                next: {type: :integer, nullable: true, description: "Next page number"},
                page: {type: :integer, description: "Current page number"}
              }
            }
          }

        let!(:company_type) { create(:company_type) }
        let!(:company) { create(:company, :confirmed, company_type: company_type) }
        let!(:api_access) { create(:api_access, name: "Test API Access", token: "test-token-123") }
        let!(:company_api_access) { create(:company_api_access, api_access: api_access, company: company) }

        context "with valid API token" do
          let(:token) { api_access.token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data).to have_key("data")
            expect(data).to have_key("meta")
          end

          context "when users exist" do
            let!(:user1) do
              user = create(:user, :confirmed, first_name: "John", last_name: "Doe", email: "john.doe@ac-nantes.fr", role: :teacher)
              create(:user_company, user: user, company: company, status: :confirmed)
              user
            end

            let!(:user2) do
              user = create(:user, :confirmed, first_name: "Jane", last_name: "Smith", email: "jane.smith@example.com", role: :voluntary)
              create(:user_company, user: user, company: company, status: :confirmed)
              user
            end

            run_test! do |response|
              json_response = JSON.parse(response.body)

              expect(json_response["data"]).to be_an(Array)
              expect(json_response["data"].size).to eq(2)

              expect(json_response["meta"]).to include("count", "pages", "page")
              expect(json_response["meta"]["count"]).to eq(2)
              expect(json_response["meta"]["page"]).to eq(1)

              user_data = json_response["data"]
              expect(user_data.map { |u| u["id"] }).to contain_exactly(user1.id, user2.id)
            end
          end

          context "when searching by query" do
            let!(:john_user) do
              user = create(:user, :confirmed, first_name: "John", last_name: "Doe", email: "john@example.com")
              create(:user_company, user: user, company: company, status: :confirmed)
              user
            end

            let!(:jane_user) do
              user = create(:user, :confirmed, first_name: "Jane", last_name: "Smith", email: "jane@example.com")
              create(:user_company, user: user, company: company, status: :confirmed)
              user
            end

            let(:query) { "John" }

            run_test! do |response|
              json_response = JSON.parse(response.body)

              expect(json_response["data"].size).to be >= 1
              expect(json_response["data"].any? { |u| u["first_name"] == "John" }).to be true
            end
          end
        end
      end

      response "401", "unauthorized" do
        schema type: :object,
          properties: {
            error: {type: :string}
          }

        context "with invalid API token" do
          let(:token) { "invalid-token" }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["error"]).to eq("Invalid API token")
          end
        end

        context "with missing API token" do
          let(:token) { nil }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response["error"]).to eq("Invalid API token")
          end
        end
      end
    end
  end
end

