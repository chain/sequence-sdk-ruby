require_relative './lib/sequence/version'

Gem::Specification.new do |s|
  s.name = 'sequence-sdk'
  s.version = Sequence::VERSION
  s.authors = ['Chain Engineering']
  s.description = 'SDK for Sequence'
  s.summary = 'SDK for Sequence'
  s.licenses = ['Apache-2.0']
  s.homepage = 'https://github.com/sequence/sequence-sdk-ruby'
  s.required_ruby_version = '~> 2.2'

  s.files = ['README.md', 'LICENSE']
  s.files += Dir['lib/**/*.rb']

  s.require_path = 'lib'
end
