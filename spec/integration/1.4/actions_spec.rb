describe 'actions' do
  describe '#list' do
    context 'with filter for tags' do
      it 'returns list of action groups' do
        bob = create_account('bob')
        cash = create_flavor('cash')
        action_tags = { 'acting_party' => SecureRandom.uuid }
        issue_flavor(100, cash, bob, action_tags: action_tags)
        issue_flavor(100, cash, bob)

        items = chain.actions.list(
          filter: 'tags.acting_party=$1',
          filter_params: [action_tags['acting_party']],
        )

        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(cash.id)
        expect(item.destination_account_id).to eq(bob.id)
        expect(item.tags).to eq(action_tags)
      end
    end
  end

  describe '#sum' do
    context 'with filter for tags' do
      it 'returns sum of actions' do
        alice = create_account('alice')
        cert = create_flavor('stock-certificate')
        action_tags = { 'acting_party' => SecureRandom.uuid }
        issue_flavor(50, cert, alice, action_tags: action_tags)
        issue_flavor(50, cert, alice, action_tags: action_tags)
        issue_flavor(50, cert, alice)

        items = chain.actions.sum(
          filter: 'tags.acting_party=$1',
          filter_params: [action_tags['acting_party']],
        )

        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
      end
    end
  end
end
