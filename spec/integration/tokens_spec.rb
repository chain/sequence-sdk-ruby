# frozen_string_literal: true

describe 'tokens' do
  describe '#list' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.tokens.list(id: 'bad')
        }.to raise_error(ArgumentError)

        expect {
          chain.tokens.list(page_size: 1)
        }.to raise_error(ArgumentError)
      end
    end

    context 'with filter for flavor_id' do
      it 'returns list of token groups' do
        alice = create_account('alice')
        cert = create_flavor('stock-certificate')
        issue(100, cert, alice)

        items = chain.tokens.list(
          filter: "flavor_id='#{cert.id}'",
        ).to_a

        expect(items.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(cert.id)
        expect(item.flavor_tags).to be_nil
        expect(item.account_id).to eq(alice.id)
        expect(item.account_tags).to be_nil
      end
    end

    context 'with filter for flavor_tags and account_id' do
      it 'returns list of token groups' do
        oakland = create_account('oakland-dealership')
        vin = '5GAKVBKD4FJ211258'
        q5 = chain.flavors.create(
          id: create_id('audi'),
          tags: {
            make: 'Audi',
            model: 'Q5',
            vin: vin,
            year: '2010',
          },
          key_ids: [create_key.id],
        )
        issue(1, q5, oakland)

        items = chain.tokens.list(
          filter: 'flavor_tags.vin=$1 AND account_id=$2',
          filter_params: [vin, oakland.id],
        ).to_a

        expect(items.size).to eq 1
        item = items.first
        expect(item.amount).to eq 1
        expect(item.flavor_id).to eq(q5.id)
        expect(item.account_id).to eq(oakland.id)
      end
    end

    context 'with filter for tags' do
      it 'returns list of token groups' do
        bob = create_account('bob')
        cash = create_flavor('cash')
        token_tags = create_tags('due_date')
        issue(100, cash, bob, token_tags: token_tags)
        issue(100, cash, bob)

        items = chain.tokens.list(
          filter: 'tags.due_date=$1',
          filter_params: [token_tags['due_date']],
        ).to_a

        expect(items.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(cash.id)
        expect(item.flavor_tags).to be_nil
        expect(item.account_id).to eq(bob.id)
        expect(item.account_tags).to be_nil
        expect(item.tags).to eq(token_tags)
      end
    end

    context 'with :size, :cursor, using .page' do
      it 'paginates results with cursor' do
        chain.dev_utils.reset

        alice = create_account('alice')
        gold = create_flavor('gold')
        issue(1, gold, alice, token_tags: { due: 'today' })
        issue(1, gold, alice, token_tags: { due: 'tomorrow' })
        issue(1, gold, alice, token_tags: { due: 'next week' })

        page1 = chain.tokens.list.page(size: 2)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)

        cursor = page1.cursor
        page2 = chain.tokens.list.page(cursor: cursor)

        expect(page2.items.size).to eq(1)
      end
    end

    context '#each' do
      it 'iterates through the result set' do
        chain.dev_utils.reset

        alice = create_account('alice')
        gold = create_flavor('gold')
        issue(1, gold, alice, token_tags: { due: 'today' })
        issue(1, gold, alice, token_tags: { due: 'tomorrow' })
        issue(1, gold, alice, token_tags: { due: 'next week' })

        results = []
        chain.tokens.list.each do |x|
          results << x
        end

        expect(results.size).to eq(3)
      end
    end
  end

  describe '#sum' do
    context 'with filter for flavor_id' do
      it 'returns sum of tokens' do
        alice = create_account('alice')
        cert = create_flavor('stock-certificate')
        issue(50, cert, alice)
        issue(50, cert, alice)

        items = chain.tokens.sum(
          filter: "flavor_id='#{cert.id}'",
        ).to_a

        expect(items.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to be_nil
        expect(item.flavor_tags).to be_nil
        expect(item.account_id).to be_nil
        expect(item.account_tags).to be_nil
        expect(item.tags).to be_nil
      end
    end

    context 'grouped by flavor_id and account_id' do
      it 'returns sum of tokens' do
        alice = create_account('alice')
        cert = create_flavor('stock-certificate')
        issue(50, cert, alice)
        issue(50, cert, alice)

        items = chain.tokens.sum(
          filter: "flavor_id='#{cert.id}'",
          group_by: ['flavor_id', 'account_id'],
        ).to_a

        expect(items.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq cert.id
        expect(item.account_id).to eq alice.id
      end
    end

    context 'with :size, :cursor, using .page' do
      it 'paginates results with cursor' do
        chain.dev_utils.reset

        alice = create_account('alice')
        bob = create_account('bob')
        gold = create_flavor('gold')
        issue(1, gold, alice)
        issue(1, gold, bob)

        page1 = chain.tokens.sum(group_by: ['account_id']).page(size: 1)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(1)
        expect(page1.last_page).to eq(false)

        page2 = chain.tokens.sum.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(false)

        page3 = chain.tokens.sum.page(cursor: page2.cursor)

        expect(page3.items.size).to eq(0)
        expect(page3.last_page).to eq(true)
      end
    end

    context '#each with :group_by' do
      it 'iterates through the result set' do
        chain.dev_utils.reset

        alice = create_account('alice')
        bob = create_account('bob')
        gold = create_flavor('gold')
        issue(1, gold, alice)
        issue(1, gold, bob)

        results = []
        chain.tokens.sum(
          group_by: ['account_id'],
        ).each do |x|
          results << x
        end

        expect(results.size).to eq(2)
      end
    end
  end
end
