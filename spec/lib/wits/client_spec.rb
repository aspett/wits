require 'spec_helper'

describe Wits::Client do

  subject { Wits::Client }

  describe '.client' do
    it 'returns an instance of Faraday::Connection' do
      expect(subject.client).to be_an_instance_of(Faraday::Connection)
    end

    it 'returns @client' do
      expect(subject.client).to eq subject.instance_variable_get(:@client)
    end

    it 'URL is set correctly' do
      expect(subject.client.url_prefix.to_s).to eq 'http://www.electricityinfo.co.nz/'
    end
  end

  describe '.get' do
    it 'delegates to Faraday::Connection' do
      args  = [:blah]
      block = Proc.new {}

      expect(subject.client).to receive(:get).with(args, &block)

      subject.client.get(args, &block)
    end

    errors = %w(
      ConnectionFailed ResourceNotFound TimeoutError ClientError
    )

    errors.each do |error|
      it "Wits::Error::#{error} is raised on Faraday::#{error} error" do
        allow(subject.client).to receive(:get).and_raise(Faraday.const_get(error), 'message')

        expect {
          subject.get
        }.to raise_error(Wits::Error.const_get(error))
      end
    end
  end

  describe '.get_csv' do
    it 'delegates to .get' do
      args  = [:blah]
      block = Proc.new {}
      response = double('reponse', body: 'a' * 300)

      expect(subject).to receive(:get).with(args, &block).and_return(response)

      subject.get_csv(args, &block)
    end

    describe 'raises an Wits::Error::ResourceNotFound error' do
      it 'when the response contains HTML' do
        response = double('reponse', body: '<html></html>')

        expect(subject).to receive(:get).and_return(response)

        expect {
          subject.get_csv
        }.to raise_error Wits::Error::ResourceNotFound
      end

      it 'when the response body length is less than 300 bytes' do
        response = double('reponse', body: 'a' * 299)

        expect(subject).to receive(:get).and_return(response)

        expect {
          subject.get_csv
        }.to raise_error Wits::Error::ResourceNotFound
      end
    end
  end
end
