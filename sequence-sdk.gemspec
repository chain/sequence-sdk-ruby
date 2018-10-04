# frozen_string_literal: true

require_relative './lib/sequence/version'

Gem::Specification.new do |s|
  s.name = 'sequence-sdk'
  s.version = Sequence::VERSION
  s.authors = ['Chain Engineering']
  s.description = 'SDK for Sequence'
  s.summary = 'SDK for Sequence'
  s.licenses = ['Apache-2.0']
  s.homepage = 'https://github.com/sequence/sequence-sdk-ruby'
  s.required_ruby_version = '~> 2.3'

  s.files = ['README.md', 'LICENSE']
  s.files += Dir['lib/**/*.rb']

  s.require_path = 'lib'

  s.add_development_dependency 'bundler', '~> 1.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.5.0', '>= 3.5.0'
  s.add_development_dependency 'rspec-its', '~> 1.2.0'
  s.add_development_dependency 'simplecov', '~> 0.14.1'
  s.add_development_dependency 'yard', '~> 0.9.5', '>= 0.9.5'
end
