# frozen_string_literal: true

describe 'accounts' do
  describe '#create' do
    context 'when :key_ids are missing' do
      it 'raises argument error' do
        expect {
          chain.accounts.create
        }.to raise_error(
          ArgumentError,
          ':key_ids must be provided',
        )
      end
    end

    context 'when :key_ids are empty' do
      it 'raises argument error' do
        expect {
          chain.accounts.create(key_ids: [])
        }.to raise_error(
          ArgumentError,
          ':key_ids must be provided',
        )
      end
    end

    context 'when :key_ids are provided' do
      it 'creates an account' do
        key = create_key

        result = chain.accounts.create(key_ids: [key.id])

        expect(result.id).not_to be_empty
        expect(result.key_ids).to eq([key.id])
      end
    end
  end
end
