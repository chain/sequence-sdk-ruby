# frozen_string_literal: true

describe Sequence::Query do
  context '#each' do
    it 'makes one network request per page' do
      params = { filter: 'tags.foo=$1', filter_params: 'bar' }
      allow(chain.session).to receive(:request)
        .with('list-accounts', params)
        .and_return(
          'id' => 'foo',
          'key_ids' => ['bar'],
          'quorum' => 1,
          'tags' => {},
        )

      results = []
      chain.accounts.list(params).each do |item|
        results << item
        if results.size == 3
          break
        end
      end

      expect(chain.session).to have_received(:request)
        .with('list-accounts', params)
        .once
    end
  end
end
