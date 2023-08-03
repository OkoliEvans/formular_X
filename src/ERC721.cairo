// use starknet::ContractAddress;

// #[starknet::interface]
// trait IERC721<T> {
//     fn get_name(self: @T) -> felt252;
//     fn get_symbol(self: @T) -> felt252;
//     fn balance_of(self: @T, owner: ContractAddress) -> u128;
//     fn owner_of(self: @T, token_id: u128) -> ContractAddress;
//     fn is_approved_for_all(self: @T, owner: ContractAddress, operator: ContractAddress) -> bool;
//     fn transfer_from(ref self: T, from: ContractAddress, to: ContractAddress, token_id: u128);
//     fn approve(ref self: T, to: ContractAddress, token_id: u128);
//     fn set_approval_for_all(ref self: T, operator: ContractAddress, approved: bool);
//     fn get_approved(ref self: T, token_id: u128) -> ContractAddress;
//     fn safe_transfer_from(ref self: T, from: ContractAddress, to: ContractAddress, token_id: u128);

// }

#[starknet::contract]
mod ERC721 {
    use starknet::{ContractAddress, get_contract_address};
    use starknet::get_caller_address;
    use starknet::Zeroable;
    use starknet::contract_address_const;
    use starkzepp::src::interface::IERC721;
    
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
        Approval_for_all: Approval_for_all,
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

    #[derive(Drop, starknet::Event)]
    struct Approval_for_all {
        owner: ContractAddress,
        operator: ContractAddress,
        approved: bool
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
            self._set_approval_for_all(caller, operator, approved);
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

        // mint, safemint, burn etc

    }

      //////////////////////////////////////////////////////////
     //              HELPER FUNCTIONS                        //
    //////////////////////////////////////////////////////////
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _approve(ref self: ContractState, _to: ContractAddress, _token_id: u128) {
            self.token_approvals.write(_token_id, _to);
            self.emit(Approval {from: self.owner_of(_token_id), to: _to, token_id: _token_id} );
        }

        fn _set_approval_for_all(ref self: ContractState, _owner: ContractAddress , _operator: ContractAddress, _approved: bool) {
            assert(_owner != _operator, 'ERC721 Invalid Operator');
            self.operator_approvals.write((_owner, _operator), _approved);
            self.emit( Approval_for_all {owner: _owner, operator: _operator, approved: _approved});
        }

        // Reverts if the 'token id' has not been minted yet
        fn _require_minted(self: @ContractState, _token_id: u128) {
            assert(self._exists(_token_id), 'ERC721 Non-existent token');
        }

        // Returns true if token is minted
        fn _exists(self: @ContractState, _token_id: u128) -> bool {
            let token_owner: ContractAddress = self.owner_of(_token_id);
            !token_owner.is_zero()
        }

        // Returns whether 'spender' is allowed to manage 'tokenid'
        fn _is_approved_or_owner(ref self: ContractState, _spender: ContractAddress, _token_id: u128) -> bool {
            let token_owner: ContractAddress = self.owner_of(_token_id);
            _spender == token_owner || self.is_approved_for_all(token_owner, _spender) || self.get_approved(_token_id) == _spender
        } 

        fn _transfer(ref self: ContractState, _from: ContractAddress, _to: ContractAddress, _token_id: u128) {
            let token_owner: ContractAddress = self.owner_of(_token_id);
            assert(token_owner == _from, 'ERC721 Incorrect Owner');
            assert(!_to.is_zero(), 'ERC721 Invalid Receiver');
            // self._before_token_transfer(_from, _to, _token_id, 1); // Is this needed in Cairo?

            delete self.token_approvals.read(_token_id);

        }

    }

}