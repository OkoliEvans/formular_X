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
}