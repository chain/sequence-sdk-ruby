# frozen_string_literal: true

describe Sequence::Action do
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
      destination_account_id: 'destination-account-id-123',
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

  describe '#snapshot' do
    it 'prints the snapshot as nested json' do
      action = described_class.new(
        timestamp: DateTime.now.rfc3339,
        snapshot: {
          'action_tags' => action_tags,
          'destination_account_tags' => destination_account_tags,
          'flavor_tags' => flavor_tags,
          'source_account_tags' => source_account_tags,
          'token_tags' => token_tags,
        },
      )

      json = action.to_json
      expect(JSON.parse(json)['snapshot']).to eq(
        'action_tags' => action_tags,
        'destination_account_tags' => destination_account_tags,
        'flavor_tags' => flavor_tags,
        'source_account_tags' => source_account_tags,
        'token_tags' => token_tags,
      )
    end

    it 'is Hash-like' do
      action = described_class.new(
        snapshot: {
          'action_tags' => action_tags,
          'destination_account_tags' => destination_account_tags,
          'flavor_tags' => flavor_tags,
          'source_account_tags' => source_account_tags,
          'token_tags' => token_tags,
        },
      )

      snapshot = action.snapshot

      expect(snapshot['action_tags']).to eq(action_tags)
      expect(snapshot['destination_account_tags'])
        .to eq(destination_account_tags)
      expect(snapshot['flavor_tags']).to eq(flavor_tags)
      expect(snapshot['source_account_tags']).to eq(source_account_tags)
      expect(snapshot['token_tags']).to eq(token_tags)
    end

    it 'can access tags via dot notation' do
      action = described_class.new(
        snapshot: {
          'action_tags' => action_tags,
          'destination_account_tags' => destination_account_tags,
          'flavor_tags' => flavor_tags,
          'source_account_tags' => source_account_tags,
          'token_tags' => token_tags,
        },
      )

      snapshot = action.snapshot

      expect(snapshot.action_tags).to eq(action_tags)
      expect(snapshot.destination_account_tags)
        .to eq(destination_account_tags)
      expect(snapshot.flavor_tags).to eq(flavor_tags)
      expect(snapshot.source_account_tags).to eq(source_account_tags)
      expect(snapshot.token_tags).to eq(token_tags)
    end
  end

  def action_tags
    { 'due' => 'january-1' }
  end

  def destination_account_tags
    { 'bank' => 'first-republic' }
  end

  def flavor_tags
    { 'mint' => 'san-francisco' }
  end

  def source_account_tags
    { 'bank' => 'td-bank' }
  end

  def token_tags
    { 'currency' => 'usd' }
  end
end
