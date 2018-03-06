describe 'transactions' do
  describe '#issue' do
    context 'with tags' do
      it 'adds tags to issue action' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        eur = create_flavor('eur')
        action_tags = create_refdata('acting_party')
        issue_flavor(50, eur, alice)

        chain.transactions.transact do |b|
          b.issue(
            amount: 100,
            flavor_id: usd.id,
            destination_account_id: alice.id,
            action_tags: action_tags,
          )
        end

        items = chain.actions.list(
          filter: 'tags.acting_party=$1',
          filter_params: [action_tags['acting_party']],
        )
        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
        expect(item.type).to eq('issue')
      end
    end
  end

  describe '#transfer' do
    context 'with tags' do
      it 'adds tags to transfer action' do
        alice = create_account('alice')
        bob = create_account('bob')
        action_tags = create_refdata('acting_party')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice)

        chain.transactions.transact do |b|
          b.transfer(
            amount: 100,
            flavor_id: usd.id,
            source_account_id: alice.id,
            destination_account_id: bob.id,
            action_tags: action_tags,
          )
        end

        items = chain.actions.list(
          filter: 'tags.acting_party=$1',
          filter_params: [action_tags['acting_party']],
        )
        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
        expect(item.type).to eq('transfer')
      end
    end
  end

  describe '#retire' do
    context 'with tags' do
      it 'adds tags to retire action' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        action_tags = create_refdata('acting_party')
        issue_flavor(100, usd, alice)

        chain.transactions.transact do |b|
          b.retire(
            amount: 100,
            flavor_id: usd.id,
            source_account_id: alice.id,
            action_tags: action_tags,
          )
        end

        items = chain.actions.list(
          filter: 'tags.acting_party=$1',
          filter_params: [action_tags['acting_party']],
        )
        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
        expect(item.type).to eq('retire')
      end
    end
  end
end
