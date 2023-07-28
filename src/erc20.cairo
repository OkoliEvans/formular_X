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
    fn burn(ref self: T, amount: u256);
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
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Mint: Mint,
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

    #[constructor]
    fn constructor(
        ref self: ContractState, name: felt252, symbol: felt252, decimal: u256, initial_supply: u256
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.decimal.write(decimal);
        self.total_supply.write(initial_supply);
    }

    // approve, transfer, transferFrom, increaseAllowance, decreaseAllowance, burn, mint 
    // #[generate_trait]
    #[external(v0)]
    impl ERC20Impl of super::ERC20Trait<ContractState> {

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


        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            let sender: ContractAddress = get_caller_address();

            assert(spender != is_zero(), 'Zero address');
            assert(amount <= self.balances.read(sender), 'Insufficient amount');

            _approve(sender, spender, amount);
        }

        fn transfer(ref self: ContractState, receiver: ContractAddress, amount: u256) {
            let sender: ContractAddress = get_caller_address();

            assert(receiver != is_zero(), 'Zero address');
            assert(amount <= self.balances.read(sender), 'Insufficient amount');

            self.balances.write(sender, (self.balances.read(sender) - amount));
            self.balances.write(sender, (self.balances.read(receiver) + amount));

            self.emit(Transfer { sender: sender, receiver: receiver, amount: amount });
        }



    }
}

