describe 'keys' do
  describe '#create' do
    context 'when :id is provided' do
      it 'creates a key with that ID' do
        uuid = SecureRandom.uuid

        key = chain.keys.create(id: uuid)

        expect(key.id).to eq(uuid)
      end
    end
  end
end
