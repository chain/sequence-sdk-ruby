# frozen_string_literal: true

describe 'transactions' do
  describe '#transfer' do
    context 'with filter' do
      it 'transfers flavors tagged with given filter' do
        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice, token_tags: { 'foo' => 'bar' })

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
        )
        expect(items.all.size).to eq 0
        items = chain.tokens.list(
          filter: 'account_id = $1',
          filter_params: [bob.id],
        )
        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
      end
    end
  end

  describe '#retire' do
    context 'with filter' do
      it 'retires flavors tagged with given filter' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice, token_tags: { 'foo' => 'bar' })
        issue_flavor(100, usd, alice)

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
        )
        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(usd.id)
      end
    end
  end

  describe '#list' do
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

    context 'with filter parameters and :size, :cursor pagination' do
      it 'paginates results' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice)
        issue_flavor(100, usd, alice)
        issue_flavor(100, usd, alice)

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
        tx = issue_flavor(100, usd, alice)

        chain.transactions.list(
          filter: 'actions(destination_account_id=$1)',
          filter_params: [alice.id],
        ).page.each do |item|
          expect(item).to be_a(Sequence::Transaction)
          expect(item.id).to eq(tx.id)
        end
      end
    end

    context '#all#each' do
      it 'yields transactions to the block' do
        chain.dev_utils.reset

        alice = create_account('alice')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice)
        issue_flavor(100, usd, alice)

        results = []
        chain.transactions.list.all.each do |item|
          expect(item).to be_a(Sequence::Transaction)
          results << item
        end

        expect(results.size).to eq(2)
      end
    end
  end
end
