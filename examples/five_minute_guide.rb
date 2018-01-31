# To run:
# ruby five_minute_guide.rb

require 'securerandom'
require ENV['CHAIN'] + '/sdk/ruby/lib/sequence'

ledger = Sequence::Client.new(
  ledger_name: 'CHANGEME',
  credential: 'CHANGEME',
)

uuid = SecureRandom.uuid
usd = "usd-#{uuid}"
alice = "alice-#{uuid}"
bob = "bob-#{uuid}"

key = ledger.keys.create
ledger.assets.create(alias: usd, keys: [key])
ledger.accounts.create(id: alice, keys: [key])
ledger.accounts.create(id: bob, keys: [key])

ledger.transactions.transact do |builder|
  builder.issue(
    asset_alias: usd,
    amount: 100,
    destination_account_id: alice,
  )
end

ledger.transactions.transact do |builder|
  builder.transfer(
    asset_alias: usd,
    amount: 50,
    source_account_id: alice,
    destination_account_id: bob,
  )
end

ledger.transactions.transact do |builder|
  builder.retire(
    asset_alias: usd,
    amount: 20,
    source_account_id: bob,
  )
end
