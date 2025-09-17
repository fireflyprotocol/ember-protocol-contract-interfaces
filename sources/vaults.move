#[allow(unused_const, unused_field)]
module ember_vaults::vault {

    // === Imports ===

    use std::string::String;
    use sui::balance::Balance;
    use sui::table::Table;
    use sui::coin::{TreasuryCap, Coin};
    use sui::clock::Clock;
    use ember_vaults::queue::Queue;
    use ember_vaults::admin::ProtocolConfig;

    // === Errors ===
    
    const EInvalidPermission: u64 = 2000;
    const EInvalidAccount: u64 = 2001;
    const EInvalidRate: u64 = 2002;
    const EInvalidFeePercentage: u64 = 2003;
    const EZeroAmount: u64 = 2004;
    const EInvalidStatus: u64 = 2005;
    const EVaultPaused: u64 = 2006;
    const EInsufficientBalance: u64 = 2007;
    const EBlacklistedAccount: u64 = 2008;
    const EInsufficientShares: u64 = 2009;
    const EInvalidInterval: u64 = 2010;
    const EInvalidAmount: u64 = 2011;
    const EInvalidRequest: u64 = 2012;
    const EUserDoesNotHaveAccount: u64 = 2013;
    const ESameValue: u64 = 2014;
    const EAlreadyExists: u64 = 2015;
    const EMaxTVLReached: u64 = 2016;
    const EReceiptTokenTreasuryCapNotEmpty: u64 = 2017;

    // === Structs ===

    /// Represents a withdrawal request
    public struct WithdrawalRequest has copy, drop, store {
        owner: address, 
        // the address of the receiver that will get the withdrawal amount
        receiver: address, 
        // the number of shares to redeem
        shares: u64, 
        // the estimated amount of assets user will receive after withdrawal
        estimated_withdraw_amount: u64,
        // the time at which withdrawal request was made
        timestamp: u64, 
        // this is the sequencer number of the vault at the time of requesting withdrawal
        sequence_number: u128 
    }

    /// Represents the platform fee accrued on the vault
    public struct PlatformFee has copy, drop, store {
        // the amount of platform fee accrued on the vault
        accrued: u64,
        // timestamp (ms) at which the platform fee was last charged
        last_charged_at: u64,
    }

    /// Represents the rate of the vault
    public struct Rate has copy, drop, store {
        // the rate of the vault (1e9)
        value: u64,
        // the max allowed change in rate per update
        max_rate_change_per_update: u64,
        // the time interval that must elapse before rate can be updated (ms)
        rate_update_interval: u64,
        // the last time the rate was updated (ms)
        last_updated_at: u64,
    }

    /// Represents an account in the vault. The struct is only created when a 
    /// user requests a withdrawal and is removed when the withdrawal is processed.
    public struct Account has copy, drop, store {
        // the amount of shares that the account has pending for withdrawal
        total_pending_withdrawal_shares: u64,
        // The sequencer numbers of the withdrawal requests that the account has made and are pending processing
        // @Dev if a user makes too many requests, the vector will grow and will eventually hit its max size.
        // That will cause a denial of service attack as user won't be able to cancel their requests.
        // The user will need to wait for vault operator to process their already pending requests before they
        // can request more withdrawals.
        pending_withdrawal_requests: vector<WithdrawalRequest>,
        // The sequencer numbers of the withdrawal requests that the account has cancelled
        cancel_withdraw_request: vector<u128>,
    }

    /// Represents an Ember Vault
    public struct Vault<phantom T, phantom R> has key {
        // Unique id of the vault
        id: UID, 
        // Name of the vault (can be removed)
        name: String,
        // admin of the vault, can perform privileged operations like setting vault operator or adding/removing supported assets etc.
        admin: address,         
        // The vault operator, can perform operations like depositing/withdrawing assets, setting vault rate etc.
        operator: address,

