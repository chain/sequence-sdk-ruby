# frozen_string_literal: true

describe 'transactions' do
  describe '#issue' do
    context 'with tags' do
      it 'adds tags to issue action' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        eur = create_flavor('eur')
        action_tags = create_tags('acting_party')
        issue(50, eur, alice)

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
        action_tags = create_tags('acting_party')
        usd = create_flavor('usd')
        issue(100, usd, alice)

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

    context 'with filter by timestamp' do
      it 'spends tokens from after a given point' do
        chain.dev_utils.reset

        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_flavor('usd')
        first_tx = issue(
          200,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'false' },
        )
        _second_tx = issue(
          100,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'true' },
        )

        chain.transactions.transact do |b|
          b.transfer(
            amount: 100,
            flavor_id: usd.id,
            source_account_id: alice.id,
            destination_account_id: bob.id,
            filter: 'tags.expiration:time > $1',
            filter_params: [first_tx.actions.first.snapshot.token_tags['expiration']],
          )
        end

        unspent_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['false'],
        )
        remaining_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['true'],
        )

        expect(unspent_tokens.all.size).to eq 1
        expect(unspent_tokens.all.first.amount).to eq 200
        expect(remaining_tokens.all.size).to eq 0
      end

      it 'spends tokens from before a given point' do
        chain.dev_utils.reset

        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_flavor('usd')
        _first_tx = issue(
          100,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'true' },
        )
        second_tx = issue(
          200,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'false' },
        )

        chain.transactions.transact do |b|
          b.transfer(
            amount: 100,
            flavor_id: usd.id,
            source_account_id: alice.id,
            destination_account_id: bob.id,
            filter: 'tags.expiration:time < $1',
            filter_params: [second_tx.actions.first.snapshot.token_tags['expiration']],
          )
        end

        unspent_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['false'],
        )
        remaining_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['true'],
        )

        expect(unspent_tokens.all.size).to eq 1
        expect(unspent_tokens.all.first.amount).to eq 200
        expect(remaining_tokens.all.size).to eq 0
      end

      it 'fails to spend tokens if not from before given point' do
        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_flavor('usd')
        _first_tx = issue(
          100,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3) },
        )
        second_tx = issue(
          200,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3) },
        )

        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 200,
              flavor_id: usd.id,
              source_account_id: alice.id,
              destination_account_id: bob.id,
              filter: 'tags.expiration:time < $1',
              filter_params: [second_tx.actions.first.snapshot.token_tags['expiration']],
            )
          end
        }.to raise_error(Sequence::APIError)
      end
    end
  end

  describe '#retire' do
    context 'with tags' do
      it 'adds tags to retire action' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        action_tags = create_tags('acting_party')
        issue(100, usd, alice)

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

    context 'with filter by timestamp' do
      it 'retires tokens from at or after a given point' do
        chain.dev_utils.reset

        alice = create_account('alice')
        usd = create_flavor('usd')
        _first_tx = issue(
          200,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'false' },
        )
        second_tx = issue(
          100,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'true' },
        )

        _third_tx = issue(
          100,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'true' },
        )

        chain.transactions.transact do |b|
          b.retire(
            amount: 200,
            flavor_id: usd.id,
            source_account_id: alice.id,
            filter: 'tags.expiration:time >= $1',
            filter_params: [second_tx.actions.first.snapshot.token_tags['expiration']],
          )
        end

        unspent_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['false'],
        )
        remaining_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['true'],
        )

        expect(unspent_tokens.all.size).to eq 1
        expect(unspent_tokens.all.first.amount).to eq 200
        expect(remaining_tokens.all.size).to eq 0
      end

      it 'retires tokens from at or before a given point' do
        chain.dev_utils.reset

        alice = create_account('alice')
        usd = create_flavor('usd')
        _first_tx = issue(
          100,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'true' },
        )
        second_tx = issue(
          100,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'true' },
        )
        _third_tx = issue(
          200,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3), spend_me: 'false' },
        )

        chain.transactions.transact do |b|
          b.retire(
            amount: 200,
            flavor_id: usd.id,
            source_account_id: alice.id,
            filter: 'tags.expiration:time <= $1',
            filter_params: [second_tx.actions.first.snapshot.token_tags['expiration']],
          )
        end

        unspent_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['false'],
        )
        remaining_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['true'],
        )

        expect(unspent_tokens.all.size).to eq 1
        expect(unspent_tokens.all.first.amount).to eq 200
        expect(remaining_tokens.all.size).to eq 0
      end

      it 'fails to retire tokens if not from after given point' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        first_tx = issue(
          200,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3) },
        )
        _second_tx = issue(
          100,
          usd,
          alice,
          token_tags: { expiration: DateTime.now.rfc3339(3) },
        )

        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 200,
              flavor_id: usd.id,
              source_account_id: alice.id,
              filter: 'tags.expiration:time > $1',
              filter_params: [first_tx.actions.first.snapshot.token_tags['expiration']],
            )
          end
        }.to raise_error(Sequence::APIError)
      end
    end
  end

  describe '#list with filter' do
    context 'by timestamp' do
      it 'lists transactions occurring after a given point' do
        chain.dev_utils.reset

        alice = create_account('alice')
        usd = create_flavor('usd')
        first_tx = issue(100, usd, alice)
        second_tx = issue(200, usd, alice)

        items = chain.transactions.list(
          filter: 'timestamp > $1',
          filter_params: [first_tx.timestamp.to_datetime.rfc3339(3)],
        )
        expect(items.all.size).to eq 1
        expect(items.all.first.id).to eq second_tx.id
      end

      it 'lists transactions occurring at or after a given point' do
        chain.dev_utils.reset

        alice = create_account('alice')
        usd = create_flavor('usd')
        _first_tx = issue(100, usd, alice)
        second_tx = issue(200, usd, alice)
        third_tx = issue(300, usd, alice)

        items = chain.transactions.list(
          filter: 'timestamp >= $1',
          filter_params: [second_tx.timestamp.to_datetime.rfc3339(3)],
        )
        expect(items.all.size).to eq 2
        expect(items.all.last.id).to eq second_tx.id
        expect(items.all.first.id).to eq third_tx.id
      end

      it 'lists transactions occurring before a given point' do
        chain.dev_utils.reset

        alice = create_account('alice')
        usd = create_flavor('usd')
        first_tx = issue(100, usd, alice)
        second_tx = issue(200, usd, alice)

        items = chain.transactions.list(
          filter: 'timestamp < $1',
          filter_params: [second_tx.timestamp.to_datetime.rfc3339(3)],
        )
        expect(items.all.size).to eq 1
        expect(items.all.first.id).to eq first_tx.id
      end

      it 'lists transactions occurring at or before a given point' do
        chain.dev_utils.reset

        alice = create_account('alice')
        usd = create_flavor('usd')
        first_tx = issue(100, usd, alice)
        second_tx = issue(200, usd, alice)
        _third_tx = issue(300, usd, alice)

        items = chain.transactions.list(
          filter: 'timestamp <= $1',
          filter_params: [second_tx.timestamp.to_datetime.rfc3339(3)],
        )
        expect(items.all.size).to eq 2
        expect(items.all.last.id).to eq first_tx.id
        expect(items.all.first.id).to eq second_tx.id
      end
    end
  end
end
