# frozen_string_literal: true

require_relative '../spec_helper'

describe Sequence::Client do
  describe '#new' do
    context 'when missing :ledger_name and missing :ledger' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when nil :ledger_name and missing :ledger' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo', ledger_name: nil)
        }.to raise_error(ArgumentError)
      end
    end

    context 'when blank :ledger_name and missing :ledger' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo', ledger_name: '')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when nil :ledger and missing :ledger_name' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo', ledger: nil)
        }.to raise_error(ArgumentError)
      end
    end

    context 'when blank :ledger and missing :ledger_name' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo', ledger: '')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when missing :credential' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(ledger_name: 'foo')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when nil :credential' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: nil, ledger_name: 'foo')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when blank :credential' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: '', ledger_name: 'foo')
        }.to raise_error(ArgumentError)
      end
    end
  end
end
