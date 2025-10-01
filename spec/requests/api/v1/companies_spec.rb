require "swagger_helper"

RSpec.describe "API V1 Companies", type: :request do
  path "/api/v1/companies" do
    get "List companies" do
      tags "Companies (V1)"
      produces "application/json"
      description <<~DESC
        Returns a list of companies with optional filtering. 
        By default, only confirmed companies are returned unless admin parameter is set to true.
      DESC

      parameter name: :full_name,
        in: :query,
        type: :string,
        required: false,
        description: "Filter companies by full name (partial match)",
        example: "Tech Corp"

      parameter name: :admin,
        in: :query,
        type: :string,
        required: false,
        description: 'Set to "true" to include unconfirmed companies (admin access)',
        enum: ["true", "false"]

      response "200", "successful" do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: {type: :integer, description: "Company ID"},
              full_name: {type: :string, description: "Full company name"}
            }
          }

        let!(:company_type) { create(:company_type) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
        end

        context "when retrieving confirmed companies" do
          let!(:confirmed_company1) { create(:company, :confirmed, name: "Tech Solutions Inc", city: "Paris", zip_code: "75001", company_type: company_type) }
          let!(:confirmed_company2) { create(:company, :confirmed, name: "Digital Innovations Ltd", city: "Lyon", zip_code: "69001", company_type: company_type) }
          let!(:pending_company) { create(:company, :pending, name: "Pending Corp", city: "Marseille", zip_code: "13001", company_type: company_type) }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response.size).to eq(2)
            expect(json_response.map { |c| c["id"] }).to contain_exactly(confirmed_company1.id, confirmed_company2.id)
          end
        end

        context "when filtering by full_name" do
          let!(:company_type) { create(:company_type) }
          let!(:tech_company) { create(:company, :confirmed, name: "Tech Corp", city: "Paris", zip_code: "75001", company_type: company_type) }
          let!(:other_company) { create(:company, :confirmed, name: "Other Business", city: "Lyon", zip_code: "69001", company_type: company_type) }
          let(:full_name) { "Tech" }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response.size).to be >= 1
            expect(json_response.any? { |c| c["full_name"].include?("Tech") }).to be true
          end
        end

        context "when admin parameter is true" do
          let!(:company_type) { create(:company_type) }
          let!(:confirmed_company) { create(:company, :confirmed, name: "Confirmed Corp", city: "Paris", zip_code: "75001", company_type: company_type) }
          let!(:pending_company) { create(:company, :pending, name: "Pending Corp", city: "Lyon", zip_code: "69001", company_type: company_type) }
          let(:admin) { "true" }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response.size).to eq(2)
            company_ids = json_response.map { |c| c["id"] }
            expect(company_ids).to contain_exactly(confirmed_company.id, pending_company.id)
          end
        end
      end
    end
  end
end

