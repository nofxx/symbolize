require 'active_support/concern'
require 'active_support/core_ext/hash/keys'

module Symbolize
  module ActiveRecord
    extend ActiveSupport::Concern

    included do
      # Returns an array of all the attributes that have been specified for symbolization
      class_attribute :symbolized_attributes, :instance_reader => false
      self.symbolized_attributes = []
    end

    # Symbolize ActiveRecord attributes. Add
    #   symbolize :attr_name
    # to your model class, to make an attribute return symbols instead of
    # string values. Setting such an attribute will accept symbols as well
    # as strings. In the database, the symbolized attribute should have
    # the column-type :string.
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     symbolize :gender, :in => [:female, :male]
    #     symbolize :so, :in => {
    #       :linux   => "Linux",
    #       :mac     => "Mac OS X"
    #     }
    #     symbolize :gui, , :in => [:gnome, :kde, :xfce], :allow_blank => true
    #     symbolize :browser, :in => [:firefox, :opera], :i18n => false
    #   end
    #
    # It will automattically lookup for i18n:
    #
    # activerecord:
    #   symbolizes:
    #     user:
    #       gender:
    #         female: Girl
    #         male: Boy
    #
    # You can skip i18n lookup with :i18n => false
    #   symbolize :gender, :in => [:female, :male], :i18n => false
    #
    # Its possible to use boolean fields also.
    #   symbolize :switch, :in => [true, false]
    #
    #   ...
    #     switch:
    #       "true": On
    #       "false": Off
    #       "nil": Unknown
    #
    module ClassMethods
      # Specifies that values of the given attributes should be returned
      # as symbols. The table column should be created of type string.

      def symbolize(*attr_names)
        configuration = attr_names.extract_options!
        configuration.assert_valid_keys(:in, :within, :i18n, :scopes, :methods, :case_insensitive_methods, :capitalize, :validate, :default, :allow_blank, :allow_nil)

        enum                     = configuration[:in] || configuration[:within]
        i18n                     = configuration[:i18n]
        i18n                     = enum && !enum.is_a?(Hash) if i18n.nil?
        scopes                   = configuration[:scopes]
        methods                  = configuration[:methods]
        case_insensitive_methods = configuration[:case_insensitive_methods]
        capitalize               = configuration[:capitalize]
        validation               = configuration[:validate] != false
        default_option           = configuration[:default]

        attr_names.each do |attr_name|
          attr_name_str = attr_name.to_s

          if enum
            enum_hash = \
            if enum.is_a?(Hash)
              enum
            else
              enum.each_with_object({}) do |e, a|
                a.store(e.respond_to?(:to_sym) ? e.to_sym : e,
                        capitalize ? e.to_s.capitalize : e.to_s)
              end
            end

            values_name = attr_name_str + '_values'
            values_const_name = values_name.upcase

            # Get the values of :in
            const_set values_const_name, enum_hash unless const_defined? values_const_name

            [
              'get_' + values_name,
              attr_name_str + '_enum',
            ].each do |enum_method_name|

              define_singleton_method(enum_method_name) do
                if i18n
                  enum_hash.each_key.map do |symbol|
                    [i18n_translation_for(attr_name_str, symbol), symbol]
                  end
                else
                  enum_hash.map(&:reverse)
                end
              end
            end

            if methods
              enum_hash.each_key do |key|
                # It's a good idea to test for name collisions here and raise exceptions.
                # However, the existing software with this kind of errors will start crashing,
                # so I'd postpone this improvement until the next major version
                # this way it will not affect those people who use ~> in their Gemfiles

                # raise ArgumentError, "re-defined #{key}? method of #{self.name} class due to 'symbolize'" if method_defined?("#{key}?")

                define_method("#{key}?") do
                  send(attr_name_str) == key.to_sym
                end
              end
            end

            if case_insensitive_methods
              enum_hash.each_key do |key|
                # It's a good idea to test for name collisions here and raise exceptions.
                # However, the existing software with this kind of errors will start crashing,
                # so I'd postpone this improvement until the next major version
                # this way it will not affect those people who use ~> in their Gemfiles

                # raise ArgumentError, "re-defined #{key.downcase}? method of #{self.name} class due to 'symbolize'" if method_defined?("#{key.downcase}?")
                # raise ArgumentError, "re-defined #{key.upcase}? method of #{self.name} class due to 'symbolize'" if method_defined?("#{key.upcase}?")

                define_method("#{key.downcase}?") do
                  send(attr_name_str) == key.to_sym
                end

                alias_method "#{key.upcase}?", "#{key.downcase}?"
              end
            end

            if scopes
              if scopes == :shallow
                enum_hash.each_key do |name|
                  next unless name.respond_to?(:to_sym)

                  scope name, -> { where(attr_name_str => name) }
                  # Figure out if this as another option, or default...
                  # scope "not_#{name}", -> { where.not(attr_name_str => name)
                end
              else
                scope attr_name_str, ->(val) { where(attr_name_str => val) }
              end
            end

            if validation
              validates(*attr_names, configuration.slice(:allow_nil, :allow_blank).merge(:inclusion => { :in => enum_hash.keys }))
            end
          end

          define_method(attr_name_str) { read_and_symbolize_attribute(attr_name_str) || default_option }
          define_method(attr_name_str + '=') { |value| write_symbolized_attribute(attr_name_str, value) }

          if default_option
            before_save { self[attr_name_str] ||= default_option }
          else
            define_method(attr_name_str) { read_and_symbolize_attribute(attr_name_str) }
          end

          define_method(attr_name_str + '_text') do
            if i18n
              read_i18n_attribute(attr_name_str)
            else
              attr_value = send(attr_name_str)
              if enum
                enum_hash[attr_value]
              else
                attr_value.to_s
              end
            end
          end
        end

        # merge new symbolized attribute and create a new array to ensure that each class in inheritance hierarchy
        # has its own array of symbolized attributes
        self.symbolized_attributes += attr_names.map(&:to_s)
      end

      # Hook used by Rails to do extra stuff to attributes when they are initialized.
      def initialize_attributes(*args)
        super.tap do |attributes|
          # Make sure any default values read from the database are symbolized
          symbolized_attributes.each do |attr_name|
            attributes[attr_name] = symbolize_attribute(attributes[attr_name])
          end
        end
      end

      # String becomes symbol, booleans string and nil nil.
      def symbolize_attribute(value)
        case value
        when String
          value.presence.try(:to_sym)
        when Symbol, TrueClass, FalseClass, Numeric
          value
        else
          nil
        end
      end

      def i18n_translation_for(attr_name, attr_value)
        I18n.translate("activerecord.symbolizes.#{model_name.to_s.underscore}.#{attr_name}.#{attr_value}")
      end
    end

    # String becomes symbol, booleans string and nil nil.
    def symbolize_attribute(value)
      self.class.symbolize_attribute(value)
    end

    # Return an attribute's value as a symbol or nil
    def read_and_symbolize_attribute(attr_name)
      symbolize_attribute(read_attribute(attr_name))
    end

    # Return an attribute's i18n
    def read_i18n_attribute(attr_name)
      unless (t = self.class.i18n_translation_for(attr_name, read_attribute(attr_name))).is_a?(Hash)
        t
      end
    end

    # Write a symbolized value. Watch out for booleans.
    def write_symbolized_attribute(attr_name, value)
      write_attribute(attr_name, symbolize_attribute(value))
    end
  end
end
