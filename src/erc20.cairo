#[starknet::contract]
mod ERC20 {

    use starknet::get_caller_address;
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimal: u256,
        total_supply: u256,
        balance: LegacyMap::<ContractAddress, u256>,
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

    

}

