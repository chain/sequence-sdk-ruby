describe 'flavors' do
  describe '#list' do
    context 'with filter parameters and :size, :cursor pagination' do
      it 'paginates results' do
        uuid = SecureRandom.uuid
        create_flavor('btc', tags: { foo: uuid })
        create_flavor('eth', tags: { foo: uuid })
        create_flavor('ltc', tags: { foo: uuid })

        page1 = chain.flavors.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).page(size: 2)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)

        cursor = page1.cursor
        page2 = chain.flavors.list.page(cursor: cursor)

        expect(page2.items.size).to eq(1)
      end
    end

    context '#page#each' do
      it 'yields flavors in the page to the block' do
        uuid = SecureRandom.uuid
        btc = create_flavor('btc', tags: { foo: uuid })
        create_flavor('eth')

        chain.flavors.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).page.each do |item|
          expect(item).to be_a(Sequence::Flavor)
          expect(item.id).to eq(btc.id)
        end
      end
    end

    context '#all#each' do
      it 'yields flavors to the block' do
        uuid = SecureRandom.uuid
        create_flavor('btc', tags: { foo: uuid })
        create_flavor('eth', tags: { foo: uuid })

        results = []
        chain.flavors.list(
          filter: 'tags.foo=$1',
          filter_params: [uuid],
        ).all.each do |item|
          expect(item).to be_a(Sequence::Flavor)
          results << item
        end

        expect(results.size).to eq(2)
      end
    end
  end
end
