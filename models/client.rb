# frozen_string_literal: true

require_relative "../lib/passive_record/base"

# This class represents a client
class Client < PassiveRecord::Base
  attr_accessor :id, :name

  has_many :invoices

  def initialize(id, name)
    super(id)
    @name = name
  end
end
