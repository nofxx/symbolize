# Todo: is this the best way for AR?
module Symbolize
  autoload :ActiveRecord, 'symbolize/active_record'
end

require 'symbolize/mongoid' if defined? Mongoid
require 'symbolize/railtie' if defined? Rails
