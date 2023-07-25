#[starknet::contract]
mod ERC20 {
    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimal: felt252,
        total_supply: felt252,
        balance: LegacyMap::<ContractAddress, u252>,
    }


}

