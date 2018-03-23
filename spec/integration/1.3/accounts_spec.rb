# frozen_string_literal: true

describe 'accounts' do
  describe '#list' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.accounts.list(id: 'bad')
        }.to raise_error(ArgumentError)

        expect {
          chain.accounts.list(page_size: 1)
        }.to raise_error(ArgumentError)
      end
    end

    context '#page(size:), #page(:cursor) with filter parameters' do
      it 'paginates results' do
        uuid = SecureRandom.uuid
        create_account('alice', tags: { foo: uuid })
        create_account('bob', tags: { foo: uuid })
        create_account('carol', tags: { foo: uuid })

        page1 = chain.accounts.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).page(size: 2)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)
        expect(page1.last_page).to eq(false)

        page2 = chain.accounts.list.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(true)
      end
    end

    context '#page(size:), #page(:cursor) and last page is full' do
      it 'recognizes the last page' do
        uuid = SecureRandom.uuid
        create_account('alice', tags: { foo: uuid })

        page1 = chain.accounts.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).page(size: 1)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(1)
        expect(page1.last_page).to eq(false)

        page2 = chain.accounts.list.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(0)
        expect(page2.last_page).to eq(true)
      end
    end

    context '#page#each' do
      it 'yields accounts in the page to the block' do
        uuid = SecureRandom.uuid
        alice = create_account('alice', tags: { foo: uuid })
        create_account('bob')

        chain.accounts.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).page.each do |item|
          expect(item).to be_a(Sequence::Account)
          expect(item.id).to eq(alice.id)
        end
      end
    end

    context '#all#each' do
      it 'yields accounts to the block' do
        uuid = SecureRandom.uuid
        create_account('alice', tags: { foo: uuid })
        create_account('bob', tags: { foo: uuid })

        results = []
        chain.accounts.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).all.each do |item|
          expect(item).to be_a(Sequence::Account)
          results << item
        end

        expect(results.size).to eq(2)
      end
    end
  end
end
