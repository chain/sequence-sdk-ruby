# frozen_string_literal: true

describe 'transactions' do
  describe '#list' do
    context 'with filter using camelCase/snake_case' do
      it 'lists transactions using snake_case' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice)

        items = chain.tokens.list(
          filter: 'account_id = $1',
          filter_params: [alice.id],
        )
        expect(items.all.size).to eq 1
        expect(items.all.first.amount).to eq 100
        expect(items.all.first.flavor_id).to eq(usd.id)
      end

      it 'fails to list transactions using camelCase' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue_flavor(100, usd, alice)

        expect {
          chain.tokens.list(
            filter: 'accountId = $1',
            filter_params: [alice.id],
          ).all
        }.to raise_error(Sequence::APIError)
      end
    end
  end
end
