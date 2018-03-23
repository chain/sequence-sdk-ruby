# frozen_string_literal: true

describe Sequence::Action::ClientModule do
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
      ).all

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
      ).all

      expect(num_actions.size).to eq(2)
    end

    context 'with :page_size, :after' do
      it 'paginates results reverse chronologically' do
        tags = create_tags('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        issue(1, gold, alice, action_tags: tags)
        bob = create_account('bob')
        btc = create_flavor('btc')
        issue(1, btc, bob, action_tags: tags)

        first_page = chain.actions.list(
          filter: "tags.test='#{tags['test']}'",
          page_size: 1,
        ).pages.first

        expect(first_page).to be_a(Sequence::Page)
        expect(first_page.items.size).to eq(1)

        action = first_page.items.first

        expect(action.type).to eq('issue')
        expect(action.flavor_id).to eq(btc.id)
        expect(action.destination_account_id).to eq(bob.id)

        second_page = chain.actions.list(
          filter: "tags.test='#{tags['test']}'",
          after: first_page.next['after'],
        ).pages.first

        action = second_page.items.first

        expect(action.type).to eq('issue')
        expect(action.flavor_id).to eq(gold.id)
        expect(action.destination_account_id).to eq(alice.id)
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
      ).all

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
      ).all

      expect(result.size).to eq(2)
      expect(
        result.detect { |r| r.tags == { 'one' => nil } }.amount,
      ).to eq(95)
      expect(
        result.detect { |r| r.tags == { 'one' => 'fish' } }.amount,
      ).to eq(10)
    end
  end
end
