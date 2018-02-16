describe Sequence::APIError do
  describe '#new' do
    it 'includes deprecated #code and current #seq_code' do
      body = {
        'code' => 'CH008',
        'seq_code' => 'SEQ008',
      }
      error = described_class.new(body, nil)

      expect(error.code).to eq('CH008')
      expect(error.seq_code).to eq('SEQ008')
    end
  end

  describe '#to_s' do
    it 'includes information from API response in error message' do
      body = {
        'code' => 'CH008',
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
