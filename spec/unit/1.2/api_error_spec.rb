# frozen_string_literal: true

describe Sequence::APIError do
  describe '#new' do
    it 'includes #seq_code' do
      body = { 'seq_code' => 'SEQ008' }
      error = described_class.new(body, nil)

      expect(error.seq_code).to eq('SEQ008')
    end
  end

  describe '#to_s' do
    it 'includes information from API response in error message' do
      body = {
        'detail' => 'deets',
        'message' => 'not found',
        'seq_code' => 'SEQ008',
      }
      response = {
        'Chain-Request-ID' => '1',
      }
      error = described_class.new(body, response)

      result = error.to_s

      expected = 'Code: SEQ008 Message: not found Detail: deets Request-ID: 1'
      expect(result).to eql(expected)
    end
  end
end
