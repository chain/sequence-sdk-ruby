# frozen_string_literal: true

describe 'keys' do
  describe '#create' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.keys.create(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'with no options' do
      it 'creates a key' do
        key = chain.keys.create

        expect(key.id).not_to be_empty
      end
    end

    context 'when :id is provided' do
      it 'creates a key with that ID' do
        uuid = SecureRandom.uuid

        key = chain.keys.create(id: uuid)

        expect(key.id).to eq(uuid)
      end
    end

    context 'with the same id' do
      it 'raises API error' do
        uuid = SecureRandom.uuid
        chain.keys.create(id: uuid)

        expect {
          chain.keys.create(id: uuid)
        }.to raise_error(Sequence::APIError)
      end
    end
  end

  describe '#list' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.keys.list(id: 'bad')
        }.to raise_error(ArgumentError)

        expect {
          chain.keys.list(page_size: 1)
        }.to raise_error(ArgumentError)
      end
    end

    context 'with :size, :cursor pagination' do
      it 'paginates results' do
        chain.dev_utils.reset

        create_key
        create_key
        create_key

        page1 = chain.keys.list.page(size: 2)
        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)
        expect(page1.last_page).to eq(false)

        page2 = chain.keys.list.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(true)
      end
    end

    context '#page#each' do
      it 'yields keys in the page to the block' do
        chain.dev_utils.reset

        key = create_key

        chain.keys.list.page.each do |item|
          expect(item).to be_a(Sequence::Key)
          expect(item.id).to eq(key.id)
        end
      end
    end

    context '#each' do
      it 'yields keys to the block' do
        chain.dev_utils.reset

        create_key
        create_key

        results = []
        chain.keys.list.each do |item|
          expect(item).to be_a(Sequence::Key)
          results << item
        end

        expect(results.size).to eq(2)
      end
    end
  end
end
