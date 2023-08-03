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