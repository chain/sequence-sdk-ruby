describe Sequence::Action::ClientModule do
  describe '#list' do
    context 'with :size, :cursor' do
      it 'paginates results with cursor' do
        ref_data = create_refdata('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        3.times do
          issue_flavor(1, gold, alice, reference_data: ref_data)
        end

        first_page = chain.actions.list(
          filter: "reference_data.test='#{ref_data['test']}'",
        ).page(size: 2)

        expect(first_page).to be_a(Sequence::Page)
        expect(first_page.items.size).to eq(2)

        cursor = first_page.cursor
        second_page = chain.actions.list.page(cursor: cursor)

        expect(second_page.items.size).to eq(1)
      end
    end
  end
end
