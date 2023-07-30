use starknet::ContractAddress;

/// @dev Trait defining functions that are to be implemented by the contract
#[starknet::interface]
trait ERC20Trait<T> {
    /// @dev Function that returns name of token
    fn get_name(self: @T) -> felt252;

    /// @dev Function that returns symbol of token
    fn get_symbol(self: @T) -> felt252;

    /// @dev Function that returns decimal of token
    fn get_decimal(self: @T) -> u256;

    /// @dev Function that returns total supply of token
    fn get_total_supply(self: @T) -> u256;

    /// @dev Function to get balance of an account
    fn get_balance(self: @T, account: ContractAddress) -> u256;

    ///@dev Function to view allowance for an account
    fn get_allowance(self: @T, owner: ContractAddress, spender: ContractAddress) -> u256;

    /// @dev Function to approve transactions
    fn approve(ref self: T, spender: ContractAddress, amount: u256);

    /// @dev to transfer tokens
    fn transfer(ref self: T, receiver: ContractAddress, amount: u256);

    /// @dev Function to transfer on behalf of owner
    fn transferFrom(ref self: T, sender: ContractAddress, receiver: ContractAddress, amount: u256);

    /// @dev Function to mint tokens
    fn mint(ref self: T, to: ContractAddress, amount: u256);

    /// @dev Function to increase allowances
    fn increase_allowance(ref self: T, spender: ContractAddress, amount: u256);

    /// @dev Function to decrease allowances
    fn decrease_allowance(ref self: T, spender: ContractAddress, amount: u256);

    /// @dev Function to burn token
    fn burn(ref self: T, from: ContractAddress, amount: u256);
}


#[starknet::contract]
mod ERC20 {
    // use ERC20::interface::ERC20Trait;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::Zeroable;

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimal: u256,
        total_supply: u256,
        balances: LegacyMap::<ContractAddress, u256>,
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,
        Owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Mint: Mint,
        Approve: Approve,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        sender: ContractAddress,
        receiver: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Mint {
        receiver: ContractAddress,
        amount: u256,
    }


    #[derive(Drop, starknet::Event)]
    struct Approve {
        owner: ContractAddress,
        receiver: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: felt252, symbol: felt252, decimal: u256, initial_supply: u256
    ) {
        let owner: ContractAddress = get_caller_address();

        self.name.write(name);
        self.symbol.write(symbol);
        self.decimal.write(decimal);
        self.total_supply.write(initial_supply);
        self.Owner.write(owner);
    }

    // approve, transfer, transferFrom, increaseAllowance, decreaseAllowance, burn, mint 

    #[external(v0)]
    impl ERC20Impl of super::ERC20Trait<ContractState> {
        ////////////////////////////////////////////////////
        //  //  //      IMMUTABLE FUNCTIONS         // // //
        ///////////////////////////////////////////////////
        fn get_name(self: @ContractState) -> felt252 {
            self.name.read()
        }


        fn get_symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }


        fn get_decimal(self: @ContractState) -> u256 {
            self.decimal.read()
        }


        fn get_total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }


        fn get_balance(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }


        fn get_allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowances.read((owner, spender))
        }


        //////////////////////////////////////////////////////////////////////
        //   // //            MUTABLE   FUNCTIONS                   //  //  //
        /////////////////////////////////////////////////////////////////////
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            let sender: ContractAddress = get_caller_address();

            assert(spender != is_zero(), 'Zero address');
            assert(amount <= self.balances.read(sender), 'Insufficient amount');

            self._approve(sender, spender, amount);
        }


        fn transfer(ref self: ContractState, receiver: ContractAddress, amount: u256) {
            let sender: ContractAddress = get_caller_address();

            assert(receiver != is_zero(), 'Zero address');
            assert(amount < self.balances.read(sender), 'Insufficient amount');

            self._update(sender, receiver, amount);
        }

        fn transferFrom(ref self: ContractState, sender: ContractAddress, receiver: ContractAddress, amount: u256){
            let current_allowance = self.allowances.read((sender, receiver));
            assert(sender != is_zero(), 'Zero address');
            assert(receiver != is_zero(), 'Zero address');
            assert(current_allowance > amount, 'Insufficient allowance');

            self._approve(sender, receiver, current_allowance - amount);
            self._update(sender, receiver, amount);
        }


        fn increase_allowance(ref self: ContractState, spender: ContractAddress, amount: u256) {
            let owner: ContractAddress = get_caller_address();

            
        }


        fn decrease_allowance(ref self: ContractState, spender: ContractAddress, amount: u256) {

        }



        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) {
            let caller: ContractAddress = get_caller_address();
            let owner: ContractAddress = self.Owner.read();
            assert(to != is_zero(), 'Zero Address');
            assert(caller == owner, 'Unauthorized caller');

            self._update(caller, to, amount);
        }


        fn burn(ref self: ContractState, from: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            let owner = self.Owner.read();
            let caller_bal: u256 = self.balances.read(from);

            assert(caller == owner, 'Unauthorized caller');
            assert(caller_bal > amount, 'Insufficient balance');
            self._update(from, zero(), amount);
        }


    }

    /// @dev Implementation trait to hold internal functions
    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _approve(
            ref self: ContractState, sender: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            // let mut initial_allowance: u256 = self.allowances.read((sender, spender));
            self.allowances.write((self.allowances.read((sender, spender)) + amount));

            self.emit(Approve { owner: sender, receiver: spender, amount: amount });
        }


        fn _update(
            ref self: ContractState,
            sender: ContractAddress,
            receiver: ContractAddress,
            amount: u256
        ) {
            if (sender == is_zero()) {
                self.total_supply.write(self.total_supply.read() + amount);
            } else {
                self.balances.write(sender, (self.balances.read(sender) - amount));
            }

            if (receiver == is_zero()) {
                self.total_supply.write(self.total_supply.read() - amount);
            } else {
                self.balances.write(sender, (self.balances.read(receiver) + amount));
            }

            self.emit(Transfer { sender: sender, receiver: receiver, amount: amount });
        }
    }
}

