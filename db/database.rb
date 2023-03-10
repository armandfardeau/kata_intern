# frozen_string_literal: true

require "sqlite3"
require "fileutils"
require "singleton"

# This class is a wrapper around the SQLite3 database
class Database
  DB_FILE = "test.db"
  include Singleton

  def self.execute(query, values = nil)
    if values
      puts "Executing query: #{query} with values: #{values}" if ENV["DEBUG"]
      db.execute(query, values)
    else
      puts "Executing query: #{query}" if ENV["DEBUG"]
      db.execute(query)
    end
  end

  def self.schema
    return @schema if @schema

    tables = Database.execute("select * from sqlite_master").map { |row| row[2] }
    @schema = tables.each_with_object({}) do |table, hash|
      hash[table] = Database.execute("pragma table_info(#{table})").map { |row| row[1] }
    end
  end

  def self.last_insert_row_id
    db.last_insert_row_id
  end

  def self.reset
    @db = nil
  end

  def self.db
    return @db if @db

    FileUtils.rm_f(DB_FILE)
    db = SQLite3::Database.new(DB_FILE)

    Dir["db/migrations/*.sql3"].each do |file|
      db.execute(File.read(file))
    end

    @db = db
  end
end
