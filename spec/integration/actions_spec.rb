# frozen_string_literal: true

describe 'actions' do
  describe '#list' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.actions.list(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    it 'lists two issue actions' do
      alice = create_account('alice')
      gold = create_flavor('gold')
      tags = create_tags('test')
      2.times do
        issue(1, gold, alice, action_tags: tags)
      end

      num_actions = chain.actions.list(
        filter: "tags.test='#{tags['test']}'",
      ).to_a

      expect(num_actions.size).to eq(2)
    end

    it 'lists two transfer actions' do
      chain.dev_utils.reset
      alice = create_account('alice')
      bob = create_account('bob')
      btc = create_flavor('btc')
      usd = create_flavor('usd')
      tags = create_tags('test')
      issue(20, btc, alice, action_tags: tags)
      issue(50, usd, bob, action_tags: tags)
      transfer(10, btc, alice, bob, action_tags: tags)
      transfer(25, usd, bob, alice, action_tags: tags)

      num_actions = chain.actions.list(
        filter: 'tags.test=$1 AND type=$2',
        filter_params: [tags['test'], 'transfer'],
      ).to_a

      expect(num_actions.size).to eq(2)
    end

    context '#page with :size, :cursor' do
      it 'paginates results with cursor' do
        tags = create_tags('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        3.times do
          issue(1, gold, alice, action_tags: tags)
        end

        page1 = chain.actions.list(
          filter: "tags.test='#{tags['test']}'",
        ).page(size: 2)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)

        cursor = page1.cursor
        page2 = chain.actions.list.page(cursor: cursor)

        expect(page2.items.size).to eq(1)
      end
    end

    context '#page#each' do
      it 'yields the items in the page to the block' do
        tags = create_tags('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        issue(1, gold, alice, action_tags: tags)
        issue(1, gold, alice, action_tags: tags)

        chain.actions.list(
          filter: "tags.test='#{tags['test']}'",
        ).page.each do |action|
          expect(action).to be_a(Sequence::Action)
          expect(action.amount).to eq(1)
        end
      end
    end

    context '#each' do
      it 'iterates through entire set, yields actions to block' do
        tags = create_tags('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        3.times do
          issue(1, gold, alice, action_tags: tags)
        end

        results = []
        chain.actions.list(
          filter: "tags.test='#{tags['test']}'",
        ).each do |x|
          results << x
        end

        expect(results.size).to eq(3)
      end

      it 'can break early' do
        tags = create_tags('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        3.times do
          issue(1, gold, alice, action_tags: tags)
        end

        results = []
        chain.actions.list(
          filter: "tags.test='#{tags['test']}'",
        ).each do |x|
          results << x
          if results.size == 1
            break
          end
        end

        expect(results.size).to eq(1)
      end
    end

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
        ).to_a

        expect(items.size).to eq 1
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
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.amount).to eq 200
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
        ).to_a

        expect(items.size).to eq 2
        expect(items.first.amount).to eq 300
        expect(items.last.amount).to eq 200
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
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.amount).to eq 100
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
        ).to_a

        expect(items.size).to eq 2
        expect(items.first.amount).to eq 200
        expect(items.last.amount).to eq 100
      end
    end
  end

  describe '#sum' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.actions.sum(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    it 'filters by destination account and returns correct sum' do
      alice = create_account('alice')
      gold = create_flavor('gold')
      issue(100, gold, alice)
      issue(100, gold, alice)

      result = chain.actions.sum(
        filter: "destination_account_id='#{alice.id}'",
      ).first

      expect(result.amount).to eq(200)
    end

    it 'filters by flavor and returns correct sum' do
      alice = create_account('alice')
      bob = create_account('bob')
      btc = create_flavor('btc')
      usd = create_flavor('usd')
      issue(1, btc, alice)
      issue(5, usd, alice)
      issue(2, btc, bob)

      result = chain.actions.sum(
        filter: "flavor_id='#{btc.id}'",
      ).first

      expect(result.amount).to eq(3)
    end

    it 'sums by given fields' do
      chain.dev_utils.reset
      alice = create_account('alice')
      bob = create_account('bob')
      btc = create_flavor('btc')
      usd = create_flavor('usd')
      issue(20, btc, alice)
      issue(50, usd, bob)
      transfer(10, btc, alice, bob)
      transfer(25, usd, bob, alice)

      result = chain.actions.sum(
        group_by: ['type'],
      ).to_a

      expect(result.size).to eq(2)
      expect(result.detect { |r| r.type == 'issue' }.amount).to eq(70)
      expect(result.detect { |r| r.type == 'transfer' }.amount).to eq(35)
    end

    it 'handles nested JSON objects like tags and reference data' do
      chain.dev_utils.reset
      alice = create_account('alice')
      bob = create_account('bob')
      btc = create_flavor('btc')
      usd = create_flavor('usd')
      issue(20, btc, alice)
      issue(50, usd, bob)
      transfer(10, btc, alice, bob, action_tags: { 'one': 'fish' })
      transfer(25, usd, bob, alice, action_tags: { 'two': 'fish' })

      result = chain.actions.sum(
        group_by: ['tags.one'],
      ).to_a

      expect(result.size).to eq(2)
      expect(
        result.detect { |r| r.tags == { 'one' => nil } }.amount,
      ).to eq(95)
      expect(
        result.detect { |r| r.tags == { 'one' => 'fish' } }.amount,
      ).to eq(10)
    end

    context '#page with :size, :cursor, :group_by' do
      it 'paginates results with cursor' do
        tags = create_tags('test')
        alice = create_account('alice')
        bob = create_account('bob')
        carol = create_account('carol')
        gold = create_flavor('gold')
        issue(1, gold, alice, action_tags: tags)
        issue(1, gold, bob, action_tags: tags)
        issue(1, gold, carol, action_tags: tags)

        page1 = chain.actions.sum(
          filter: "tags.test='#{tags['test']}'",
          group_by: ['destination_account_id'],
        ).page(size: 2)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)
        expect(page1.last_page).to eq(false)

        page2 = chain.actions.sum.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(true)
      end
    end

    context '#page#each' do
      it 'yields the items in the page to the block' do
        tags = create_tags('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        issue(1, gold, alice, action_tags: tags)
        issue(1, gold, alice, action_tags: tags)

        chain.actions.sum(
          filter: 'tags.test=$1',
          filter_params: [tags['test']],
          group_by: ['destination_account_id'],
        ).page.each do |action|
          expect(action).to be_a(Sequence::Action)
          expect(action.amount).to eq(2)
        end
      end
    end

    context '#each with :group_by' do
      it 'iterates through the result set' do
        tags = create_tags('test')
        alice = create_account('alice')
        bob = create_account('bob')
        gold = create_flavor('gold')
        issue(1, gold, alice, action_tags: tags)
        issue(1, gold, bob, action_tags: tags)

        results = []
        chain.actions.sum(
          filter: "tags.test='#{tags['test']}'",
          group_by: ['destination_account_id'],
        ).each do |x|
          results << x
        end

        expect(results.size).to eq(2)
      end
    end

    context '#each with filter for tags' do
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
        ).to_a

        expect(items.size).to eq 1
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
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.amount).to eq 200
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
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.amount).to eq 500
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
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.amount).to eq 100
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
        ).to_a

        expect(items.size).to eq 1
        expect(items.first.amount).to eq 300
      end
    end
  end
end