        // the list of accounts blacklisted to perform any action on the vault
        blacklisted: vector<address>,
        // true if withdrawals, deposits and claims are paused
        paused: bool,        
        // the queue contains pending withdrawals that are yet not claimed by users
        pending_withdrawals: Queue<WithdrawalRequest>,
        // the table contains the accounts in the vault that have pending withdrawals
        accounts: Table<address,Account>, 
        // pending shares to burn upon processing withdrawal request
        pending_shares_to_burn: Balance<R>,
        // this is the list of accounts to which funds can be withdrawn from the vault and sent to by operator
        sub_accounts: vector<address>,
        // the rate of the vault
        rate: Rate,  
        // the fee percentage to be charged on the vault
        fee_percentage: u64,
        // the balance of the vault asset
        balance: Balance<T>,
        // the platform fee
        fee: PlatformFee,
        // the minimum amount of shares that can be withdrawn from the vault
        min_withdrawal_shares: u64,
        // the maximum TVL that the vault can hold
        max_tvl: u64,
        // treasury cap for the receipt token
        receipt_token_treasury_cap: TreasuryCap<R>,
        // an ever increasing number that is used to track the actions performed on the vault
        sequence_number: u128,
    }



    // === Public Functions ===
    
    /// Allows a user to deposit assets into the vault and receive receipt tokens in return.
    /// 
    /// Parameters:
    /// - vault: The mutable reference to the vault to deposit into.
    /// - config: The protocol configuration.
    /// - balance: The balance of assets to deposit.
    /// - ctx: The mutable transaction context.
    /// 
    /// Returns:
    /// - Coin<R>: The minted receipt token coin corresponding to the deposited amount.
    /// 
    /// Aborts with:
    /// - EZeroAmount: If the deposit amount is zero.
    /// - EInvalidPermission: If the protocol is paused or the vault is paused.
    public fun deposit_asset<T,R>(_vault: &mut Vault<T,R>, _config: &ProtocolConfig, _balance: Balance<T>, _ctx: &mut TxContext): Coin<R> {
       abort 0
    }

    /// Allows a user to mint shares from the vault and receive receipt tokens in return.
    /// 
    /// Parameters:
    /// - vault: The mutable reference to the vault to mint shares from.
    /// - config: The protocol configuration.
    /// - balance: The balance of assets to mint shares from.
    /// - shares: The number of shares to mint.
    /// 
    /// Returns:
    /// - Coin<R>: The minted receipt token coin corresponding to the minted shares.
    /// 
    /// Aborts with:
    /// - EZeroAmount: If the shares to mint is zero.
    /// - EInvalidRate: If the vault rate is zero.
    /// - EInsufficientBalance: If the balance is insufficient to mint the shares.
    public fun mint_shares<T,R>(_vault: &mut Vault<T,R>, _config: &ProtocolConfig, _balance: &mut Balance<T>, _shares: u64, _ctx: &mut TxContext): Coin<R> {
        abort 0
    }



    /// Allows a user to redeem shares of a vault and receive underlying assets.
    /// The shares are locked into vault upon request and only when the vault operator processes
    /// the withdrawal request, the shares are burnt and the under lying asset based on the vault rate at the time of processing claim
    /// request is sent to the user.
    /// Parameters:
    /// - vault: The mutable reference to the vault to redeem shares from.
    /// - config: The protocol configuration.
    /// - shares: The balance containing shares to redeem
    /// - receiver: The address to send the underlying assets to
    /// - clock: The clock reference
    /// - ctx: The mutable transaction context
    /// 
    /// Aborts with:
    /// - EZeroAmount: If the shares to redeem is zero.
    /// - EInvalidRate: If the vault rate is zero.
    public fun redeem_shares<T,R>(_vault: &mut Vault<T,R>, _config: &ProtocolConfig, _shares: Balance<R>, _receiver: address, _clock: &Clock, _ctx: &mut TxContext): WithdrawalRequest {
        abort 0        
    }


    /// Allows an owner to cancel a pending withdrawal request
    /// Parameters:
    /// - vault: The mutable reference to the vault to cancel the withdrawal request from.
    /// - config: The protocol configuration.
    /// - sequence_number: The sequence number of the withdrawal request to cancel.
    /// - ctx: The mutable transaction context
    public fun cancel_pending_withdrawal_request<T,R>(_vault: &mut Vault<T,R>, _config: &ProtocolConfig, _sequence_number: u128, _ctx: &mut TxContext){
        abort 0        
    }


    // === View Functions ===

    /// Returns the id of the vault
    /// Parameters:
    /// - vault: The vault to get the id from
    /// Returns: The id of the vault
    public fun get_vault_id<T,R>(_vault: &Vault<T,R>): ID {
        abort 0
    }

