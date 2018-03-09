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

    context 'with the same alias' do
      it 'raises API error' do
        uuid = SecureRandom.uuid
        chain.keys.create(alias: uuid)

        expect {
          chain.keys.create(alias: uuid)
        }.to raise_error(Sequence::APIError)
      end
    end
  end

  describe '#query' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.keys.query(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'with no options' do
      it 'finds all keys' do
        key = create_key

        query = chain.keys.query.first

        expect(query.id).to eq key.id
      end
    end

    context 'with :page_size, :after' do
      it 'paginates results reverse chronologically' do
        old_key = create_key
        new_key = create_key

        first_page = chain.keys.query(page_size: 1).pages.first

        expect(first_page).to be_a(Sequence::Page)
        expect(first_page.items.size).to eq(1)
        expect(first_page.items.first.id).to eq(new_key.id)

        second_page = chain.keys.query(
          after: first_page.next['after'],
        ).pages.first

        expect(second_page.items.first.id).to eq(old_key.id)
      end
    end
  end
end
