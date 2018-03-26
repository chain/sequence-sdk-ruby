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

        query = chain.accounts.query(filter: "id='#{account.id}'").first
        expect(query.tags).to eq('x' => 'baz')
        query = chain.accounts.query(filter: "id='#{other.id}'").first
        expect(query.tags).to eq('y' => 'bar')
      end
    end
  end

  describe '#query' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.accounts.query(id: 'bad')
        }.to raise_error(ArgumentError)
      end
    end

    context 'with filter' do
      it 'finds the account' do
        account = create_account('alice')

        query = chain.accounts.query(filter: "id='#{account.id}'").first

        expect(query.id).to eq account.id
      end
    end

    context 'with filter parameters' do
      it 'finds the account' do
        key = create_key
        account = chain.accounts.create(
          key_ids: [key.id],
          tags: { type: 'checking' },
        )

        query = chain.accounts.query(
          filter: 'tags.type=$1',
          filter_params: ['checking'],
        ).first

        expect(query.id).to eq account.id
      end
    end

    context 'with :page_size, :after' do
      it 'paginates results reverse chronologically' do
        alice = create_account('alice')
        bob = create_account('bob')

        first_page = chain.accounts.query(page_size: 1).pages.first

        expect(first_page).to be_a(Sequence::Page)
        expect(first_page.items.size).to eq(1)
        expect(first_page.items.first.id).to eq(bob.id)

        second_page = chain.accounts.query(
          after: first_page.next['after'],
        ).pages.first

        expect(second_page.items.first.id).to eq(alice.id)
      end
    end
  end
end
