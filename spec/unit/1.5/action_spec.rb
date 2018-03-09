# frozen_string_literal: true

describe Sequence::Action do
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
