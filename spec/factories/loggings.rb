FactoryBot.define do
  factory :logging do
    ip_address { "255.0.0.1" }
    request_path { "/projects" }
    request_path_params { "" }
    request_code { 404 }
    request_time { "2023-10-27 12:28:52" }
    user_agent { "MacOS" }
    user_id { 1 }
    user_email { "test@test.com" }
  end
end
