# frozen_string_literal: true

# This class represents an invoice
class Invoice < PassiveRecord::Base
  attr_accessor :id, :client_id, :amount, :title, :description

  belongs_to :client

  def initialize(id, client_id, amount, title, description)
    super(id)
    @client_id = client_id
    @amount = amount
    @title = title
    @description = description
  end

  scope :expensive, -> { where { "amount > 100" } }

  def self.search(term)
    where { "title LIKE '%#{term}%'" }.or(where { "description LIKE '%#{term}%'" })
  end
end
