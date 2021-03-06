require_relative '../spec_helper'

silent { load 'bin/credy' }

describe Credy::CLI do

  before :all do
    @stdout = $stdout
    $stdout = StringIO.new
  end

  describe 'generate' do

    it 'works without options' do
      Credy::CreditCard.should_receive(:generate).with({})
      r = Credy::CLI.start ['generate']
    end

    it '--country' do 
      Credy::CreditCard.should_receive(:generate).with(country: 'au').twice
      Credy::CLI.start ['generate', '--country', 'au']
      Credy::CLI.start ['generate', '-c', 'au']
    end

    it '--type' do 
      Credy::CreditCard.should_receive(:generate).with(type: 'visa').twice
      Credy::CLI.start ['generate', '--type', 'visa']
      Credy::CLI.start ['generate', '-t', 'visa']
    end

    it '--number' do
      Credy::CreditCard.should_receive(:generate).exactly(20).and_return({number: '50076645747856835'})
      Credy::CLI.start ['generate', '--number', 10]
      Credy::CLI.start ['generate', '-n', 10]
    end

    describe 'result' do

      before :all do
        $stdout = @stdout
      end

      it 'stops if no number is found' do
        Credy::CreditCard.should_receive(:generate).once.and_return(nil)
        STDOUT.should_receive(:puts).with('No rule found for those criteria.').once
        Credy::CLI.start ['generate', '-n', 10]
      end

      describe '--details' do
        before do
          number = {number: '50076645747856835', type: 'visa', country: 'au'}
          Credy::CreditCard.should_receive(:generate).any_number_of_times.and_return number
        end

        it 'only returns the number' do
          STDOUT.should_receive(:puts).with('50076645747856835').once
          Credy::CLI.start ['generate']
        end

        it 'accepts to return more details' do
          STDOUT.should_receive(:puts).with('50076645747856835 (visa, au)').twice
          Credy::CLI.start ['generate', '--details']
          Credy::CLI.start ['generate', '-d']
        end
      end

    end

  end

  describe 'infos' do

    it 'calls the infos function' do
      Credy::CreditCard.should_receive(:infos).with '5108756163954799'
      Credy::CLI.start ['infos', '5108756163954799']
    end

    describe 'result' do
      before :all do
        $stdout = @stdout
      end

      it 'shows error if nothing found' do
        Credy::CreditCard.should_receive(:infos).and_return nil
        STDOUT.should_receive(:puts).with 'No information available for this number.'
        Credy::CLI.start ['infos', '5108756163954799']
      end

      it 'shows the card informations' do
        number = {number: '50076645747856835', type: 'visa', country: 'au'}
        Credy::CreditCard.should_receive(:infos).at_least(1).times.and_return number
        STDOUT.should_receive(:puts).with 'Type: visa'
        STDOUT.should_receive(:puts).with 'Country: au'
        STDOUT.should_receive(:puts).with 'Valid'
        Credy::CLI.start ['infos', '50076645747856835']
      end
    end

  end

  describe 'validate' do
    it 'calls the validate function' do
      Credy::CreditCard.should_receive(:validate).with('5108756163954799').and_return({valid: false, details: {}})
      Credy::CLI.start ['validate', '5108756163954799']
    end

    describe 'result' do
      before :all do
        $stdout = @stdout
      end

      it 'shows card validity and details' do
        validity = { valid: true, details: { luhn: true, type: true} }
        Credy::CreditCard.should_receive(:validate).and_return validity
        STDOUT.should_receive(:puts).with 'This number is valid.'
        STDOUT.should_receive(:puts).with '(luhn: v, type: v)'
        Credy::CLI.start ['validate', '50076645747856835']
      end

       it 'shows card validity and details for invalid number' do
        validity = { valid: false, details: { luhn: false, type: false} }
        Credy::CreditCard.should_receive(:validate).and_return validity
        STDOUT.should_receive(:puts).with 'This number is not valid.'
        STDOUT.should_receive(:puts).with '(luhn: x, type: x)'
        Credy::CLI.start ['validate', '5108756163954799']
      end

    end
  end

end