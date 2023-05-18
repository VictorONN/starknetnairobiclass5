#[contract]

mod ICO {
    use class::erc20::IERC20;
    use class::erc20::IERC20::IERC20Dispatcher;
    use class::erc20::IERC20::IERC20DispatcherTrait;

    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::ContractAddress;
    use starknet::get_block_timestamp;
    use starknet::contract_address_try_from_felt252;
    use integer::u256_from_felt252;
    use option::OptionTrait;

    struct Storage {
        token_address: ContractAddress,
        admin_address: ContractAddress,
        registered_address: LegacyMap::<ContractAddress, bool>,
        claimed_address: LegacyMap::<ContractAddress, bool>,
        ico_start_time: u64,
        ico_end_time: u64,
    }

    const ICO_DURATION: u64 = 86400;
    const REG_PRICE: felt252 = 1000000000000000;

    #[event]
    fn Registered(user: ContractAddress) {}

    #[event]
    fn Claimed(user: ContractAddress) {}

    #[constructor]
    fn constructor(_token_address: ContractAddress, _admin_address: ContractAddress) {
        token_address::write(_token_address);
        admin_address::write(_admin_address);
        let start_time: u64 = get_block_timestamp();
        let end_time: u64 = start_time + ICO_DURATION;
        ico_start_time::write(start_time);
        ico_end_time::write(end_time);
        return ();
    }

    #[view]
    fn is_registered(user: ContractAddress) -> bool {
        registered_address::read(user)
    }

    #[external]
    fn register() {
        let caller = get_caller_address();
        let this_contract = get_contract_address();
        let start_time = ico_start_time::read();
        let end_time = ico_end_time::read();
        let eth_contract_address: ContractAddress = contract_address_try_from_felt252(0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7).unwrap();

        // check that the ICO has not ended
        let current_time: u64 = get_block_timestamp();
        assert(current_time < end_time, 'ICO: ico has ended');
        // check that the user has not previously registered_address
        assert(registered_address::read(caller) == false, 'ICO: already registered');
        // check that the user approved REG_PRICE to be spent 
        let allowance: u256 = IERC20Dispatcher { contract_address: eth_contract_address }.allowance(caller, this_contract);
        assert(allowance > u256_from_felt252(REG_PRICE), 'ICO: insufficient allowance');

        IERC20Dispatcher { contract_address: eth_contract_address }.transfer_from(caller, this_contract, u256_from_felt252(REG_PRICE));

        // register the user
        registered_address::write(caller, true);

        // emit Registered event
        Registered(caller);

        return ();
    }

    #[external]
    fn claim(_address: ContractAddress) {
        let this_contract = get_contract_address();
        let end_time = ico_end_time::read();

        // check that ICO is over
        let current_time: u64 = get_block_timestamp();
        assert(current_time > end_time, 'ICO: ico has not ended');
        // check that the user has registered
        assert(registered_address::read(_address) == true, 'ICO: user is not registered');
        // check that the user has not claimed previously
        assert(claimed_address::read(_address) == false, 'ICO: user already claimed');

        let claim_amount: u256 = u256_from_felt252(50);
        let _token_address = token_address::read();
        let _admin_address = admin_address::read();
        IERC20Dispatcher { contract_address: _token_address }.transfer_from(_admin_address, _address, claim_amount);

        claimed_address::write(_address, true);

        // emit Claimed event
        Claimed(_address);

        return ();
    }
}