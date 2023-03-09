require "sqlite3"
require 'fileutils'
require "singleton"
require 'byebug'

DB_FILE = "test.db"

class Database
  include Singleton

  def self.execute(query, values = nil)
    if values
      puts "Executing query: #{query} with values: #{values}"
      db.execute(query, values)
    else
      puts "Executing query: #{query}"
      db.execute(query)
    end
  end

  def self.last_insert_row_id
    db.last_insert_row_id
  end

  def self.db
    return @db if @db
    FileUtils.rm_f(DB_FILE) if File.exist?(DB_FILE)
    db = SQLite3::Database.new(DB_FILE)

    # Create a table
    db.execute <<-SQL
      create table clients (
        id integer primary key,
        name varchar(30)
      );
    SQL

    db.execute <<-SQL
      create table invoices (
        id integer primary key,
        client_id integer not null,
        amount integer not null,
        title varchar(30) not null,
        description varchar(100),
        foreign key (client_id) references clients(id)
      );
    SQL

    @db = db
  end
end

class Relation
  include Enumerable

  def self.where(klass, **args, &block)
    if block_given?
      objects = Database.execute("select * from #{klass.table_name} where #{block.call}")
    else
      objects = Database.execute("select * from #{klass.table_name} where #{args.keys.map { |k| "#{k} = '#{args[k]}'" }.join(" and ")}")
    end
    new(klass, objects)
  end

  def initialize(klass, objects)
    @klass = klass
    @objects = build(objects)
  end

  def build(objects)
    return [] if objects.empty?
    objects.map do |object|
      begin
        @klass.new(*object)
      rescue ArgumentError
        objects
      end
    end
  end

  def each(&block)
    if block_given?
      @objects.each { |object| block.call(object) }
    else
      to_enum(:each)
    end
  end

  def to_s
    @objects.map(&:to_s).join(", ")
  end

  def method_missing(symbol, *args)
    if @klass.respond_to?(symbol)
      actual = @klass.send(symbol, *args).map(&:id)
      current = @objects.select { |object| actual.include?(object.id) }

      Relation.new(@klass, current)
    else
      super
    end
  end
end

class Base
  class << self
    def table_name
      self.name.downcase + "s"
    end

    def scope(name, lambda, &block)
      define_singleton_method(name) do
        if block_given?
          block.call
        else
          lambda.call
        end
      end
    end

    def has_many(i)
      define_method(i) do
        Relation.where(Object.const_get(i.capitalize[0..-2]), "#{self.class.table_name[0..-2]}_id" => self.id)
      end
    end

    def belongs_to(i)
      define_method(i) do
        Object.const_get(i.capitalize).find(self.send("#{i}_id"))
      end
    end

    def all
      objects = Database.execute("select * from #{table_name}")
      objects.map { |object| new(*object) }
    end

    def where(**args, &block)
      Relation.where(self, **args, &block)
    end

    def find(id)
      objects = Database.execute("select * from #{table_name} where id = ?", id)
      new(*objects.first)
    end

    def create(**args)
      Database.execute("insert into #{table_name} (#{args.keys.join(", ")}) values (#{Array.new(args.values.length, "?").join(",")})", args.values)
      self.find(Database.last_insert_row_id)
    end
  end

  def update(**args)
    Database.execute("update #{self.class.table_name} set #{args.keys.map { |k| "#{k} = '#{args[k]}'" }.join(", ")} where id = #{self.id}")
    self.class.find(self.id)
  end

  def delete
    Database.execute("delete from #{self.class.table_name} where id = #{self.id}")
  end

  def to_s
    super + " " + instance_variables.map { |var| "#{var}: #{self.instance_variable_get(var)}" }.join(", ")
  end
end

class Client < Base
  attr_accessor :id, :name
  has_many :invoices

  def initialize(id, name)
    @id = id
    @name = name
  end
end

class Invoice < Base
  attr_accessor :id, :client_id, :amount, :title, :description
  belongs_to :client

  def initialize(id, client_id, amount, title, description)
    @id = id
    @client_id = client_id
    @amount = amount
    @title = title
    @description = description
  end

  scope :expensive, -> { where { "amount > 100" } }
end

# Insert some records
client_1 = Client.create(name: "John")
client_2 = Client.create(name: "Jane")

Invoice.create(client_id: client_1.id, amount: 25, title: "Truck repair", description: "Repair of the truck")
Invoice.create(client_id: client_2.id, amount: 30, title: "New tires", description: "New tires for the car")
Invoice.create(client_id: client_1.id, amount: 150, title: "New tires", description: "New tires for the car")

puts Client.all
puts Invoice.all

puts Invoice.where { "amount < 50" }
puts Invoice.where { "description like '%tires%'" }

Invoice.create(client_id: client_1.id, amount: 200, title: "New tires", description: "New tires for the car")

client_2.delete

puts client_1.update(name: "John Doe")
puts client_1.inspect
puts client_1.invoices
puts client_1.invoices.first.client
Invoice.expensive
puts client_1.invoices.expensive