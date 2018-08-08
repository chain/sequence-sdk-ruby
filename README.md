# Sequence Ruby SDK

## Usage

### Get the gem

The Ruby SDK is available
[via Rubygems](https://rubygems.org/gems/sequence-sdk).

Ruby >= 2.3 is required. See
[Ruby Maintenance Branches](https://www.ruby-lang.org/en/downloads/branches/)
for the language's schedule for security and bug fixes.

Add the following to your `Gemfile`:

```ruby
gem 'sequence-sdk', '~> 2.2'
```

### In your code

```ruby
require 'sequence'

ledger = Sequence::Client.new(
  ledger_name: 'ledger',
  credential: '...'
)
```

### Documentation

Comprehensive instructions and examples are available in the
[developer documentation](https://dashboard.seq.com/docs).
