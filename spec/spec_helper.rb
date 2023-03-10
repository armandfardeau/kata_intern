# frozen_string_literal: true

require "simplecov"
require "simplecov-cobertura"

SimpleCov.start

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter if ENV["CI"]

RSpec.configure do |config|
  config.before do
    Database.reset
  end
end
