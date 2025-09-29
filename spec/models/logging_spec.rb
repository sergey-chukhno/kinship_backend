require "rails_helper"

RSpec.describe Logging, type: :model do
  it { should validate_presence_of(:ip_address) }
  it { should validate_presence_of(:request_path) }
  it { should validate_presence_of(:request_path_params) }
  it { should validate_presence_of(:request_code) }
  it { should validate_presence_of(:request_time) }
  it { should validate_presence_of(:user_agent) }
end
