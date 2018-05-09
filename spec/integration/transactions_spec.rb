# frozen_string_literal: true

describe 'transactions' do
  describe '#issue' do
    context 'for non-existent flavors' do
      it 'raises API error' do
        alice = create_account('alice')

        expect {
          chain.transactions.transact do |b|
            b.issue(
              amount: 100,
              flavor_id: 'unobtanium',
              destination_account_id: alice.id,
            )
          end
        }.to raise_error(Sequence::APIError)
      end
    end

    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(not: 'an-option')
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :amount' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(
              flavor_id: create_id('usd'),
              destination_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(
              amount: 100,
              destination_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :destination_account_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(
              amount: 100,
              flavor_id: create_id('usd'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'with action tags' do
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
        ).to_a

        expect(items.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
        expect(item.type).to eq('issue')
      end
    end

    context 'with transaction tags' do
      it 'adds tags to transaction' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        eur = create_flavor('eur')
        tags = create_tags('foo')
        issue(50, eur, alice)

        chain.transactions.transact do |b|
          b.issue(
            amount: 100,
            flavor_id: usd.id,
            destination_account_id: alice.id,
          )
          b.transaction_tags = tags
        end

        tx = chain.transactions.list(
          filter: 'actions(snapshot.transaction_tags.foo=$1)',
          filter_params: [tags['foo']],
        ).first
        action = tx.actions.first

        expect(tx.tags).to eq(tags)
        expect(action.snapshot.transaction_tags).to eq(tags)
        expect(action.type).to eq('issue')
        expect(action.amount).to eq 100
        expect(action.flavor_id).to eq(usd.id)
        expect(action.destination_account_id).to eq(alice.id)
      end
    end
  end

  describe '#transfer' do
    context 'for non-existent flavors' do
      it 'raises API error' do
        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_flavor('usd')
        issue(100, usd, alice)

        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              flavor_id: 'unobtanium',
              source_account_id: alice.id,
              destination_account_id: bob.id,
            )
          end
        }.to raise_error(Sequence::APIError)
      end
    end

    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(not: 'an-option')
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :amount' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              flavor_id: create_id('usd'),
              source_account_id: create_id('alice'),
              destination_account_id: create_id('bob'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              source_account_id: create_id('alice'),
              destination_account_id: create_id('bob'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :source_account_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              flavor_id: create_id('usd'),
              destination_account_id: create_id('bob'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :destination_account_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              flavor_id: create_id('usd'),
              source_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

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
        ).to_a

        expect(items.size).to eq 1
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
        ).to_a
        remaining_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['true'],
        ).to_a

        expect(unspent_tokens.size).to eq 1
        expect(unspent_tokens.first.amount).to eq 200
        expect(remaining_tokens.size).to eq 0
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
        ).to_a
        remaining_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['true'],
        ).to_a

        expect(unspent_tokens.size).to eq 1
        expect(unspent_tokens.first.amount).to eq 200
        expect(remaining_tokens.size).to eq 0
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

    context 'with filter' do
      it 'transfers flavors tagged with given filter' do
        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_flavor('usd')
        issue(100, usd, alice, token_tags: { 'foo' => 'bar' })

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
        ).to_a

        expect(items.size).to eq 0

        items = chain.tokens.list(
          filter: 'account_id = $1',
          filter_params: [bob.id],
        ).to_a

        expect(items.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
      end
    end
  end

  describe '#retire' do
    context 'for non-existent flavors' do
      it 'raises API error' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue(100, usd, alice)

        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 100,
              flavor_id: 'unobtanium',
              source_account_id: alice.id,
            )
          end
        }.to raise_error(Sequence::APIError)
      end
    end

    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(not: 'an-option')
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :amount' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(
              flavor_id: create_id('usd'),
              source_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 100,
              source_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :source_account_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 100,
              flavor_id: create_id('usd'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

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
        ).to_a

        expect(items.size).to eq 1
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
        ).to_a
        remaining_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['true'],
        ).to_a

        expect(unspent_tokens.size).to eq 1
        expect(unspent_tokens.first.amount).to eq 200
        expect(remaining_tokens.size).to eq 0
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
        ).to_a
        remaining_tokens = chain.tokens.list(
          filter: 'tags.spend_me=$1',
          filter_params: ['true'],
        ).to_a

        expect(unspent_tokens.size).to eq 1
        expect(unspent_tokens.first.amount).to eq 200
        expect(remaining_tokens.size).to eq 0
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

      context 'with filter' do
        it 'retires flavors tagged with given filter' do
          alice = create_account('alice')
          usd = create_flavor('usd')
          issue(100, usd, alice, token_tags: { 'foo' => 'bar' })
          issue(100, usd, alice)

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
          ).to_a

          expect(items.size).to eq 1
          item = items.first
          expect(item.amount).to eq 100
          expect(item.flavor_id).to eq(usd.id)
        end
      end
    end
  end

  describe '#list' do
    context 'with filter using camelCase/snake_case' do
      it 'lists transactions using snake_case' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue(100, usd, alice)

        items = chain.tokens.list(
          filter: 'account_id = $1',
          filter_params: [alice.id],
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.amount).to eq 100
        expect(items.first.flavor_id).to eq(usd.id)
      end

      it 'fails to list transactions using camelCase' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue(100, usd, alice)

        expect {
          chain.tokens.list(
            filter: 'accountId = $1',
            filter_params: [alice.id],
          ).to_a
        }.to raise_error(Sequence::APIError)
      end
    end

    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.transactions.list(id: 'bad')
        }.to raise_error(ArgumentError)

        expect {
          chain.transactions.list(page_size: 1)
        }.to raise_error(ArgumentError)
      end
    end

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
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.id).to eq second_tx.id
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
        ).to_a

        expect(items.size).to eq 2
        expect(items.last.id).to eq second_tx.id
        expect(items.first.id).to eq third_tx.id
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
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.id).to eq first_tx.id
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
        ).to_a

        expect(items.size).to eq 2
        expect(items.last.id).to eq first_tx.id
        expect(items.first.id).to eq second_tx.id
      end
    end

    context 'with filter parameters and :size, :cursor pagination' do
      it 'paginates results' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue(100, usd, alice)
        issue(100, usd, alice)
        issue(100, usd, alice)

        page1 = chain.transactions.list(
          filter: 'actions(destination_account_id=$1)',
          filter_params: [alice.id],
        ).page(size: 2)
        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)
        expect(page1.last_page).to eq(false)

        page2 = chain.transactions.list.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(true)
      end
    end

    context '#page#each' do
      it 'yields transactions in the page to the block' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        tx = issue(100, usd, alice)

        chain.transactions.list(
          filter: 'actions(destination_account_id=$1)',
          filter_params: [alice.id],
        ).page.each do |item|
          expect(item).to be_a(Sequence::Transaction)
          expect(item.id).to eq(tx.id)
        end
      end
    end

    context '#each' do
      it 'yields transactions to the block' do
        chain.dev_utils.reset

        alice = create_account('alice')
        usd = create_flavor('usd')
        issue(100, usd, alice)
        issue(100, usd, alice)

        results = []
        chain.transactions.list.each do |item|
          expect(item).to be_a(Sequence::Transaction)
          results << item
        end

        expect(results.size).to eq(2)
      end
    end
  end
end
