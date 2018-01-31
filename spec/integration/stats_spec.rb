describe 'stats' do
  it 'counts assets, accounts, and transactions' do
    # assume the ledger is not empty
    initial = chain.stats.get

    key = create_key
    account = chain.accounts.create(keys: [key], quorum: 1)
    asset = chain.assets.create(keys: [key], quorum: 1)

    chain.transactions.transact do |b|
      b.issue asset_id: asset.id, amount: 1, destination_account_id: account.id
    end

    got = chain.stats.get
    expect(got.asset_count).to eql(initial.asset_count + 1)
    expect(got.account_count).to eql(initial.account_count + 1)
    expect(got.tx_count).to eql(initial.tx_count + 1)
  end
end
