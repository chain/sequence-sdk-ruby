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
        }.to raise_error(
          ArgumentError,
          ':key_ids or :keys (but not both) must be provided',
        )
      end
    end

    context 'when :key_ids are empty' do
      it 'raises argument error' do
        expect {
          chain.flavors.create(key_ids: [])
        }.to raise_error(
          ArgumentError,
          ':key_ids or :keys (but not both) must be provided',
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
end
