lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'symbolize/version'

Gem::Specification.new do |s|
  s.name = "symbolize"
  s.version = Symbolize::VERSION

  s.authors     = ["Marcos Piccinini"]
  s.description = "ActiveRecord/Mongoid enums with i18n"
  s.homepage    = "http://github.com/nofxx/symbolize"
  s.summary     = "Object enums with i18n in AR or Mongoid"
  s.email       = "x@nofxx.com"
  s.license     = 'MIT'

  s.files = Dir.glob("{lib,spec}/**/*") + %w(README.md Rakefile)
  s.require_path = "lib"

  s.rubygems_version = "1.3.7"
  s.add_dependency 'activesupport', '>= 3.2', '< 5'
  s.add_dependency 'activemodel', '>= 3.2', '< 5'
end
