lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'symbolize/version'

Gem::Specification.new do |s|
  s.name        = 'symbolize'
  s.version     = Symbolize::VERSION

  s.authors     = ['Marcos Piccinini']
  s.description = 'ActiveRecord/Mongoid enums with i18n'
  s.homepage    = 'http://github.com/nofxx/symbolize'
  s.summary     = 'Object enums with i18n in AR or Mongoid'
  s.email       = 'x@nofxx.com'
  s.license     = 'MIT'

  s.files = Dir.glob('{lib,spec}/**/*') + %w(README.md Rakefile)
  s.require_path = 'lib'

  s.add_dependency 'i18n'
  s.add_dependency 'activemodel', '>= 3.2'
  s.add_dependency 'activesupport', '>= 3.2'

  # s.add_development_dependency 'pg'
  # s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'mongoid'
  s.add_development_dependency 'activerecord'
  # s.add_development_dependency 'coveralls'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 3'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'guard-rubocop'

end
