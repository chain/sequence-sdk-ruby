describe 'accounts' do
  describe '#create' do
    context 'when :id is provided' do
      it 'creates an account with that ID' do
        key = create_key
        id = create_id('alice')

        result = chain.accounts.create(id: id, keys: [key])

        expect(result.id).to eq(id)
      end
    end
  end
end
