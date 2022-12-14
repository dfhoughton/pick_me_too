# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pick_me_too'

Gem::Specification.new do |s|
  s.name        = 'pick_me_too'
  s.version     = PickMeToo::VERSION
  s.summary     = 'Randomly select items from a list with specified frequencies'
  s.description = <<-DESC.strip.gsub(/\s+/, ' ')
    PickMeToo is a Ruby urn model. It allows you to generate
    an "urn" from which you can randomly sample items with
    specified frequencies. This facilitates modeling things that occur
    with known frequencies, like weather or wandering monsters.
  DESC
  s.authors     = ['David F. Houghton']
  s.email       = 'dfhoughton@gmail.com'
  s.homepage    =
    'https://github.com/dfhoughton/pick_me_too'
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.5.3'
  s.files                 = `git ls-files -z`.split("\x0")
  s.test_files            = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths         = ['lib']

  s.add_development_dependency 'bundler', '~> 1.7'
  s.add_development_dependency 'byebug', '~> 9.1', '>= 9.1.0'
  s.add_development_dependency 'json', '~> 2'
  s.add_development_dependency 'minitest', '~> 5'
  s.add_development_dependency 'rake', '~> 10.0'
end
