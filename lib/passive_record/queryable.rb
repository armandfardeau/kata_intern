# frozen_string_literal: true

require_relative "relation"

module PassiveRecord
  # Add query methods to base
  module Queryable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    # Holds Query methods
    module ClassMethods
      def scope(name, lambda, &block)
        define_singleton_method(name) do
          if block_given?
            block.call
          else
            lambda.call
          end
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
    end
  end
end
