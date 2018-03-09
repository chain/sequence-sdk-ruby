# frozen_string_literal: true

describe 'transactions' do
  describe '#issue' do
    context 'for non-existent assets' do
      it 'raises API error' do
        alice = create_account('alice')

        expect {
          chain.transactions.transact do |b|
            b.issue(
              amount: 100,
              asset_alias: 'unobtanium',
              destination_account_id: alice.id,
            )
          end
        }.to raise_error(Sequence::APIError)
      end
    end

    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(not: 'an-option')
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :amount' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(
              asset_alias: create_alias('usd'),
              destination_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id or :asset_{id,alias}' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(
              amount: 100,
              destination_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :destination_account_{id,alias}' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(
              amount: 100,
              asset_alias: create_alias('usd'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#transfer' do
    context 'for non-existent assets' do
      it 'raises API error' do
        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_asset('usd')
        issue(100, usd, alice)

        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              asset_alias: 'unobtanium',
              source_account_id: alice.id,
              destination_account_id: bob.id,
            )
          end
        }.to raise_error(Sequence::APIError)
      end
    end

    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(not: 'an-option')
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :amount' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              asset_alias: create_alias('usd'),
              source_account_id: create_id('alice'),
              destination_account_id: create_id('bob'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id or :asset_{id,alias}' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              source_account_id: create_id('alice'),
              destination_account_id: create_id('bob'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :source_account_{id,alias,contract}' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              asset_alias: create_alias('usd'),
              destination_account_id: create_id('bob'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :destination_account_{id,alias}' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              asset_alias: create_alias('usd'),
              source_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#retire' do
    context 'for non-existent assets' do
      it 'raises API error' do
        alice = create_account('alice')
        usd = create_asset('usd')
        issue(100, usd, alice)

        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 100,
              asset_alias: 'unobtanium',
              source_account_id: alice.id,
            )
          end
        }.to raise_error(Sequence::APIError)
      end
    end

    context 'with invalid option' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(not: 'an-option')
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :amount' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(
              asset_alias: create_alias('usd'),
              source_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id or :asset_{id,alias}' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 100,
              source_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :source_account_{id,alias,contract}' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 100,
              asset_alias: create_alias('usd'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end
  end
end
