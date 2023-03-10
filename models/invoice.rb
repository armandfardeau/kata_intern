# frozen_string_literal: true

# This class represents an invoice
class Invoice < PassiveRecord::Base
  belongs_to :client
  scope :expensive, -> { where { "amount > 100" } }

  def self.search(term)
    where { "title LIKE '%#{term}%'" }.or(where { "description LIKE '%#{term}%'" })
  end
end
