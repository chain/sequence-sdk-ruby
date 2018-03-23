# frozen_string_literal: true

describe Sequence::Action do
  describe '#new' do
    it 'translates' do
      # DateTime#rfc3339 uses numeric timezones
      time = '2017-01-01T00:00:00+00:00'
      raw = {
        amount: 100,
        type: 'issue',
        id: 'id-123',
        transaction_id: 'transaction-123',
        timestamp: time,
        flavor_id: 'flavor-123',
        snapshot: {
          destination_account_tags: {
            bank: 'first-republic',
          },
          flavor_tags: {
            mint: 'san-francisco',
          },
          source_account_tags: {
            bank: 'td-bank',
          },
        },
        source_account_id: 'source-account-id-123',
        source_account_tags: {
          'bank' => 'td-bank',
        },
        destination_account_id: 'destination-account-id-123',
        destination_account_tags: {
          'bank' => 'first-republic',
        },
      }

      result = described_class.new(raw)

      expect(result.timestamp).to eql(Time.parse(time))
      raw.delete(:timestamp)

      unless result.snapshot.is_a?(Sequence::ResponseObject::Snapshot)
        expect(result.to_h[:snapshot].to_json)
          .to eql(raw.to_h[:snapshot].to_json)
      end
      raw.delete(:snapshot)

      raw.each_key do |key|
        expect(result.to_h[key].to_json).to eql(raw.to_h[key].to_json)
      end
    end
  end
end
