# frozen_string_literal: true

describe Sequence::Session do
  describe '#new' do
    context 'with valid options' do
      it 'instantiates the session' do
        session = chain.session

        expect(session.instance_variable_get(:@team_name)).to eq('team')
        api = session.instance_variable_get(:@api)
        expect(api.instance_variable_get(:@base_url).to_s)
          .to eq('https://chain.localhost:1999')
      end
    end
  end

  describe '#request' do
    it 'makes requests against ledger API' do
      chain.dev_utils.reset

      result = chain.session.request('/stats')

      expect(result['flavor_count']).to eq(0)
      expect(result['account_count']).to eq(0)
      expect(result['tx_count']).to eq(0)
    end

    context 'when addr changes between refreshes' do
      it 'uses the new addr on subsequent requests' do
        ttl_seconds = 0
        hello = instance_double('Sequence::Hello')
        allow(Sequence::Hello).to receive(:new).and_return(hello)
        allow(hello).to receive(:call)
          .and_return(['team', 'chain.localhost:1999', ttl_seconds])

        session = Sequence::Session.new(
          credential: ENV['SEQCRED'],
          ledger_name: ENV.fetch('LEDGER_NAME', 'test'),
        )
        api = session.instance_variable_get(:@api)
        expect(api.instance_variable_get(:@base_url).to_s)
          .to eq('https://chain.localhost:1999')

        allow(hello).to receive(:call)
          .and_return(['team', 'changed.localhost:1999', ttl_seconds])

        session.request('/stats') # deadline of 0 reached, refresh in thread
        sleep 1 # wait for thread to finish

        api = session.instance_variable_get(:@api)
        expect(api.instance_variable_get(:@base_url).to_s)
          .to eq('https://changed.localhost:1999')
      end
    end
  end

  context 'when hello errors during a refresh' do
    it 'continues using the previous addr' do
      ttl_seconds = 0
      hello = instance_double('Sequence::Hello')
      allow(Sequence::Hello).to receive(:new).and_return(hello)
      allow(hello).to receive(:call)
        .and_return(['team', 'chain.localhost:1999', ttl_seconds])

      session = Sequence::Session.new(
        credential: ENV['SEQCRED'],
        ledger_name: ENV.fetch('LEDGER_NAME', 'test'),
      )
      api = session.instance_variable_get(:@api)
      expect(api.instance_variable_get(:@base_url).to_s)
        .to eq('https://chain.localhost:1999')

      allow(hello).to receive(:call).and_raise('error')

      api = session.instance_variable_get(:@api)
      expect(api.instance_variable_get(:@base_url).to_s)
        .to eq('https://chain.localhost:1999')
    end
  end
end
