# frozen_string_literal: true

describe 'actions' do
  describe '#list' do
    context '#page with :size, :cursor' do
      it 'paginates results with cursor' do
        ref_data = create_refdata('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        3.times do
          issue_flavor(1, gold, alice, reference_data: ref_data)
        end

        page1 = chain.actions.list(
          filter: "reference_data.test='#{ref_data['test']}'",
        ).page(size: 2)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)

        cursor = page1.cursor
        page2 = chain.actions.list.page(cursor: cursor)

        expect(page2.items.size).to eq(1)
      end
    end

    context '#page#each' do
      it 'yields the items in the page to the block' do
        ref_data = create_refdata('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        issue_flavor(1, gold, alice, reference_data: ref_data)
        issue_flavor(1, gold, alice, reference_data: ref_data)

        chain.actions.list(
          filter: "reference_data.test='#{ref_data['test']}'",
        ).page.each do |action|
          expect(action).to be_a(Sequence::Action)
          expect(action.amount).to eq(1)
        end
      end
    end

    context '#all#each' do
      it 'iterates through the result set' do
        ref_data = create_refdata('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        3.times do
          issue_flavor(1, gold, alice, reference_data: ref_data)
        end

        results = []
        chain.actions.list(
          filter: "reference_data.test='#{ref_data['test']}'",
        ).all.each do |x|
          results << x
        end

        expect(results.size).to eq(3)
      end
    end
  end

  describe '#sum' do
    context '#page with :size, :cursor, :group_by' do
      it 'paginates results' do
        ref_data = create_refdata('test')
        alice = create_account('alice')
        bob = create_account('bob')
        carol = create_account('carol')
        gold = create_flavor('gold')
        issue_flavor(1, gold, alice, reference_data: ref_data)
        issue_flavor(1, gold, bob, reference_data: ref_data)
        issue_flavor(1, gold, carol, reference_data: ref_data)

        page1 = chain.actions.sum(
          filter: "reference_data.test='#{ref_data['test']}'",
          group_by: ['destination_account_id'],
        ).page(size: 2)

        expect(page1).to be_a(Sequence::Page)
        expect(page1.items.size).to eq(2)
        expect(page1.last_page).to eq(false)

        page2 = chain.actions.sum.page(cursor: page1.cursor)

        expect(page2.items.size).to eq(1)
        expect(page2.last_page).to eq(true)
      end
    end

    context '#page#each' do
      it 'yields the items in the page to the block' do
        ref_data = create_refdata('test')
        alice = create_account('alice')
        gold = create_flavor('gold')
        issue_flavor(1, gold, alice, reference_data: ref_data)
        issue_flavor(1, gold, alice, reference_data: ref_data)

        chain.actions.sum(
          filter: 'reference_data.test=$1',
          filter_params: [ref_data['test']],
          group_by: ['destination_account_id'],
        ).page.each do |action|
          expect(action).to be_a(Sequence::Action)
          expect(action.amount).to eq(2)
        end
      end
    end

    context 'with :group_by, using .all' do
      it 'iterates through the result set' do
        ref_data = create_refdata('test')
        alice = create_account('alice')
        bob = create_account('bob')
        gold = create_flavor('gold')
        issue_flavor(1, gold, alice, reference_data: ref_data)
        issue_flavor(1, gold, bob, reference_data: ref_data)

        results = []
        chain.actions.sum(
          filter: "reference_data.test='#{ref_data['test']}'",
          group_by: ['destination_account_id'],
        ).all.each do |x|
          results << x
        end

        expect(results.size).to eq(2)
      end
    end
  end
end
