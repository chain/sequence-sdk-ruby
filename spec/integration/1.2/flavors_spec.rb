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

    context 'when :keys are missing' do
      it 'raises argument error' do
        expect {
          chain.flavors.create
        }.to raise_error(ArgumentError, ':keys must be provided')
      end
    end

    context 'when :keys are empty' do
      it 'raises argument error' do
        expect {
          chain.flavors.create(keys: [])
        }.to raise_error(ArgumentError, ':keys must be provided')
      end
    end

    context 'when :keys are provided' do
      it 'creates a flavor' do
        key = create_key

        result = chain.flavors.create(keys: [key])

        expect(result.id).not_to be_empty
      end
    end

    context 'when :keys and :id are provided' do
      it 'creates a flavor with user specified id' do
        key = create_key
        id = create_id('user-specified')

        result = chain.flavors.create(id: id, keys: [key])

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
        flavor = chain.flavors.create(keys: [key], tags: { x: 'foo' })
        other = chain.flavors.create(keys: [key], tags: { y: 'bar' })

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
        flavor = chain.flavors.create(keys: [key])

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
  end
end
