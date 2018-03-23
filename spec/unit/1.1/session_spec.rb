# frozen_string_literal: true

describe Sequence::Session do
  describe '#request' do
    it 'makes requests against ledger API using refresh method' do
      chain.dev_utils.reset

      result = chain.session.request('/stats')

      expect(result).to eq(
        'asset_count' => 0,
        'account_count' => 0,
        'flavor_count' => 0,
        'tx_count' => 0,
      )
    end
  end
end
