# frozen_string_literal: true

describe 'actions' do
  describe '#list' do
    context 'with filter for tags' do
      it 'returns list of action groups' do
        bob = create_account('bob')
        cash = create_flavor('cash')
        action_tags = { 'acting_party' => SecureRandom.uuid }
        issue(100, cash, bob, action_tags: action_tags)
        issue(100, cash, bob)

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

    context 'with filter for timestamp' do
      it 'returns list of actions occurring after a given point' do
        chain.dev_utils.reset

        bob = create_account('bob')
        cash = create_flavor('cash')
        first_tx = issue(100, cash, bob)
        _second_tx = issue(200, cash, bob)

        items = chain.actions.list(
          filter: 'timestamp > $1',
          filter_params: [first_tx.timestamp.to_datetime.rfc3339(3)],
        )

        expect(items.all.size).to eq 1
        expect(items.all.first.amount).to eq 200
      end

      it 'returns list of actions occurring at or after a given point' do
        chain.dev_utils.reset

        bob = create_account('bob')
        cash = create_flavor('cash')
        _first_tx = issue(100, cash, bob)
        second_tx = issue(200, cash, bob)
        _third_tx = issue(300, cash, bob)

        items = chain.actions.list(
          filter: 'timestamp >= $1',
          filter_params: [second_tx.timestamp.to_datetime.rfc3339(3)],
        )

        expect(items.all.size).to eq 2
        expect(items.all.first.amount).to eq 300
        expect(items.all.last.amount).to eq 200
      end

      it 'returns list of actions occurring before a given point' do
        chain.dev_utils.reset

        bob = create_account('bob')
        cash = create_flavor('cash')
        _first_tx = issue(100, cash, bob)
        second_tx = issue(200, cash, bob)

        items = chain.actions.list(
          filter: 'timestamp < $1',
          filter_params: [second_tx.timestamp.to_datetime.rfc3339(3)],
        )

        expect(items.all.size).to eq 1
        expect(items.all.first.amount).to eq 100
      end

      it 'returns list of actions occurring at or before a given point' do
        chain.dev_utils.reset

        bob = create_account('bob')
        cash = create_flavor('cash')
        _first_tx = issue(100, cash, bob)
        second_tx = issue(200, cash, bob)
        _third_tx = issue(300, cash, bob)

        items = chain.actions.list(
          filter: 'timestamp <= $1',
          filter_params: [second_tx.timestamp.to_datetime.rfc3339(3)],
        )

        expect(items.all.size).to eq 2
        expect(items.all.first.amount).to eq 200
        expect(items.all.last.amount).to eq 100
      end
    end
  end

  describe '#sum' do
    context 'with filter for tags' do
      it 'returns sum of actions' do
        alice = create_account('alice')
        cert = create_flavor('stock-certificate')
        action_tags = { 'acting_party' => SecureRandom.uuid }
        issue(50, cert, alice, action_tags: action_tags)
        issue(50, cert, alice, action_tags: action_tags)
        issue(50, cert, alice)

        items = chain.actions.sum(
          filter: 'tags.acting_party=$1',
          filter_params: [action_tags['acting_party']],
        )

        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
      end
    end

    context 'with filter for timestamp' do
      it 'returns sum of actions occurring after a given point' do
        chain.dev_utils.reset

        bob = create_account('bob')
        cash = create_flavor('cash')
        first_tx = issue(100, cash, bob)
        _second_tx = issue(200, cash, bob)

        items = chain.actions.sum(
          filter: 'destination_account_id=$1 AND timestamp > $2',
          filter_params: [bob.id, first_tx.timestamp.to_datetime.rfc3339(3)],
        )

        expect(items.all.size).to eq 1
        expect(items.all.first.amount).to eq 200
      end

      it 'returns sum of actions occurring at or after a given point' do
        chain.dev_utils.reset

        bob = create_account('bob')
        cash = create_flavor('cash')
        _first_tx = issue(100, cash, bob)
        second_tx = issue(200, cash, bob)
        _third_tx = issue(300, cash, bob)

        items = chain.actions.sum(
          filter: 'destination_account_id=$1 AND timestamp >= $2',
          filter_params: [bob.id, second_tx.timestamp.to_datetime.rfc3339(3)],
        )

        expect(items.all.size).to eq 1
        expect(items.all.first.amount).to eq 500
      end

      it 'returns sum of actions occurring before a given point' do
        chain.dev_utils.reset

        bob = create_account('bob')
        cash = create_flavor('cash')
        _first_tx = issue(100, cash, bob)
        second_tx = issue(200, cash, bob)

        items = chain.actions.sum(
          filter: 'destination_account_id=$1 AND timestamp < $2',
          filter_params: [bob.id, second_tx.timestamp.to_datetime.rfc3339(3)],
        )

        expect(items.all.size).to eq 1
        expect(items.all.first.amount).to eq 100
      end

      it 'returns sum of actions occurring at or before a given point' do
        chain.dev_utils.reset

        bob = create_account('bob')
        cash = create_flavor('cash')
        _first_tx = issue(100, cash, bob)
        second_tx = issue(200, cash, bob)
        _third_tx = issue(300, cash, bob)

        items = chain.actions.sum(
          filter: 'destination_account_id=$1 AND timestamp <= $2',
          filter_params: [bob.id, second_tx.timestamp.to_datetime.rfc3339(3)],
        )

        expect(items.all.size).to eq 1
        expect(items.all.first.amount).to eq 300
      end
    end
  end
end
