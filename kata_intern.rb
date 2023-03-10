# frozen_string_literal: true

require_relative "models/client"
require_relative "models/invoice"
require "byebug"

Database.reset

# Insert some records
client1 = Client.create(name: "John")
client2 = Client.create(name: "Jane")

Invoice.create(client: client1, amount: 25, title: "Truck repair", description: "Repair of the truck")
Invoice.create(client: client2, amount: 30, title: "New tires", description: "New tires for the car")
Invoice.create(client: client1, amount: 150, title: "New tires", description: "New tires for the car")

puts Client.all
puts Invoice.all

puts(Invoice.where { "amount < 50" })
puts(Invoice.where { "description like '%tires%'" })

Invoice.create(client: client1, amount: 200, title: "New tires", description: "New tires for the car")

client2.delete

puts client1.update(name: "John Doe")
puts client1.inspect
puts client1.invoices
puts client1.invoices.first.client
Invoice.expensive
puts client1.invoices.expensive
