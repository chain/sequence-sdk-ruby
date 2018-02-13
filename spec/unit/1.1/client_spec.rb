describe Sequence::Client do
  describe '#new' do
    context 'when nonempty :ledger_name and nonempty :ledger' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo', ledger_name: 'x', ledger: 'y')
        }.to raise_error(ArgumentError)
      end
    end
  end
end
