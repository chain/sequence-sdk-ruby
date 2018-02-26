describe 'transactions' do
  describe '#transfer' do
    context 'with filter' do
      it 'transfers flavors tagged with given filter' do
        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice, token_tags: { 'foo' => 'bar' })

        chain.transactions.transact do |b|
          b.transfer(
            amount: 100,
            flavor_id: usd.id,
            source_account_id: alice.id,
            destination_account_id: bob.id,
            filter: 'tags.foo=$1',
            filter_params: ['bar'],
          )
        end

        items = chain.tokens.list(
          filter: 'account_id = $1',
          filter_params: [alice.id],
        )
        expect(items.all.size).to eq 0
        items = chain.tokens.list(
          filter: 'account_id = $1',
          filter_params: [bob.id],
        )
        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
      end
    end
  end

  describe '#retire' do
    context 'with filter' do
      it 'retires flavors tagged with given filter' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice, token_tags: { 'foo' => 'bar' })
        issue_flavor(100, usd, alice)

        chain.transactions.transact do |b|
          b.retire(
            amount: 100,
            flavor_id: usd.id,
            source_account_id: alice.id,
            filter: 'tags.foo=$1',
            filter_params: ['bar'],
          )
        end

        items = chain.tokens.list(
          filter: 'account_id = $1',
          filter_params: [alice.id],
        )
        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
      end
    end
  end
end
