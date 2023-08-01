use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<T> {
    fn get_name(self: @T) -> felt252;
    fn get_symbol(self: @T) -> felt252;
    fn balance_of(self: @T, owner: ContractAddress) -> u8;
    fn owner_of(self: @T, token_id: u128) -> ContractAddress;
    fn is_approved_for_all(self: @T, owner: ContractAddress, operator: ContractAddress) -> bool;
    fn transfer_from(ref self: T, from: ContractAddress, to: ContractAddress, token_id: u128);
    fn approve(ref self: T, to: ContractAddress, token_id: u128);
    fn set_approval_for_all(ref self: T, operator: ContractAddress, approved: bool);
    fn get_approved(ref self: T, token_id: u128);
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
    }

}