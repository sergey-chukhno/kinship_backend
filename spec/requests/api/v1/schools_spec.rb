require "swagger_helper"

RSpec.describe "API V1 Schools", type: :request do
  path "/api/v1/schools" do
    get "List schools" do
      tags "Schools (V1)"
      produces "application/json"
      description <<~DESC
        Returns a list of schools with optional filtering by name, zip code, and school type.
        By default, only confirmed schools are returned unless admin parameter is set to true.
        Results are limited to 20 records.
      DESC

      parameter name: :name,
        in: :query,
        type: :string,
        required: false,
        description: "Filter schools by name (partial match)",
        example: "Lycée"

      parameter name: :zip_code,
        in: :query,
        type: :string,
        required: false,
        description: "Filter schools by zip code",
        example: "75001"

      parameter name: :school_type,
        in: :query,
        type: :string,
        required: false,
        description: "Filter schools by type",
        example: "lycee"

      parameter name: :admin,
        in: :query,
        type: :string,
        required: false,
        description: 'Set to "true" to include unconfirmed schools (admin access)',
        enum: ["true", "false"]

      parameter name: :q,
        in: :query,
        required: false,
        schema: {type: :object},
        description: "Advanced search query object (Ransack format)",
        style: :deepObject,
        explode: true

      response "200", "successful" do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: {type: :integer, description: "School ID"},
              full_name: {type: :string, description: "Full school name"},
              zip_code: {type: :string, description: "School zip code"},
              school_type: {type: :string, description: "Type of school (e.g., lycee, college)"}
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
        end

        context "when retrieving confirmed schools" do
          let!(:confirmed_school1) { create(:school, name: "Lycée Victor Hugo", city: "Paris", zip_code: "75001", school_type: :lycee, status: :confirmed) }
          let!(:confirmed_school2) { create(:school, name: "Collège Montaigne", city: "Paris", zip_code: "75006", school_type: :college, status: :confirmed) }
          let!(:pending_school) { create(:school, name: "Pending School", city: "Lyon", zip_code: "69001", school_type: :primaire, status: :pending) }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response.size).to eq(2)
            school_ids = json_response.map { |s| s["id"] }
            expect(school_ids).to contain_exactly(confirmed_school1.id, confirmed_school2.id)
          end
        end

        context "when filtering by name" do
          let!(:lycee_school) { create(:school, name: "Lycée des Arts", city: "Paris", zip_code: "75001", school_type: :lycee, status: :confirmed) }
          let!(:college_school) { create(:school, name: "Collège Science", city: "Lyon", zip_code: "69001", school_type: :college, status: :confirmed) }
          let(:name) { "Lycée" }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response.size).to be >= 1
            expect(json_response.any? { |s| s["full_name"].include?("Lycée") }).to be true
          end
        end

        context "when filtering by zip_code" do
          let!(:paris_school) { create(:school, name: "École Paris", city: "Paris", zip_code: "75001", school_type: :primaire, status: :confirmed) }
          let!(:lyon_school) { create(:school, name: "École Lyon", city: "Lyon", zip_code: "69001", school_type: :primaire, status: :confirmed) }
          let(:zip_code) { "75001" }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response.size).to eq(1)
            expect(json_response.first["zip_code"]).to eq("75001")
          end
        end

        context "when filtering by school_type" do
          let!(:lycee_school) { create(:school, name: "Lycée Test", city: "Paris", zip_code: "75001", school_type: :lycee, status: :confirmed) }
          let!(:college_school) { create(:school, name: "Collège Test", city: "Lyon", zip_code: "69001", school_type: :college, status: :confirmed) }
          let(:school_type) { "lycee" }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response.size).to eq(1)
            expect(json_response.first["school_type"]).to eq("lycee")
          end
        end

        context "when admin parameter is true" do
          let!(:confirmed_school) { create(:school, name: "Confirmed School", city: "Paris", zip_code: "75001", school_type: :lycee, status: :confirmed) }
          let!(:pending_school) { create(:school, name: "Pending School", city: "Lyon", zip_code: "69001", school_type: :college, status: :pending) }
          let(:admin) { "true" }

          run_test! do |response|
            json_response = JSON.parse(response.body)
            expect(json_response.size).to eq(2)
            school_ids = json_response.map { |s| s["id"] }
            expect(school_ids).to contain_exactly(confirmed_school.id, pending_school.id)
          end
        end
      end
    end
  end
end
