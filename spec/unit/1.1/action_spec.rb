# frozen_string_literal: true

describe Sequence::Action do
  describe '#new' do
    it 'translates' do
      # DateTime's to_rfc3339 method uses numeric timezones
      time = '2017-01-01T00:00:00+00:00'
      raw = {
        amount: 100,
        type: 'issue',
        id: 'id-123',
        transaction_id: 'transaction-123',
        timestamp: time,
        asset_id: 'asset-123',
        asset_alias: 'usd',
        asset_tags: {
          'mint' => 'san-francisco',
        },
        source_account_id: 'source-account-id-123',
        source_account_alias: 'alice',
        source_account_tags: {
          'bank' => 'td-bank',
        },
        destination_account_id: 'destination-account-id-123',
        destination_account_alias: 'bob',
        destination_account_tags: {
          'bank' => 'first-republic',
        },
        reference_data: {
          'ride-share-id' => 'ride-share-123',
        },
      }

      result = described_class.new(raw)

      expect(result.timestamp).to eql(Time.parse(time))
      expect(result.to_json).to eql(raw.to_json)
    end
  end
end
