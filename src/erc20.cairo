#[starknet::contract]
mod ERC20 {

    use starknet::get_caller_address;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimal: felt252,
        total_supply: felt252,
        balance: LegacyMap::<ContractAddress, u252>,
    }

    #[event]
    #[derive( Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Mint: Mint,
        Redeem: Redeem,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        sender: ContractAddress,
        receiver: ContractAddress,
        amount: felt252,
    }

    


}

