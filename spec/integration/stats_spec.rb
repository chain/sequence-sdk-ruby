# frozen_string_literal: true

describe 'stats' do
  it 'counts flavors, accounts, and transactions' do
    # assume the ledger is not empty
    initial = chain.stats.get

    key = create_key
    account = chain.accounts.create(key_ids: [key.id], quorum: 1)
    flavor = chain.flavors.create(key_ids: [key.id], quorum: 1)

    chain.transactions.transact do |b|
      b.issue flavor_id: flavor.id, amount: 1, destination_account_id: account.id
    end

    got = chain.stats.get
    expect(got.flavor_count).to eql(initial.flavor_count + 1)
    expect(got.account_count).to eql(initial.account_count + 1)
    expect(got.tx_count).to eql(initial.tx_count + 1)
    expect(got.ledger_type).to eql('dev')
  end
end
