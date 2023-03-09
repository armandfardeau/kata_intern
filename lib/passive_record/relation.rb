# frozen_string_literal: true

module PassiveRecord
  # This class represents a relation
  class Relation
    include Enumerable

    def self.where(klass, **args, &block)
      objects = if block_given?
                  Database.execute("select * from #{klass.table_name} where #{block.call}")
                else
                  Database.execute("select * from #{klass.table_name} where #{args.keys.map do |k|
                                                                                "#{k} = '#{args[k]}'"
                                                                              end.join(' and ')}")
                end
      new(klass, objects)
    end

    def or(query)
      self.class.new(@klass, (@objects + query.instance_variable_get(:@objects)).each_with_object({}) do |object, hash|
                               hash[object.id] = object
                             end.values)
    end

    def initialize(klass, objects)
      @klass = klass
      @objects = build(objects)
    end

    def build(objects)
      return [] if objects.empty?

      objects.map do |object|
        @klass.new(*object)
      rescue ArgumentError
        objects
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

    def respond_to_missing?(symbol, include_private = false)
      @klass.respond_to?(symbol) || super
    end

    def method_missing(symbol, *args)
      if @klass.respond_to?(symbol)
        actual = @klass.send(symbol, *args).map(&:id)
        current = @objects.select { |object| actual.include?(object.id) }

        self.class.new(@klass, current)
      else
        super
      end
    end
  end
end
