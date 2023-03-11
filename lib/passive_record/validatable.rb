# frozen_string_literal: true

module PassiveRecord
  # Add validation methods to base
  module Validatable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    # Holds Validation methods
    module ClassMethods
      def validations
        @validations ||= []
      end

      def errors
        @errors ||= []
      end

      def instance_errors
        values = errors
        @errors = nil
        values
      end

      def instance_valid?(args)
        args = Struct.new(*args.keys).new(*args.values)
        errors = validations.reject do |validation|
          validation[:v].call(args)
        rescue NoMethodError
          false
        end

        return true if errors.empty?

        self.errors << errors.map do |error|
          error[:message].call
        end

        false
      end

      def validates(field, method)
        validations << Validatable.validations_method(self, field, method)
      end

      def validate(method, lambda, message = nil, &block)
        validations << { v: block_given? ? block : lambda, message: message ? -> { message } : -> { "#{method.capitalize} error" } }
      end
    end

    def self.validations_method(klass, field, method)
      {
        uniqueness: {
          v: ->(args) { !args.send(field).nil? && klass.where(field.to_sym => args.send(field)).to_a.empty? },
          message: -> { "#{field.capitalize} must be unique" }
        },
        presence: {
          v: ->(args) { !args.send(field).nil? },
          message: -> { "#{field.capitalize} is required" }
        }
      }.fetch(method, -> { true })
    end
  end
end
