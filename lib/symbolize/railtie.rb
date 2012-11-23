# Rails 3 initialization
module Symbolize
  require 'rails'
  class Railtie < Rails::Railtie
    initializer 'symbolize.insert_into_active_record' do
      ActiveSupport.on_load :active_record do
        ::ActiveRecord::Base.send :include, Symbolize::ActiveRecord
      end
    end
  end
end
