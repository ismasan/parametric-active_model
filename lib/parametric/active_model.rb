require 'active_model'
require 'parametric/struct'
require "parametric/active_model/version"

module Parametric
  class ActiveModel
    include ::ActiveModel::Model
    extend ::ActiveModel::Naming
    include Parametric::Struct

    def self.name=(str)
      @name = str
    end

    def self.name
      super || @name
    end

    def self.model_name
      @model_name ||= ::ActiveModel::Name.new(self, nil, name.to_s.demodulize)
    end

    def self.parametric_build_class_for_child(key, child_schema)
      klass = Class.new(Parametric::ActiveModel) do
        schema child_schema
      end
      klass.name = key.to_s.singularize
      klass
    end

    def self.parametric_after_define_schema(schema)
      schema.fields.each do |key, field|
        define_method key do
          _graph[key]
        end
        if field.meta_data[:type] == :array
          define_method "#{key.to_s.pluralize}_attributes=".to_sym do |*args|
            # do nothing. We need this just so AM renders nested arrays in forms!
          end
        end
      end
    end

    def initialize(data = {})
      data = data.permit! if data.respond_to?(:permit!)
      super data.to_hash.deep_symbolize_keys
    end

    def options_for(field)
      self.class.schema.fields[field].meta_data.fetch(:options, [])
    end

    def errors
      @errors ||= (
        errors = ::ActiveModel::Errors.new(self)
        _errs = super
        _errs.each do |key, msgs|
          msgs.each do |msg|
            errors.add(key.split('.')[1].to_sym, :blank, message: msg) unless _is_array_error?(key)
          end
        end
        errors
      )
    end

    # AM stuff
    def read_attribute_for_validation(attr)
      send(attr)
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

    def self.lookup_ancestors
      [self]
    end

    private
    def _is_array_error?(key)
      !!(key =~ /\[\d+\]/)
    end
  end
end
