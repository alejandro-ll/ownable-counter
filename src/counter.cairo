use starknet::ContractAddress;

#[starknet::interface]
pub trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
}

#[starknet::contract]
mod Counter {
    use super::{ ICounter };
    use starknet::{ContractAddress, get_caller_address};
    use core::num::traits::zero::Zero;
    use kill_switch::{ IKillSwitchDispatcher, IKillSwitchDispatcherTrait };
    use ownable::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: IKillSwitchDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[constructor]
    fn constructor(ref self: ContractState, value: u32, kill_switch_address: ContractAddress, initial_owner: ContractAddress) {
        self.counter.write(value);
        self.kill_switch.write(IKillSwitchDispatcher{ contract_address: kill_switch_address });
        self.ownable.initializer(initial_owner);
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased: CounterIncreased,
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        counter: u32
    }

    #[abi(embed_v0)]
    impl Counter of ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            return self.counter.read();
        }
        fn increase_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();
            if (self.kill_switch.read().is_active()){
                self.counter.write(self.counter.read() + 1);
                self.emit(CounterIncreased { counter: self.counter.read() });

            }
        }
    }
}
