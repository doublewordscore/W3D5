require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      :foreign_key => "#{name}_id".to_sym,
      :primary_key => :id,
      :class_name => name.to_s.camelcase,
    }


    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end

end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      :foreign_key => "#{self_class_name}_id".downcase.to_sym,
      :primary_key => :id,
      :class_name => name.to_s.camelcase.singularize
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

module Associatable
  # Phase IIIb



  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      foreign_key_val = self.send(options.foreign_key)
      target_model_class = options.model_class.where(options.primary_key == foreign_key_val).first
    end

  end

  def has_many(name, options = {})

  end

  def self.assoc_options

  end


end

class SQLObject
  extend Associatable
end
