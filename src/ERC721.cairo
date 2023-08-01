use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<T> {
    fn get_name(self: @T) -> felt252;
    fn get_symbol(self: @T) -> felt252;
    fn balance_of(self: @T, owner: ContractAddress) -> u128;
    fn owner_of(self: @T, token_id: u128) -> ContractAddress;
    fn is_approved_for_all(self: @T, owner: ContractAddress, operator: ContractAddress) -> bool;
    fn transfer_from(ref self: T, from: ContractAddress, to: ContractAddress, token_id: u128);
    fn approve(ref self: T, to: ContractAddress, token_id: u128);
    fn set_approval_for_all(ref self: T, operator: ContractAddress, approved: bool);
    fn get_approved(ref self: T, token_id: u128) -> ContractAddress;
    fn safe_transfer_from(ref self: T, from: ContractAddress, to: ContractAddress, token_id: u128);

}

#[starknet::contract]
mod ERC721 {
    use starknet::{ContractAddress, get_contract_address};
    use starknet::get_caller_address;
    use starknet::Zeroable;
    use starknet::contract_address_const;
    use super::IERC721;
    
    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        owners: LegacyMap::<u128, ContractAddress>,
        balances: LegacyMap::<ContractAddress, u128>,
        token_approvals: LegacyMap::<u128, ContractAddress>,
        operator_approvals: LegacyMap::<(ContractAddress, ContractAddress), bool>,
        Owner: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Approval: Approval,
        Transfer: Transfer,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u128
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        token_id: u128
    }

    #[constructor]
    fn constructor(ref self: ContractState, _name: felt252, _symbol: felt252) {
        let owner: ContractAddress = get_caller_address();
        self.name.write(_name);
        self.symbol.write(_symbol);

        self.Owner.write(owner);
    }

    #[external(v0)]
    impl IERC721Trait of super::IERC721<ContractState> {

          /////////////////////////////////////////////////////////
         //              IMMUTABLE FUNCTIONS                   //
        ///////////////////////////////////////////////////////

        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn balance_of(self: @ContractState, owner: ContractAddress) -> u128 {
            self.balances.read(owner)
        }

        fn owner_of(self: @ContractState, token_id: u128) -> ContractAddress {
            self.owners.read(token_id)
        }

        // Returns if the 'operator' is allowed to manage all of the assets of 'owner'
        fn is_approved_for_all(self: @ContractState, owner: ContractAddress, operator: ContractAddress) -> bool {
            self.operator_approvals.read((owner, operator))
        }

          ///////////////////////////////////////////////////////
         //              MUTABLE FUNCTIONS                    //
        //////////////////////////////////////////////////////

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u128) {
            let owner: ContractAddress = self.owner_of(token_id);
            let caller: ContractAddress = get_caller_address();
            assert(to != owner, 'Invalid receiver');
            assert(caller == self.Owner.read() && self.is_approved_for_all(owner, to), 'ERC721 Invalid Approver');

            self._approve(to, token_id);
        }


        fn set_approval_for_all(ref self: ContractState, operator: ContractAddress, approved: bool) {
            let caller: ContractAddress = get_caller_address();
            self._set_approval_for_all(caller, operator, approve);
        }


        fn get_approved(ref self: ContractState, token_id: u128) -> ContractAddress {
            self._require_minted(token_id);
            self.token_approvals.read(token_id)
        }

        fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u128) {
            let caller: ContractAddress = get_caller_address();
            assert(self._is_approved_or_owner(caller, token_id), 'ERC721 Insufficient Approval');
            self._transfer(from, to, token_id);
        }


        fn safe_transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u128) {
            self._safe_transfer_from(from, to, token_id);
        }

    }

      //////////////////////////////////////////////////////////
     //              HELPER FUNCTIONS                        //
    //////////////////////////////////////////////////////////
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        
    }

}