# frozen_string_literal: true

require_relative "../../db/database"
require_relative "relationable"
require_relative "queryable"
require_relative "validatable"
require "byebug"

module PassiveRecord
  # This class represents a base class for all models
  class Base
    include PassiveRecord::Relationable
    include PassiveRecord::Queryable
    include PassiveRecord::Validatable

    class << self
      def table_name
        "#{name.downcase}s"
      end

      def columns
        Database.schema[table_name.to_s]
      end

      def create(**args)
        inf = infer_relations(args)

        raise ArgumentError, instance_errors.join(", ") unless instance_valid?(args)

        instance = new
        inf.each { |k, v| instance.send("#{k}=".to_sym, v) }

        yield if block_given?

        instance.instance_variable_set(:@id, Database.last_insert_row_id)
        instance
      end

      def create!(**args)
        inf = infer_relations(args)

        create(**args) do
          Database.execute(
            "insert into #{table_name} (#{inf.keys.join(', ')}) values (#{Array.new(inf.values.length,
                                                                                    '?').join(',')})", inf.values
          )
        end
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
      args = Array.new(columns.length) if args.empty?

      columns.each_with_index do |column, index|
        instance_variable_set("@#{column}", args[index])
        self.class.define_method(column) { instance_variable_get("@#{column}") }
        self.class.define_method("#{column}=") { |value| instance_variable_set("@#{column}", value) } unless column == "id"
      end
    end

    def update(**args)
      inf = self.class.send(:infer_relations, args)

      values = instance_variables.each_with_object({}) do |instance_variable, hash|
        hash[instance_variable.to_s.sub("@", "").to_sym] = instance_variable_get(instance_variable)
      end.merge(inf)

      raise ArgumentError, self.class.instance_errors.join(", ") unless self.class.instance_valid?(values)

      yield if block_given?

      values.tap { |v| v.delete(:id) }.each { |k, v| send("#{k}=".to_sym, v) }

      self
    end

    def update!(**args)
      inf = self.class.send(:infer_relations, args)
      update(**args) do
        Database.execute("update #{table_name} set #{inf.keys.map do |k|
          "#{k} = '#{inf[k]}'"
        end.join(', ')} where id = #{id}")
      end
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
