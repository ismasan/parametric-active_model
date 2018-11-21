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

    class_attribute :parametric_rails_form_setters
    self.parametric_rails_form_setters = {arrays: {}, objects: {}}

    def self.parametric_after_define_schema(schema)
      schema.fields.each do |key, field|
        define_method key do
          _graph[key]
        end
        if field.meta_data[:type] == :array
          collection_name = key.to_s.pluralize
          attr_method = "#{collection_name}_attributes".to_sym
          self.parametric_rails_form_setters[:arrays][attr_method] = collection_name

          define_method "#{attr_method}=".to_sym do |*args|
            # do nothing. We need this just so AM renders nested arrays in forms!
          end
        elsif field.meta_data[:type] == :array || field.meta_data[:schema].present?
          object_name = key.to_s.singularize
          attr_method = "#{object_name}_attributes".to_sym
          self.parametric_rails_form_setters[:objects][attr_method] = object_name

          define_method "#{attr_method}=".to_sym do |*args|
            # do nothing. We need this just so AM renders nested objects in forms!
          end
        end
      end
    end

    def initialize(data = {})
      data = data.permit! if data.respond_to?(:permit!)
      data = _map_rails_fields(data.to_hash.deep_symbolize_keys)
      super data
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

    def _map_rails_fields(hash)
      hash.each_with_object({}) do |(k, v), obj|
        if collection_name = parametric_rails_form_setters[:arrays][k]
          k = collection_name.to_sym
          v = v.values
        elsif object_name = parametric_rails_form_setters[:objects][k]
          k = object_name.to_sym
        end
        v = _map_rails_fields(v) if v.is_a?(Hash)
        obj[k] = v
      end
    end
  end
end
