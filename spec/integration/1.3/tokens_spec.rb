describe 'tokens' do
  describe '#list' do
    context 'with filter for flavor_id' do
      it 'returns list of token groups' do
        alice = create_account('alice')
        cert = create_flavor('stock-certificate')
        issue_flavor(100, cert, alice)

        items = chain.tokens.list(
          filter: "flavor_id='#{cert.id}'",
        )

        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq(cert.id)
        expect(item.flavor_tags).to be_nil
        expect(item.account_id).to eq(alice.id)
        expect(item.account_tags).to be_nil
        expect(item.tags).to be_nil
      end
    end

    context 'with filter for flavor_tags and account_id' do
      it 'returns list of token groups' do
        oakland = create_account('oakland-dealership')
        vin = '5GAKVBKD4FJ211258'
        q5 = chain.flavors.create(
          id: create_id('audi'),
          tags: {
            make: 'Audi',
            model: 'Q5',
            vin: vin,
            year: '2010',
          },
          keys: [create_key],
        )
        issue_flavor(1, q5, oakland)

        items = chain.tokens.list(
          filter: 'flavor_tags.vin=$1 AND account_id=$2',
          filter_params: [vin, oakland.id],
        )

        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 1
        expect(item.flavor_id).to eq(q5.id)
        expect(item.account_id).to eq(oakland.id)
      end
    end
  end

  describe '#sum' do
    context 'with filter for flavor_id' do
      it 'returns sum of tokens' do
        alice = create_account('alice')
        cert = create_flavor('stock-certificate')
        issue_flavor(50, cert, alice)
        issue_flavor(50, cert, alice)

        items = chain.tokens.sum(
          filter: "flavor_id='#{cert.id}'",
        )

        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to be_nil
        expect(item.flavor_tags).to be_nil
        expect(item.account_id).to be_nil
        expect(item.account_tags).to be_nil
        expect(item.tags).to be_nil
      end
    end

    context 'grouped by flavor_id and account_id' do
      it 'returns sum of tokens' do
        alice = create_account('alice')
        cert = create_flavor('stock-certificate')
        issue_flavor(50, cert, alice)
        issue_flavor(50, cert, alice)

        items = chain.tokens.sum(
          filter: "flavor_id='#{cert.id}'",
          group_by: ['flavor_id', 'account_id'],
        )

        expect(items.all.size).to eq 1
        item = items.first
        expect(item.amount).to eq 100
        expect(item.flavor_id).to eq cert.id
        expect(item.account_id).to eq alice.id
      end
    end
  end
end
