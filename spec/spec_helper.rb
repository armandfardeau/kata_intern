# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    Database.reset
  end
end
