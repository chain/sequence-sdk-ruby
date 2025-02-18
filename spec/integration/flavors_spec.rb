# frozen_string_literal: true

describe 'flavors' do
  describe '#create' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.flavors.create(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :key_ids are missing' do
      it 'raises argument error' do
        expect {
          chain.flavors.create
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :key_ids are empty' do
      it 'raises argument error' do
        expect {
          chain.flavors.create(key_ids: [])
        }.to raise_error(
          ArgumentError,
          ':key_ids cannot be empty',
        )
      end
    end

    context 'when :key_ids are provided' do
      it 'creates a flavor' do
        key = create_key

        result = chain.flavors.create(key_ids: [key.id])

        expect(result.id).not_to be_empty
      end
    end

    context 'when :key_ids and :id are provided' do
      it 'creates a flavor with user specified id' do
        key = create_key
        id = create_id('user-specified')

        result = chain.flavors.create(id: id, key_ids: [key.id])

        expect(result.id).to eq(id)
      end
    end
  end

  describe '#update_tags' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.flavors.update_tags(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :id is missing' do
      it 'raises argument error' do
        expect {
          chain.flavors.update_tags(tags: { foo: 'bar' })
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :id is blank' do
      it 'raises argument error' do
        expect {
          chain.flavors.update_tags(id: '', tags: { foo: 'bar' })
        }.to raise_error(ArgumentError)
      end
    end

    context 'with :id' do
      it 'updates tags for flavor' do
        key = create_key
        flavor = chain.flavors.create(key_ids: [key.id], tags: { x: 'foo' })
        other = chain.flavors.create(key_ids: [key.id], tags: { y: 'bar' })

        chain.flavors.update_tags(id: flavor.id, tags: { x: 'baz' })

        list = chain.flavors.list(filter: "id='#{flavor.id}'").first
        expect(list.tags).to eq('x' => 'baz')
        list = chain.flavors.list(filter: "id='#{other.id}'").first
        expect(list.tags).to eq('y' => 'bar')
      end
    end
  end

  describe '#list' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.flavors.list(id: 'bad')
        }.to raise_error(ArgumentError)
      end
    end

    context 'with filter' do
      it 'finds the flavor' do
        key = create_key
        flavor = chain.flavors.create(key_ids: [key.id])

        list = chain.flavors.list(filter: "id='#{flavor.id}'").first

        expect(list.id).to eq flavor.id
      end
    end

    context 'with filter parameters' do
      it 'finds the flavor' do
        flavor = create_flavor('usd', tags: { type: 'checking' })

        list = chain.flavors.list(
          filter: 'tags.type=$1',
          filter_params: ['checking'],
        ).first

        expect(list.id).to eq flavor.id
      end
    end

    context 'with filter parameters and :size, :cursor pagination' do
      it 'paginates results' do
        uuid = SecureRandom.uuid
        create_flavor('btc', tags: { foo: uuid })
        create_flavor('eth', tags: { foo: uuid })
        create_flavor('ltc', tags: { foo: uuid })

        page1 = chain.flavors.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).page(size: 2)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)
        expect(page1.last_page).to eq(false)

        page2 = chain.flavors.list.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(true)
      end
    end

    context '#page#each' do
      it 'yields flavors in the page to the block' do
        uuid = SecureRandom.uuid
        btc = create_flavor('btc', tags: { foo: uuid })
        create_flavor('eth')

        chain.flavors.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).page.each do |item|
          expect(item).to be_a(Sequence::Flavor)
          expect(item.id).to eq(btc.id)
        end
      end
    end

    context '#each' do
      it 'yields flavors to the block' do
        uuid = SecureRandom.uuid
        create_flavor('btc', tags: { foo: uuid })
        create_flavor('eth', tags: { foo: uuid })

        results = []
        chain.flavors.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).each do |item|
          expect(item).to be_a(Sequence::Flavor)
          results << item
        end

        expect(results.size).to eq(2)
      end
    end
  end
end
