# frozen_string_literal: true

describe 'feeds' do
  describe '#consume' do
    it 'consumes every spend and every issuance transaction' do
      gold = create_flavor('gold')
      silver = create_flavor('silver')
      alice = create_account('alice')
      bob = create_account('bob')
      issuances_feed = create_tx_feed('issue', [gold, silver])
      spends_feed = create_tx_feed('transfer', [gold, silver])
      consumed = { issuances: [], spends: [] }
      threads = []

      threads << Thread.new do
        f = chain.feeds.get(id: issuances_feed.id)
        f.consume do |tx|
          consumed[:issuances] << tx.id
          f.ack
          break if consumed[:issuances].size == 2
        end
      end
      threads << Thread.new do
        f = chain.feeds.get(id: spends_feed.id)
        f.consume do |tx|
          consumed[:spends] << tx.id
          f.ack
          break if consumed[:spends].size == 2
        end
      end

      produced = {
        issuances: [
          issue(1, gold, alice).id,
          issue(1, silver, bob).id,
        ],
        spends: [
          transfer(1, gold, alice, bob).id,
          transfer(1, silver, bob, alice).id,
        ],
      }

      threads.each(&:join) # wait

      expect(consumed[:issuances].sort).to eq(produced[:issuances].sort)
      expect(consumed[:spends].sort).to eq(produced[:spends].sort)
    end

    it 'consumes the same transaction in multiple threads' do
      gold = create_flavor('gold')
      alice = create_account('alice')
      issuances_feed = create_tx_feed('issue', [gold])
      consumed = { first_thread: nil, second_thread: nil }

      t = Thread.new do
        f = chain.feeds.get(id: issuances_feed.id)
        f.consume do |tx|
          consumed[:first_thread] = tx.id
          break
        end
      end

      issuance = issue(1, gold, alice)

      t.join # wait

      t = Thread.new do
        f = chain.feeds.get(id: issuances_feed.id)
        f.consume do |tx|
          consumed[:second_thread] = tx.id
          break
        end
      end

      t.join # wait

      expect(consumed[:first_thread]).to eq(issuance.id)
      expect(consumed[:first_thread]).to eq(consumed[:second_thread])
    end

    it 'consumes actions and transactions' do
      gold = create_flavor('gold')
      alice = create_account('alice')
      bob = create_account('bob')
      carol = create_account('carol')

      tx_feed = create_tx_feed('transfer', [gold])
      issue_action_feed = create_action_feed('issue', [gold])
      transfer_action_feed = create_action_feed('transfer', [gold])

      produced_issuance_action = nil
      produced_transfer_actions = []

      produced_tx = chain.transactions.transact do |b|
        produced_issuance_action = b.issue(
          amount: 3,
          flavor_id: gold.id,
          destination_account_id: alice.id,
        )
        produced_transfer_actions << b.transfer(
          amount: 1,
          flavor_id: gold.id,
          source_account_id: alice.id,
          destination_account_id: bob.id,
        )
        produced_transfer_actions << b.transfer(
          amount: 2,
          flavor_id: gold.id,
          source_account_id: alice.id,
          destination_account_id: carol.id,
        )
      end

      f = chain.feeds.get(id: tx_feed.id)
      f.consume do |tx|
        expect(tx.id).to eq(produced_tx.id)
        break
      end

      f = chain.feeds.get(id: issue_action_feed.id)
      f.consume do |action|
        expect(action.transaction_id).to eq(produced_tx.id)
        expect(action.type).to eq('issue')
        expect(action.flavor_id).to eq(gold.id)
        expect(action.amount).to eq(3)
        expect(action.destination_account_id).to eq(alice.id)
        break
      end

      first = true
      f = chain.feeds.get(id: transfer_action_feed.id)
      f.consume do |action|
        expect(action.transaction_id).to eq(produced_tx.id)
        expect(action.type).to eq('transfer')
        expect(action.flavor_id).to eq(gold.id)
        if first
          expect(action.amount).to eq(1)
          expect(action.destination_account_id).to eq(bob.id)
          first = false
        else
          expect(action.amount).to eq(2)
          expect(action.destination_account_id).to eq(carol.id)
          first = false
          break
        end
      end
    end
  end

  describe '#ack' do
    it 'checkpoints during consume' do
      gold = create_flavor('gold')
      alice = create_account('alice')
      bob = create_account('bob')

      feed = create_action_feed('transfer', [gold])

      chain.transactions.transact do |b|
        b.issue(
          amount: 3,
          flavor_id: gold.id,
          destination_account_id: alice.id,
        )
      end
      chain.transactions.transact do |b|
        b.transfer(
          amount: 1,
          flavor_id: gold.id,
          source_account_id: alice.id,
          destination_account_id: bob.id,
        )
      end
      chain.transactions.transact do |b|
        b.transfer(
          amount: 2,
          flavor_id: gold.id,
          source_account_id: alice.id,
          destination_account_id: bob.id,
        )
      end

      feed.consume do |action|
        expect(action.type).to eq('transfer')
        expect(action.flavor_id).to eq(gold.id)
        expect(action.amount).to eq(1)
        expect(action.source_account_id).to eq(alice.id)
        expect(action.destination_account_id).to eq(bob.id)
        break
      end

      # Start a new consume loop without checkpointing; should get the
      # same action.
      feed.consume do |action|
        expect(action.type).to eq('transfer')
        expect(action.flavor_id).to eq(gold.id)
        expect(action.amount).to eq(1)
        expect(action.source_account_id).to eq(alice.id)
        expect(action.destination_account_id).to eq(bob.id)
        break
      end

      feed.ack

      # After checkpointing, should get the next action.
      feed.consume do |action|
        expect(action.type).to eq('transfer')
        expect(action.flavor_id).to eq(gold.id)
        expect(action.amount).to eq(2)
        expect(action.source_account_id).to eq(alice.id)
        expect(action.destination_account_id).to eq(bob.id)
        break
      end
    end
  end

  describe '#create' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.feeds.create(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :type is missing' do
      it 'raises argument error' do
        expect {
          chain.feeds.create
        }.to raise_error(ArgumentError)
      end
    end

    context 'when type is not action or transaction' do
      it 'raises argument error' do
        expect {
          chain.feeds.create(
            type: 'not-action-or-transaction',
            filter: "actions(type='issue' AND flavor_id='foo')",
          )
        }.to raise_error(
          ArgumentError,
          ':type must equal action or transaction',
        )
      end
    end

    it 'creates feeds with filter params' do
      gold = create_flavor('gold')
      silver = create_flavor('silver')
      alice = create_account('alice')
      _gold_tx = issue(1, gold, alice)
      silver_tx = issue(1, silver, alice)

      feed = chain.feeds.create(
        id: create_id('issue'),
        type: 'transaction',
        filter: 'actions(type=$1 AND flavor_id=$2)',
        filter_params: ['issue', silver.id],
      )

      consumed = []
      feed.consume do |tx|
        consumed << tx.id
        break
      end
      expect(consumed).to eq([silver_tx.id])
    end
  end

  describe '#get' do
    context 'when :id is missing' do
      it 'raises argument error' do
        expect {
          chain.feeds.get
        }.to raise_error(ArgumentError)
      end
    end

    it 'gets a feed' do
      silver = create_flavor('silver')
      feed = create_tx_feed('issue', [silver])

      result = chain.feeds.get(id: feed.id)

      expect(result.id).to eq(feed.id)
    end
  end

  describe '#delete' do
    context 'when :id is missing' do
      it 'raises argument error' do
        expect {
          chain.feeds.delete
        }.to raise_error(ArgumentError)
      end
    end

    it 'deletes a feed' do
      pre_list = chain.feeds.list.map(&:id)
      silver = create_flavor('silver')
      issuances_feed = create_tx_feed('issue', [silver])
      spends_feed = create_tx_feed('transfer', [silver])

      chain.feeds.delete(id: issuances_feed.id)

      post_list = chain.feeds.list.map(&:id)
      list = post_list - pre_list
      expect(list).to eq([spends_feed.id])
    end
  end

  describe '#list' do
    context '#page with :size, :cursor pagination' do
      it 'paginates results' do
        gold = create_flavor('gold')
        create_tx_feed('issue', [gold])
        create_tx_feed('transfer', [gold])
        create_action_feed('issue', [gold])

        page1 = chain.feeds.list.page(size: 1)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(1)

        cursor = page1.cursor
        page2 = chain.feeds.list.page(cursor: cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(false)
      end
    end

    context '#each' do
      it 'returns feeds' do
        chain.dev_utils.reset
        gold = create_flavor('gold')
        feed1 = create_tx_feed('issue', [gold])
        feed2 = create_tx_feed('transfer', [gold])

        result = chain.feeds.list

        expect(result.map(&:id)).to match_array([feed1.id, feed2.id])
      end
    end
  end
end