    /// Returns the name of the vault
    /// Parameters:
    /// - vault: The vault to get the name from
    /// Returns: The name of the vault
    public fun get_vault_name<T,R>(_vault: &Vault<T,R>): String {
        abort 0
    }

    /// Returns the admin of the vault
    /// Parameters:
    /// - vault: The vault to get the admin from
    /// Returns: The admin of the vault
    public fun get_vault_admin<T,R>(_vault: &Vault<T,R>): address {
        abort 0
    }

    /// Returns the operator of the vault
    /// Parameters:
    /// - vault: The vault to get the operator from
    /// Returns: The operator of the vault
    public fun get_vault_operator<T,R>(_vault: &Vault<T,R>): address {
        abort 0
    }

    /// Returns the blacklisted accounts of the vault
    /// Parameters:
    /// - vault: The vault to get the blacklisted accounts from
    /// Returns: The blacklisted accounts of the vault
    public fun get_vault_blacklisted<T,R>(_vault: &Vault<T,R>): vector<address> {
        abort 0
    }

    /// Returns the paused status of the vault
    /// Parameters:
    /// - vault: The vault to get the paused status from
    /// Returns: The paused status of the vault
    public fun get_vault_paused<T,R>(_vault: &Vault<T,R>): bool {
        abort 0
    }

    /// Returns the amount of shares that the account has pending for withdrawal
    /// Parameters:
    /// - vault: The vault to get the pending shares from
    /// - account: The account to get the pending shares from
    /// Returns: The amount of shares that the account has pending for withdrawal
    public fun get_account_total_pending_withdrawal_shares<T,R>(_vault: &Vault<T,R>, _account: address): u64 {
        abort 0
    }

    /// Returns the pending withdrawal requests of the account
    /// Parameters:
    /// - vault: The vault to get the pending withdrawal requests from
    /// - account: The account to get the pending withdrawal requests from
    /// Returns: The pending withdrawal requests of the account
    public fun get_account_pending_withdrawal_requests<T,R>(_vault: &Vault<T,R>, _account: address): vector<WithdrawalRequest> {
        abort 0
    }

    /// Returns the sequencer numbers of the cancelled withdrawal requests of the account
    /// Parameters:
    /// - vault: The vault to get the cancelled withdrawal requests from
    /// - account: The account to get the cancelled withdrawal requests from
    /// Returns: The sequencer numbers of the cancelled withdrawal requests of the account
    public fun get_account_cancelled_withdraw_request_sequencer_numbers<T,R>(_vault: &Vault<T,R>, _account: address): vector<u128> {
        abort 0
    }

    /// Returns the pending shares to redeem
    /// Parameters:
    /// - vault: The vault to get the pending shares to redeem from
    /// Returns: The pending shares to redeem
    public fun get_pending_shares_to_redeem<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the sub accounts of the vault
    /// Parameters:
    /// - vault: The vault to get the sub accounts from
    /// Returns: The sub accounts of the vault
    public fun get_vault_sub_accounts<T,R>(_vault: &Vault<T,R>): vector<address> {
        abort 0
    }

    /// Returns the rate of the vault
    /// Parameters:
    /// - vault: The vault to get the rate from
    /// Returns: The rate of the vault
    public fun get_vault_rate<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the rate update interval of the vault
    /// Parameters:
    /// - vault: The vault to get the rate update interval from
    /// Returns: The rate update interval of the vault
    public fun get_vault_rate_update_interval<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the max rate change per update of the vault
    /// Parameters:
    /// - vault: The vault to get the max rate change per update from
    /// Returns: The max rate change per update of the vault
    public fun get_vault_max_rate_change_per_update<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the last updated at of the vault
    /// Parameters:
    /// - vault: The vault to get the last updated at from
    /// Returns: The last updated at of the vault
    public fun get_vault_last_updated_at<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the balance of the vault
    /// Parameters:
    /// - vault: The vault to get the balance from
    /// Returns: The balance of the vault
    public fun get_vault_balance<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the sequence number of the vault
    /// Parameters:
    /// - vault: The vault to get the sequence number from
    /// Returns: The sequence number of the vault
    public fun get_vault_sequence_number<T,R>(_vault: &Vault<T,R>): u128 {
        abort 0
    }

