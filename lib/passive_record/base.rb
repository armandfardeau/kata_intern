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

      def columns
        Database.schema[table_name.to_s]
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

      def where(**args, &)
        Relation.where(self, **args, &)
      end

      def find(id)
        object = Database.execute("select * from #{table_name} where id = ?", id).first
        new(*object)
      end

      def create(**args)
        inf = infer_relations(args)
        Database.execute(
          "insert into #{table_name} (#{inf.keys.join(', ')}) values (#{Array.new(inf.values.length,
                                                                                  '?').join(',')})", inf.values
        )
        find(Database.last_insert_row_id)
      end

      private

      def infer_relations(args)
        args.each_with_object({}) do |(key, value), hash|
          if columns.include?("#{key}_id")
            hash["#{key}_id".to_sym] = value.id
          else
            hash[key.to_sym] = value
          end
        end
      end
    end

    def table_name
      self.class.table_name
    end

    def columns
      self.class.columns
    end

    define_method(:initialize) do |*args|
      columns.each_with_index do |column, index|
        instance_variable_set("@#{column}", args[index])
        self.class.define_method(column) { instance_variable_get("@#{column}") }
        self.class.define_method("#{column}=") { |value| instance_variable_set("@#{column}", value) } unless column == "id"
      end
    end

    def update(**args)
      inf = self.class.send(:infer_relations, args)
      Database.execute("update #{table_name} set #{inf.keys.map do |k|
        "#{k} = '#{inf[k]}'"
      end.join(', ')} where id = #{id}")
      self.class.find(id)
    end

    def delete
      Database.execute("delete from #{table_name} where id = #{id}")

      nil
    end

    def to_s
      "#{super} #{instance_variables.map { |var| "#{var}: #{instance_variable_get(var)}" }.join(', ')}"
    end
  end
end
