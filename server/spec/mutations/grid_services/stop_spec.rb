describe GridServices::Stop do
  let(:grid) { Grid.create!(name: 'test-grid') }
  let(:service) { GridService.create!(grid: grid, name: 'redis', image_name: 'redis:2.8') }
  let(:subject) { described_class.new(grid_service: service) }

  describe '#run' do
    it 'sets service state to stopped' do
      expect{
        subject.run!
      }.to change{service.reload.state}.to('stopped')
    end

    context 'with a service instance' do
      let(:node) { nil }
      let!(:service_instance) { GridServiceInstance.create!(grid_service: service, instance_number: 1, host_node: node ) }

      it 'stops the service instance' do
        expect{
          subject.run!
        }.to change{service_instance.reload.desired_state}.to('stopped')
      end

      context 'with a host node' do
        let!(:node) { grid.create_node!('test-node') }
        let(:rpc_client) { instance_double(RpcClient) }

        before do
          allow(node).to receive(:rpc_client).and_return(rpc_client)
        end

        it 'notifies the host node' do
          expect(rpc_client).to receive(:notify).with('/service_pods/notify_update', 'stop')

          outcome = subject.run!
        end
      end
    end

    it 'fails on errors' do
      expect(subject).to receive(:stop_service_instances).and_raise(StandardError.new('test'))

      expect(outcome = subject.run).to_not be_success
      expect(outcome.errors.message).to eq 'stop' => 'test'
      expect(outcome.errors.symbolic).to eq 'stop' => :error
    end
  end
end
