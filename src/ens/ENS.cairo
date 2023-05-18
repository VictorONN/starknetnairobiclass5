#[contract]

mod ENS {
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    struct Storage {
        names: LegacyMap::<ContractAddress, felt252>,
    }

    #[event]
    fn StoredName(caller: ContractAddress, name: felt252) {}

    #[constructor]
    fn constructor(_name: felt252) {
        let caller = get_caller_address();
        names::write(caller, _name);
        StoredName(caller, _name);
        return ();
    }

    #[external]
    fn store_name(_name: felt252) {
        let caller = get_caller_address();
        names::write(caller, _name);
        StoredName(caller, _name);
        return ();
    }

    #[view]
    fn get_name(_address: ContractAddress) -> felt252 {
        names::read(_address)
    }

}