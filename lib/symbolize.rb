module Symbolize
  autoload :ActiveRecord, 'symbolize/active_record'
  autoload :Mongoid, 'symbolize/mongoid'
end

require 'symbolize/railtie' if defined? Rails

