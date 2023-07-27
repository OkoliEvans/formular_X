#[starknet::contract]
mod ERC20 {

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
    #[derive( Drop, starknet::Event)]
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

    // approve, transfer, transferFrom, increaseAllowance, decreaseAllowance, burn, mint 
    // #[generate_trait]
    #[external(V0)]
    fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
        let sender: ContractAddress = get_caller_address();

        assert(!spender == is_zero(), 'Zero address');
        assert(amount < balances::read(spender), 'Insufficient amount');

        _approve(sender, spender, amount);
    }

    fn transfer(ref self: ContractState, receiver: ContractAddress, amount: u256) {
        let sender: ContractAddress = get_caller_address();

        assert(!spender == is_zero(), 'Zero address');
        assert(amount < balances::read(spender), 'Insufficient amount');
    }

}

