# frozen_string_literal: true

describe 'accounts' do
  describe '#create' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.accounts.create(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :key_ids are missing' do
      it 'raises argument error' do
        expect {
          chain.accounts.create
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :key_ids are empty' do
      it 'raises argument error' do
        expect {
          chain.accounts.create(key_ids: [])
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :key_ids are provided' do
      it 'creates an account' do
        key = create_key

        result = chain.accounts.create(key_ids: [key.id])

        expect(result.id).not_to be_empty
      end
    end

    context 'when :id is provided' do
      it 'creates an account with that ID' do
        key = create_key
        id = create_id('alice')

        result = chain.accounts.create(id: id, key_ids: [key.id])

        expect(result.id).to eq(id)
      end
    end
  end

  describe '#update_tags' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.accounts.update_tags(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :id is missing' do
      it 'raises argument error' do
        expect {
          chain.accounts.update_tags(tags: { x: 'three' })
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :id is blank' do
      it 'raises argument error' do
        expect {
          chain.accounts.update_tags(id: '', tags: { x: 'three' })
        }.to raise_error(ArgumentError)
      end
    end

    context 'with :id' do
      it 'updates tags for account' do
        key = create_key
        account = chain.accounts.create(key_ids: [key.id], tags: { x: 'foo' })
        other = chain.accounts.create(key_ids: [key.id], tags: { y: 'bar' })

        chain.accounts.update_tags(id: account.id, tags: { x: 'baz' })

        query = chain.accounts.list(filter: "id='#{account.id}'").first
        expect(query.tags).to eq('x' => 'baz')
        query = chain.accounts.list(filter: "id='#{other.id}'").first
        expect(query.tags).to eq('y' => 'bar')
      end
    end
  end

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

    context '#each' do
      it 'iterates through entire set, yields accounts to block' do
        uuid = SecureRandom.uuid
        101.times do
          create_account('alice', tags: { foo: uuid })
        end

        results = []
        chain.accounts.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).each do |item|
          expect(item).to be_a(Sequence::Account)
          results << item
        end

        expect(results.size).to eq(101)
      end

      it 'can break early' do
        uuid = SecureRandom.uuid
        4.times do
          create_account('alice', tags: { foo: uuid })
        end

        results = []
        chain.accounts.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).each do |item|
          expect(item).to be_a(Sequence::Account)
          results << item
          if results.size == 3
            break
          end
        end

        expect(results.size).to eq(3)
      end
    end
  end
end