    /// Returns the fee percentage of the vault
    /// Parameters:
    /// - vault: The vault to get the fee percentage from
    /// Returns: The fee percentage of the vault
    public fun get_vault_fee_percentage<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the min withdrawal shares of the vault
    /// Parameters:
    /// - vault: The vault to get the min withdrawal shares from
    /// Returns: The min withdrawal shares of the vault
    public fun get_vault_min_withdrawal_shares<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the max TVL of the vault
    /// Parameters:
    /// - vault: The vault to get the max TVL from
    /// Returns: The max TVL of the vault
    public fun get_vault_max_tvl<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the accrued platform fee of the vault
    /// Parameters:
    /// - vault: The vault to get the accrued platform fee from
    /// Returns: The accrued platform fee of the vault
    public fun get_accrued_platform_fee<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the last charged at of the platform fee
    /// Parameters:
    /// - vault: The vault to get the last charged at of the platform fee from
    /// Returns: The last charged at of the platform fee
    public fun get_last_charged_at_platform_fee<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Verifies if the vault is not paused
    /// Parameters:
    /// - vault: The vault to verify if it is not paused
    /// Aborts with:
    /// - EVaultPaused: If the vault is paused
    public fun verify_vault_not_paused<T,R>(_vault: &Vault<T,R>){
        abort 0
    }

    /// Returns the blacklisted accounts of the vault
    /// Parameters:
    /// - vault: The vault to get the blacklisted accounts from
    /// Returns: The blacklisted accounts of the vault
    public fun get_vault_blacklisted_accounts<T,R>(_vault: &Vault<T,R>): vector<address> {
        abort 0
    }
    
    /// Returns the total number of shares in circulation i.e. total supply of receipt tokens - pending shares to burn
    /// Parameters:
    /// - vault: The vault to get the total number of shares in circulation from
    /// Returns: The total number of shares in circulation
    public fun get_vault_total_shares_in_circulation<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Returns the total shares of the vault
    /// Parameters:
    /// - vault: The vault to get the total shares from
    /// Returns: The total shares of the vault
    public fun get_vault_total_shares<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Verifies if the account is not blacklisted
    /// Parameters:
    /// - vault: The vault to verify if the account is not blacklisted
    /// - account: The account to verify if it is not blacklisted
    /// Aborts with:
    /// - EBlacklistedAccount: If the account is blacklisted
    public fun verify_not_blacklisted<T,R>(_vault: &Vault<T,R>, _account: address){
        abort 0
    }

    /// Returns if the account is blacklisted
    /// Parameters:
    /// - vault: The vault to get the blacklisted accounts from
    /// - account: The account to get the blacklisted status from
    /// Returns: The blacklisted status of the account
    public fun is_blacklisted<T,R>(_vault: &Vault<T,R>, _account: address): bool {
        abort 0
    }

    /// Returns the withdrawal queue of the vault
    /// Parameters:
    /// - vault: The vault to get the withdrawal queue from
    /// Returns: The withdrawal queue of the vault
    public fun get_withdrawal_queue<T,R>(_vault: &Vault<T,R>): &Queue<WithdrawalRequest> {
        abort 0
    }

    /// Decodes the withdrawal request
    /// Parameters:
    /// - request: The withdrawal request to decode
    /// Returns: The decoded withdrawal request
    public fun decode_withdrawal_request(_request: &WithdrawalRequest): (address, address, u64, u64, u64, u128) {
        abort 0
    }

    /// Returns the TVL of the vault
    /// Parameters:
    /// - vault: The vault to get the TVL from
    /// Returns: The TVL of the vault
    public fun get_vault_tvl<T,R>(_vault: &Vault<T,R>): u64 {
        abort 0
    }

    /// Calculates the shares from the amount
    /// Parameters:
    /// - vault: The vault to calculate the shares from
    /// - amount: The amount to calculate the shares from
    /// Returns: The shares from the amount
    public fun calculate_shares_from_amount<T,R>(_vault: &Vault<T,R>, _amount: u64): u64 {
        abort 0
    }

    /// Calculates the amount from the shares
    /// Parameters:
    /// - vault: The vault to calculate the amount from
    /// - shares: The shares to calculate the amount from
    /// Returns: The amount from the shares
    public fun calculate_amount_from_shares<T,R>(_vault: &Vault<T,R>, _shares: u64): u64 {
        abort 0
    }
}