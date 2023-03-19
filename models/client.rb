# frozen_string_literal: true

require_relative "../lib/passive_record/base"

# This class represents a client
class Client < PassiveRecord::Base
  has_many :invoices
  validates :name, :uniqueness, :presence
end
