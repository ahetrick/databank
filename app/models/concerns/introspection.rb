# frozen_string_literal: true

module Introspection

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def max_length(property)
      self.validators_on(property.to_sym).
          select { |v| v.kind_of?(ActiveModel::Validations::LengthValidator) }.
          first.options[:maximum]
    end
  end

end