# frozen_string_literal: true

describe 'transactions' do
  describe '#issue' do
    context 'for non-existent flavors' do
      it 'raises API error' do
        alice = create_account('alice')

        expect {
          chain.transactions.transact do |b|
            b.issue(
              amount: 100,
              flavor_id: 'unobtanium',
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
              flavor_id: create_id('usd'),
              destination_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id' do
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

    context 'missing :destination_account_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.issue(
              amount: 100,
              flavor_id: create_id('usd'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#transfer' do
    context 'for non-existent flavors' do
      it 'raises API error' do
        alice = create_account('alice')
        bob = create_account('bob')
        usd = create_flavor('usd')
        issue(100, usd, alice)

        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              flavor_id: 'unobtanium',
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
              flavor_id: create_id('usd'),
              source_account_id: create_id('alice'),
              destination_account_id: create_id('bob'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id' do
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

    context 'missing :source_account_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              flavor_id: create_id('usd'),
              destination_account_id: create_id('bob'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :destination_account_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.transfer(
              amount: 100,
              flavor_id: create_id('usd'),
              source_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#retire' do
    context 'for non-existent flavors' do
      it 'raises API error' do
        alice = create_account('alice')
        usd = create_flavor('usd')
        issue(100, usd, alice)

        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 100,
              flavor_id: 'unobtanium',
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
              flavor_id: create_id('usd'),
              source_account_id: create_id('alice'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end

    context 'missing :flavor_id' do
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

    context 'missing :source_account_id' do
      it 'raises argument error' do
        expect {
          chain.transactions.transact do |b|
            b.retire(
              amount: 100,
              flavor_id: create_id('usd'),
            )
          end
        }.to raise_error(ArgumentError)
      end
    end
  end
end
