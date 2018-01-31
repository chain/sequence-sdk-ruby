describe 'assets' do
  describe '#create' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.assets.create(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :keys are missing' do
      it 'raises argument error' do
        expect {
          chain.assets.create
        }.to raise_error(ArgumentError, ':keys must be provided')
      end
    end

    context 'when :keys are empty' do
      it 'raises argument error' do
        expect {
          chain.assets.create(keys: [])
        }.to raise_error(ArgumentError, ':keys must be provided')
      end
    end

    context 'when :keys are provided' do
      it 'creates an asset' do
        key = create_key

        result = chain.assets.create(keys: [key])

        expect(result.id).not_to be_empty
      end
    end
  end

  describe '#update_tags' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.assets.update_tags(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :id and :alias are missing' do
      it 'raises argument error' do
        expect {
          chain.assets.update_tags(tags: { foo: 'bar' })
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :id is blank' do
      it 'raises argument error' do
        expect {
          chain.assets.update_tags(id: '', tags: { foo: 'bar' })
        }.to raise_error(ArgumentError)
      end
    end

    context 'when :alias is blank' do
      it 'raises argument error' do
        expect {
          chain.assets.update_tags(alias: '', tags: { foo: 'bar' })
        }.to raise_error(ArgumentError)
      end
    end

    context 'with :id' do
      it 'updates tags for asset' do
        key = create_key
        asset = chain.assets.create(keys: [key], tags: { x: 'foo' })
        other = chain.assets.create(keys: [key], tags: { y: 'bar' })

        chain.assets.update_tags(id: asset.id, tags: { x: 'baz' })

        query = chain.assets.query(filter: "id='#{asset.id}'").first
        expect(query.tags).to eq('x' => 'baz')
        query = chain.assets.query(filter: "id='#{other.id}'").first
        expect(query.tags).to eq('y' => 'bar')
      end
    end
  end

  describe '#query' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.assets.query(alias: 'bad')
        }.to raise_error(ArgumentError)
      end
    end

    context 'with filter' do
      it 'finds the asset' do
        key = create_key
        asset = chain.assets.create(keys: [key])

        query = chain.assets.query(filter: "id='#{asset.id}'").first

        expect(query.id).to eq asset.id
      end
    end

    context 'with filter parameters' do
      it 'finds the asset' do
        key = create_key
        asset = chain.assets.create(
          keys: [key],
          tags: { type: 'checking' },
        )

        query = chain.assets.query(
          filter: 'tags.type=$1',
          filter_params: ['checking'],
        ).first

        expect(query.id).to eq asset.id
      end
    end
  end
end
