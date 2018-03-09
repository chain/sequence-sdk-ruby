# frozen_string_literal: true

describe Sequence::Action do
  describe '#snapshot' do
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
      expect(JSON.parse(json)['snapshot']).to eq ({
        'action_tags' => action_tags,
        'destination_account_tags' => destination_account_tags,
        'flavor_tags' => flavor_tags,
        'source_account_tags' => source_account_tags,
        'token_tags' => token_tags,
      })
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
