use starknet::ContractAddress;

/// @dev Trait defining functions that are to be implemented by the contract
#[starknet::interface]
trait IERC20<T> {
    /// @dev Function that returns name of token
    fn name(self: @T) -> felt252;

    /// @dev Function that returns symbol of token
    fn symbol(self: @T) -> felt252;

    /// @dev Function that returns decimal of token
    fn decimals(self: @T) -> u8;

    /// @dev Function that returns total supply of token
    fn total_supply(self: @T) -> u256;

    // @dev OZ standard
    fn totalSupply(self: @T) -> u256;

    /// @dev Function to get balance of an account
    fn balance_of(self: @T, account: ContractAddress) -> u256;

    /// @dev OZ standard
    fn balanceOf(self: @T, account: ContractAddress) -> u256;

    ///@dev Function to view allowance for an account
    fn allowance(self: @T, owner: ContractAddress, spender: ContractAddress) -> u256;

    /// @dev Function to approve transactions
    fn approve(ref self: T, spender: ContractAddress, amount: u256);

    /// @dev to transfer tokens
    fn transfer(ref self: T, receiver: ContractAddress, amount: u256);

    /// @dev Function to transfer on behalf of owner
    fn transfer_from(ref self: T, sender: ContractAddress, receiver: ContractAddress, amount: u256);

    /// @dev OZ standard
    fn transferFrom(ref self: T, sender: ContractAddress, receiver: ContractAddress, amount: u256);

    /// @dev Function to mint tokens
    fn mint(ref self: T, to: ContractAddress, amount: u256);

    /// @dev Function to burn token
    fn burn(ref self: T, from: ContractAddress, amount: u256);
}


#[starknet::contract]
mod ERC20 {
    use super::IERC20;
    use starknet::get_caller_address;
    use starknet::{ContractAddress, get_contract_address};
    use starknet::contract_address_const;
    use starknet::Zeroable;
    use integer::BoundedU256;

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimal: u8,
        total_supply: u256, // how do I add the decimal to total supply
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        sender: ContractAddress,
        receiver: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        receiver: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _name: felt252, _symbol: felt252, _decimal: u8, ) {
        let _owner: ContractAddress = get_caller_address();

        self.name.write(_name);
        self.symbol.write(_symbol);
        self.decimal.write(_decimal);
        self.owner.write(_owner);
    }

    // approve, transfer, transferFrom, increaseAllowance, decreaseAllowance, burn, mint 

    #[external(v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        ////////////////////////////////////////////////////
        //              IMMUTABLE FUNCTIONS               //
        ////////////////////////////////////////////////////

        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }


        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }


        fn decimals(self: @ContractState) -> u8 {
            self.decimal.read()
        }


        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        // OZ standard
        fn totalSupply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        // OZ standard
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }


        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowances.read((owner, spender))
        }


        ////////////////////////////////////////////////////////////////////
        //                     MUTABLE   FUNCTIONS                        //
        ////////////////////////////////////////////////////////////////////
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            let _owner: ContractAddress = get_caller_address();
            self._approve(_owner, spender, amount);
        }


        fn transfer(ref self: ContractState, receiver: ContractAddress, amount: u256) {
            let sender: ContractAddress = get_caller_address();
            assert(!receiver.is_zero(), 'Zero address');
            self._update(sender, receiver, amount);
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            receiver: ContractAddress,
            amount: u256
        ) {
            self._spend_allowance(sender, receiver, amount);
            self._update(sender, receiver, amount);
        }

        /// OZ standard
        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            receiver: ContractAddress,
            amount: u256
        ) {
            self._spend_allowance(sender, receiver, amount);
            self._update(sender, receiver, amount);
        }


        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            let caller: ContractAddress = get_caller_address();
            let _owner: ContractAddress = self.owner.read();
            assert(caller == _owner, 'Unauthorized caller');
            self._mint(to, amount);
        }


        fn burn(ref self: ContractState, from: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            let _owner = self.owner.read();
            assert(caller == _owner, 'Unauthorized caller');
            self._burn(from, amount);
        }
    }


    //////////////////////////////////////////////////////////////////////////
    //                          HELPER FUNCTIONS                            //
    //////////////////////////////////////////////////////////////////////////

    /// @dev Implementation trait to hold internal functions
    #[generate_trait]
    impl InternalImpl of InternalTrait {

        fn _mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            assert(!to.is_zero(), 'ERC20: Mint to 0');
            self._update(Zeroable::zero(), to, amount);
        }

        fn _burn(ref self: ContractState, from: ContractAddress, amount: u256) {
            assert(!from.is_zero(), 'ERC20: burn from 0');
            self._update(from, Zeroable::zero(), amount);
        }


        fn _approve(
            ref self: ContractState, owner_: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner_.is_zero(), 'ERC20: Approve from 0');
            assert(!spender.is_zero(), 'ERC20: Approve to 0');
            self.allowances.write((owner_, spender), amount);

            self.emit(Approval { owner: owner_, receiver: spender, amount });
        }


        fn _update(
            ref self: ContractState,
            sender: ContractAddress,
            receiver: ContractAddress,
            amount: u256
        ) {
            if (sender.is_zero()) {
                self.total_supply.write(self.total_supply.read() + amount);
            } else {
                self.balances.write(sender, (self.balances.read(sender) - amount));
            }

            if (receiver.is_zero()) {
                self.total_supply.write(self.total_supply.read() - amount);
            } else {
                self.balances.write(receiver, (self.balances.read(receiver) + amount));
            }

            self.emit(Transfer { sender, receiver, amount });
        }


        fn _spend_allowance(
            ref self: ContractState, owner_: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            let current_allowance: u256 = self.allowances.read((owner_, spender));
            let is_unlimited_allowance: bool = current_allowance > BoundedU256::max();
            
            if !is_unlimited_allowance {
                self._approve(owner_, spender, current_allowance - amount);
            }
        }
    }
}