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

      def validates(field, *methods)
        methods.each do |method|
          validations << Validatable.validations_method(self, field, method)
        end
      end

      def validate(method, lambda, message = nil, &block)
        validations << { v: block_given? ? block : lambda, message: message ? -> { message } : -> { "#{method.capitalize} error" } }
      end
    end

    def valid?
      errors = self.class.validations.reject do |validation|
        validation[:v].call(self)
      rescue NoMethodError
        false
      end

      return true if errors.empty?

      self.errors << errors.map do |error|
        error[:message].call
      end

      false
    end

    def errors
      @errors ||= []
    end

    def self.validations_method(klass, field, method)
      {
        uniqueness: {
          v: ->(object) { !object.send(field).nil? && klass.where(field.to_sym => object.send(field)).to_a.empty? },
          message: -> { "#{field.capitalize} must be unique" }
        },
        presence: {
          v: ->(object) { !object.send(field).nil? && object.send(field) != "" },
          message: -> { "#{field.capitalize} is required" }
        }
      }.fetch(method, -> { true })
    end
  end
end
