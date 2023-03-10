# frozen_string_literal: true

require "spec_helper"
require_relative "../../models/client"
require_relative "../../models/invoice"

describe Invoice do
  describe ".create" do
    it "creates an invoice" do
      client = Client.create(name: "John")
      expect(described_class.create(client: client, amount: 25, title: "Truck repair",
                                    description: "Repair of the truck")).to be_instance_of(described_class)
      expect(described_class.create(client: client, amount: 25, title: "Truck repair",
                                    description: "Repair of the truck").amount).to eq(25)
    end
  end

  describe ".all" do
    it "returns all invoices" do
      client1 = Client.create(name: "John")
      client2 = Client.create(name: "Jane")
      described_class.create(client: client1, amount: 25, title: "Truck repair", description: "Repair of the truck")
      described_class.create(client: client2, amount: 30, title: "New tires", description: "New tires for the car")
      expect(described_class.all.count).to eq(2)
    end
  end

  describe ".find" do
    it "returns an invoice" do
      client = Client.create(name: "John")
      id = described_class.create(client: client, amount: 25, title: "Truck repair", description: "Repair of the truck").id
      expect(described_class.find(id).amount).to eq(25)
    end
  end

  describe "#update" do
    it "updates an invoice" do
      client1 = Client.create(name: "John")
      client2 = Client.create(name: "Jane")
      invoice = described_class.create(client: client1, amount: 25, title: "Truck repair", description: "Repair of the truck")
      updated = invoice.update(amount: 30, client: client2)
      expect(updated.amount).to eq(30)
      expect(updated.client.id).to eq(client2.id)
    end
  end

  describe "#delete" do
    it "deletes an invoice" do
      client = Client.create(name: "John")
      id = described_class.create(client: client, amount: 25, title: "Truck repair", description: "Repair of the truck").id
      expect(described_class.find(id).delete).to be_nil
    end
  end

  describe "#client" do
    it "returns the client for an invoice" do
      client1 = Client.create(name: "John")
      client2 = Client.create(name: "Jane")
      invoice1 = described_class.create(client: client1, amount: 25, title: "Truck repair",
                                        description: "Repair of the truck")
      invoice2 = described_class.create(client: client2, amount: 30, title: "New tires",
                                        description: "New tires for the car")
      invoice3 = described_class.create(client: client1, amount: 150, title: "New tires",
                                        description: "New tires for the car")
      expect(invoice1.client.name).to eq("John")
      expect(invoice2.client.name).to eq("Jane")
      expect(invoice3.client.name).to eq("John")
    end
  end

  describe "#client=" do
    it "updates the client for an invoice" do
      client1 = Client.create(name: "John")
      client2 = Client.create(name: "Jane")
      invoice1 = described_class.create(client: client1, amount: 25, title: "Truck repair",
                                        description: "Repair of the truck")
      invoice1.client = client2
      expect(invoice1.client.name).to eq("Jane")
    end
  end

  describe "#expensive" do
    it "returns all invoices with an amount greater than 100" do
      client1 = Client.create(name: "John")
      client2 = Client.create(name: "Jane")
      described_class.create(client: client1, amount: 25, title: "Truck repair", description: "Repair of the truck")
      described_class.create(client: client2, amount: 30, title: "New tires", description: "New tires for the car")
      described_class.create(client: client1, amount: 150, title: "New tires", description: "New tires for the car")
      expect(described_class.expensive.count).to eq(1)
    end
  end

  describe "when chaining scopes" do
    it "returns all invoices with an amount greater than 100 and a title of New tires" do
      client1 = Client.create(name: "John")
      client2 = Client.create(name: "Jane")
      described_class.create(client: client1, amount: 25, title: "Truck repair", description: "Repair of the truck")
      described_class.create(client: client2, amount: 30, title: "New tires", description: "New tires for the car")
      described_class.create(client: client1, amount: 150, title: "New tires", description: "New tires for the car")
      expect(described_class.expensive.where(title: "New tires").count).to eq(1)
    end
  end

  describe "#search" do
    it "returns all invoices with a title that includes the search term" do
      client1 = Client.create(name: "John")
      client2 = Client.create(name: "Jane")
      described_class.create(client: client1, amount: 25, title: "Truck repair", description: "Repair of the truck")
      described_class.create(client: client2, amount: 30, title: "New tires", description: "New tires for the car")
      described_class.create(client: client1, amount: 150, title: "New tires", description: "New tires for the car")
      expect(described_class.search("tires").count).to eq(2)
    end
  end
end
