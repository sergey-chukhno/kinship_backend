class Logging < ApplicationRecord
  validates :ip_address, :request_path, :request_path_params, :request_code, :request_time, :user_agent, presence: true
end
