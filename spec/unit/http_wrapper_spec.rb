# frozen_string_literal: true

require 'timeout'

describe Sequence::HttpWrapper do
  describe '#post' do
    it 'retries on network timeout error' do
      wrapper = described_class.new('http://example.com', 'macaroon')
      allow(Net::HTTP::Post).to receive(:new).and_raise(Net::OpenTimeout)

      expect {
        Timeout.timeout(3) do # 3 seconds
          wrapper.post('request_id', '/path', {})
        end
      }.to raise_error(Timeout::Error)

      expect(Net::HTTP::Post).to have_received(:new)
        .at_least(5)
        .times
    end
  end
end
