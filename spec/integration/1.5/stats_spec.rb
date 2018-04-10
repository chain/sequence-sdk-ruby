# frozen_string_literal: true

describe 'stats' do
  it 'counts flavors' do
    expect(chain.stats.get).to respond_to(:flavor_count)
  end
end
