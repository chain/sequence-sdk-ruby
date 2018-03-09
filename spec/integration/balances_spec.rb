# frozen_string_literal: true

describe '#balances' do
  describe '#query' do
    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.balances.query(alias: 'bad')
        }.to raise_error(ArgumentError)
      end
    end

    context 'with filter for asset and account' do
      it 'returns the balance' do
        alice = create_account('alice')
        usd = create_asset('usd')
        issue(100, usd, alice)
        filter = "asset_alias='#{usd.alias}' AND account_alias='#{alice.alias}'"

        sum = chain.balances.query(
          filter: filter,
          sum_by: ['asset_alias'],
        ).first

        expect(sum.amount).to eq 100
        expect(sum.sum_by).to eq('asset_alias' => usd.alias)
      end
    end

    context 'with filter and params for asset and account' do
      it 'returns the balance' do
        alice = create_account('alice')
        usd = create_asset('usd')
        issue(100, usd, alice)

        sum = chain.balances.query(
          filter: 'asset_alias=$1 AND account_alias=$2',
          filter_params: [usd.alias, alice.alias],
          sum_by: ['asset_alias'],
        ).first

        expect(sum.amount).to eq 100
        expect(sum.sum_by).to eq('asset_alias' => usd.alias)
      end
    end
  end
end
