# frozen_string_literal: true

require "spec_helper"
require_relative "../../models/client"
require_relative "../../models/invoice"

describe Client do
  describe ".create" do
    it "creates a client" do
      expect(described_class.create(name: "John")).to be_instance_of(described_class)
      expect(described_class.create(name: "John").name).to eq("John")
    end
  end

  describe ".all" do
    it "returns all clients" do
      described_class.create(name: "John")
      described_class.create(name: "Jane")
      expect(described_class.all.count).to eq(2)
    end
  end

  describe ".find" do
    it "returns a client" do
      id = described_class.create(name: "John").id
      expect(described_class.find(id).name).to eq("John")
    end
  end

  describe "#update" do
    it "updates a client" do
      id = described_class.create(name: "John").id
      expect(described_class.find(id).update(name: "Jane").name).to eq("Jane")
    end
  end

  describe "#delete" do
    it "deletes a client" do
      id = described_class.create(name: "John").id
      expect(described_class.find(id).delete).to be_nil
    end
  end

  describe "#invoices" do
    it "returns all invoices for a client" do
      client1 = described_class.create(name: "John")
      client2 = described_class.create(name: "Jane")
      Invoice.create(client_id: client1.id, amount: 25, title: "Truck repair", description: "Repair of the truck")
      Invoice.create(client_id: client2.id, amount: 30, title: "New tires", description: "New tires for the car")
      Invoice.create(client_id: client1.id, amount: 150, title: "New tires", description: "New tires for the car")
      expect(client1.invoices.count).to eq(2)
      expect(client2.invoices.count).to eq(1)
    end
  end
end
