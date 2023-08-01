use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<T> {
    fn get_name(self: @T) -> felt252;
    fn get_symbol(self: @T) -> felt252;
    // fn 

}