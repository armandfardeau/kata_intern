# frozen_string_literal: true

module PassiveRecord
  # Add relation to base
  module Relationable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    # Holds relation methods
    module ClassMethods
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
          update!("#{relation.class.name.downcase}_id" => relation.id)
        end
      end
    end
  end
end
