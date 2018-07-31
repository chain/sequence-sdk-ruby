# frozen_string_literal: true

describe 'indexes' do
  describe '#create' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect do
          chain.indexes.create(not: 'an-option')
        end.to raise_error(ArgumentError)
      end
    end

    context 'with missing options' do
      it 'raises argument error' do
        expect do
          chain.indexes.create(id: 'not-enough')
        end.to raise_error(ArgumentError)
      end
    end

    context 'when valid options provided' do
      it 'creates an index' do
        uuid = SecureRandom.uuid

        index = chain.indexes.create(
          id: uuid,
          type: 'token',
          method: 'sum',
          filter: "account_id = '#{uuid}'"
        )

        expect(index.id).to eq(uuid)
      end

      it 'creates an index without id' do
        uuid = SecureRandom.uuid

        index = chain.indexes.create(
          type: 'token',
          method: 'sum',
          filter: "account_id = '#{uuid}'"
        )

        expect(index.id).not_to be_empty
      end
    end

    context 'with a duplicate id' do
      it 'raises API error' do
        uuid = SecureRandom.uuid

        chain.indexes.create(
          id: uuid,
          type: 'token',
          method: 'sum',
          filter: "account_id = '#{uuid}-1'"
        )

        expect do
          chain.indexes.create(
            id: uuid,
            type: 'token',
            method: 'sum',
            filter: "account_id = '#{uuid}-2'"
          )
        end.to raise_error(Sequence::APIError)
      end
    end

    context 'with a duplicate filter' do
      it 'raises API error' do
        uuid = SecureRandom.uuid

        chain.indexes.create(
          type: 'token',
          method: 'sum',
          filter: "account_id = '#{uuid}'"
        )

        expect do
          chain.indexes.create(
            type: 'token',
            method: 'sum',
            filter: "account_id = '#{uuid}'"
          )
        end.to raise_error(Sequence::APIError)
      end
    end
  end

  describe '#delete' do
    context 'when :id is missing' do
      it 'raises argument error' do
        expect do
          chain.indexes.delete
        end.to raise_error(ArgumentError)
      end
    end

    it 'deletes a feed' do
      chain.dev_utils.reset

      delete_me = create_index

      list = chain.indexes.list.page
      expect(list.items.length).to eq 1

      chain.indexes.delete(id: delete_me.id)

      list = chain.indexes.list.page
      expect(list.items.length).to eq 0
    end
  end

  describe '#list' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect do
          chain.indexes.list(id: 'bad')
        end.to raise_error(ArgumentError)

        expect do
          chain.indexes.list(page_size: 1)
        end.to raise_error(ArgumentError)
      end
    end

    context 'with :size, :cursor pagination' do
      it 'paginates results' do
        chain.dev_utils.reset

        create_index
        create_index
        create_index

        page1 = chain.indexes.list.page(size: 2)
        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)
        expect(page1.last_page).to eq(false)

        page2 = chain.indexes.list.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(true)
      end
    end

    context '#page#each' do
      it 'yields indexes in the page to the block' do
        chain.dev_utils.reset

        index = create_index

        chain.indexes.list.page.each do |item|
          expect(item).to be_a(Sequence::Index)
          expect(item.id).to eq(index.id)
        end
      end
    end

    context '#each' do
      it 'yields keys to the block' do
        chain.dev_utils.reset

        create_index
        create_index

        results = []
        chain.indexes.list.each do |item|
          expect(item).to be_a(Sequence::Index)
          results << item
        end

        expect(results.size).to eq(2)
      end
    end
  end
end