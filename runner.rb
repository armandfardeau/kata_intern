# frozen_string_literal: true

require 'rspec'
require './kata_intern'

describe Client do
  it 'should return the correct value' do
    client = Client.create(name: 'John')
    expect(client.name).to eq("John")
  end
end
