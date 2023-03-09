# frozen_string_literal: true

require_relative "../../db/database"
require_relative "relation"
require "byebug"

module PassiveRecord
  # This class represents a base class for all models
  class Base
    class << self
      def table_name
        "#{name.downcase}s"
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

      # rubocop:disable Naming/PredicateName
      def has_many(model)
        define_method(model) do
          Relation.where(Object.const_get(model.capitalize[0..-2]), "#{self.class.name.downcase}_id" => id)
        end
      end
      # rubocop:enable Naming/PredicateName

      def belongs_to(model)
        define_method(model) do
          Object.const_get(model.capitalize).find(send("#{model}_id"))
        end

        define_method("#{model}=".to_sym) do |relation|
          update("#{relation.class.name.downcase}_id" => relation.id)
          self.client_id = relation.id
        end
      end

      def all
        objects = Database.execute("select * from #{table_name}")
        Relation.new(self, objects)
      end

      def where(**args, &block)
        Relation.where(self, **args, &block)
      end

      def find(id)
        object = Database.execute("select * from #{table_name} where id = ?", id).first
        new(*object)
      end

      def create(**args)
        Database.execute(
          "insert into #{table_name} (#{args.keys.join(', ')}) values (#{Array.new(args.values.length,
                                                                                   '?').join(',')})", args.values
        )
        find(Database.last_insert_row_id)
      end
    end

    def initialize(id)
      @id = id
    end

    def update(**args)
      Database.execute("update #{self.class.table_name} set #{args.keys.map do |k|
        "#{k} = '#{args[k]}'"
      end.join(', ')} where id = #{id}")
      self.class.find(id)
    end

    def delete
      Database.execute("delete from #{self.class.table_name} where id = #{id}")

      nil
    end

    def to_s
      "#{super} #{instance_variables.map { |var| "#{var}: #{instance_variable_get(var)}" }.join(', ')}"
    end
  end
end
