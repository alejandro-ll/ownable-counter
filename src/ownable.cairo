use starknet::ContractAddress;

#[starknet::interface]
pub trait IOwnable<TContractState> {
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TContractState);
}

#[starknet::component]
mod OwnableComponent {
    use starknet::{ContractAddress, get_caller_address};
    use core::num::traits::zero::Zero;
    use super::{IOwnable};

    #[storage]
    struct Storage {
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }

    #[embeddable_as(OwnableImpl)]
    impl Ownable<TContractState, +HasComponent<TContractState> of IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }
        fn transfer_ownership(ref self: ComponentState<TContractState>, new_owner: ContractAddress) {
            self.assert_only_owner();
            assert(new_owner.is_zero(), 'New owner is the zero address');
            self._transfer_ownership(new_owner);
        }
        fn renounce_ownership(ref self: ComponentState<TContractState>) {
            self.assert_only_owner();
            self._transfer_ownership(Zero::zero());
        }
    }
    #[generate_trait]
    impl InternalImpl<TContractState, +HasComponent<TContractState>> of InternalTrait<ComponentState<TContractState>> {
        fn initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            self._transfer_ownership(owner);
        }
        fn assert_only_owner(self: @ComponentState<TContractState>) {
            assert(!get_caller_address().is_zero(), 'Caller is the zero address');
            assert(get_caller_address() == self.owner.read(), 'Caller is not the owner');
        }
        fn _transfer_ownership(ref self: ComponentState<TContractState>, new_owner: ContractAddress) {
            self.owner.write(new_owner);
            self.emit(OwnershipTransferred { previous_owner: get_caller_address(), new_owner: new_owner });
        }
    }
}
