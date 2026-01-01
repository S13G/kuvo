ENV["RAILS_ENV"] ||= "test"
ENV["JWT_SECRET_KEY_BASE"] ||= "test_secret_key"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def auth_headers(user)
      token = JwtService.generate_access_token(user.id)
      { "Authorization" => "Bearer #{token}" }
    end
  end
end
