describe 'contracts' do
  describe '#query' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.contracts.query(not: 'an-option')
        }.to raise_error(ArgumentError)
      end
    end

    it 'filters by account' do
      gold = create_asset('gold')
      alice = create_account('alice')
      tx1 = issue(1, gold, alice)

      got = chain.contracts.query(
        filter: 'account_alias=$1',
        filter_params: [alice.alias],
      ).all

      expect(got.map(&:id)).to eq(tx1.contracts.map(&:id))
    end

    it 'filters by asset' do
      gold = create_asset('gold')
      alice = create_account('alice')
      bob = create_account('bob')
      tx1 = issue(1, gold, alice)
      tx2 = issue(2, gold, bob)
      got = chain.contracts.query(
        filter: 'asset_alias=$1',
        filter_params: [gold.alias],
      ).all

      expect(got.map(&:id)).to eq(
        [
          tx2.contracts.first.id,
          tx1.contracts.first.id,
        ],
      )
    end
  end
end
