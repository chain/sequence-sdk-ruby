# frozen_string_literal: true

describe Sequence::Session do
  describe '#request' do
    it 'makes requests against ledger API using refresh method' do
      chain.dev_utils.reset

      result = chain.session.request('/stats')

      expect(result['flavor_count']).to eq(0)
      expect(result['account_count']).to eq(0)
      expect(result['tx_count']).to eq(0)
    end
  end
end
