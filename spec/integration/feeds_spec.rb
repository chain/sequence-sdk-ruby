describe 'Feed', nonparallel: true do
  describe '#consume' do
    it 'consumes every spend and every issuance transaction' do
      gold = create_asset('gold')
      silver = create_asset('silver')
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
          break if consumed[:issuances].size == 2
        end
      end
      threads << Thread.new do
        f = chain.feeds.get(id: spends_feed.id)
        f.consume do |tx|
          consumed[:spends] << tx.id
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
      gold = create_asset('gold')
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
      gold = create_asset('gold')
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
          asset_id: gold.id,
          destination_account_id: alice.id
        )
        produced_transfer_actions << b.transfer(
          amount: 1,
          asset_id: gold.id,
          source_account_id: alice.id,
          destination_account_id: bob.id
        )
        produced_transfer_actions << b.transfer(
          amount: 2,
          asset_id: gold.id,
          source_account_id: alice.id,
          destination_account_id: carol.id
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
        expect(action.asset_id).to eq(gold.id)
        expect(action.amount).to eq(3)
        expect(action.destination_account_id).to eq(alice.id)
        break
      end

      first = true
      f = chain.feeds.get(id: transfer_action_feed.id)
      f.consume do |action|
        expect(action.transaction_id).to eq(produced_tx.id)
        expect(action.type).to eq('transfer')
        expect(action.asset_id).to eq(gold.id)
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
      gold = create_asset('gold')
      alice = create_account('alice')
      bob = create_account('bob')

      feed = create_action_feed('transfer', [gold])

      chain.transactions.transact do |b|
        b.issue(
          amount: 3,
          asset_id: gold.id,
          destination_account_id: alice.id
        )
      end
      chain.transactions.transact do |b|
        b.transfer(
          amount: 1,
          asset_id: gold.id,
          source_account_id: alice.id,
          destination_account_id: bob.id
        )
      end
      chain.transactions.transact do |b|
        b.transfer(
          amount: 2,
          asset_id: gold.id,
          source_account_id: alice.id,
          destination_account_id: bob.id
        )
      end

      feed.consume do |action|
        expect(action.type).to eq('transfer')
        expect(action.asset_id).to eq(gold.id)
        expect(action.amount).to eq(1)
        expect(action.source_account_id).to eq(alice.id)
        expect(action.destination_account_id).to eq(bob.id)
        break
      end

      # Start a new consume loop without checkpointing; should get the
      # same action.
      feed.consume do |action|
        expect(action.type).to eq('transfer')
        expect(action.asset_id).to eq(gold.id)
        expect(action.amount).to eq(1)
        expect(action.source_account_id).to eq(alice.id)
        expect(action.destination_account_id).to eq(bob.id)
        break
      end

      feed.ack

      # After checkpointing, should get the next action.
      feed.consume do |action|
        expect(action.type).to eq('transfer')
        expect(action.asset_id).to eq(gold.id)
        expect(action.amount).to eq(2)
        expect(action.source_account_id).to eq(alice.id)
        expect(action.destination_account_id).to eq(bob.id)
        break
      end
    end
  end

  describe '#query' do
    it 'queries feeds' do
      pre_list = chain.feeds.query.map(&:id)
      gold = create_asset('gold')
      issuances_feed = create_tx_feed('issue', [gold])
      spends_feed = create_tx_feed('transfer', [gold])

      post_list = chain.feeds.query.map(&:id)

      list = post_list - pre_list
      expect(list).to match_array([spends_feed.id, issuances_feed.id])
    end
  end

  describe '#delete' do
    it 'deletes feeds' do
      pre_list = chain.feeds.query.map(&:id)
      silver = create_asset('silver')
      issuances_feed = create_tx_feed('issue', [silver])
      spends_feed = create_tx_feed('transfer', [silver])

      chain.feeds.delete(id: issuances_feed.id)

      post_list = chain.feeds.query.map(&:id)
      list = post_list - pre_list
      expect(list).to eq([spends_feed.id])
    end
  end
end
