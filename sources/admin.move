#[allow(unused_const, unused_field)]
module ember_vaults::admin {


    // === Errors ===

    // Error codes for admin module
    const EUnsupportedPackage: u64 = 1000;
    const EPackageAlreadySupported: u64 = 1001;
    const EInvalidRecipient: u64 = 1002;
    const EInvalidRate: u64 = 1003;
    const EInvalidFeePercentage: u64 = 1004;
    const EProtocolPaused: u64 = 1005;
    const EInvalidRateInterval: u64 = 1006;

    // === Constants ===

    /// Tracks the current version of the package. Every time a breaking change is pushed, 
    /// increment the version on the new package, making any old version of the package 
    /// unable to be used
    const VERSION: u64 = 2;

 

    // === Structs ===

    /// Represents an administrative capability for high-level management and control functions.
    public struct AdminCap has key, store {
        /// Unique identifier for the AdminCap.
        id: UID
    }

    /// The protocol's config object. This is passed as input to each contract call
    /// and is used to validate if the protocol version is supported or not
    public struct ProtocolConfig has key, store {
        // Sui object id
        id: UID,
        // current supported protocol version
        version: u64,
        // if set to true, ALL non-admin operations are paused
        pause_non_admin_operations: bool,
        // the account that will receive all platform fees accrued on the vaults
        platform_fee_recipient: address,
        // the min/max limits for the rate. The rate percentage must always be >= min_rate and <= max_rate
        min_rate: u64,
        max_rate: u64,
        //  the default rate set on a vault upon genesis
        default_rate: u64,

        // the minimum/maximum rate interval allowed to be set on a vault
        min_rate_interval: u64,
        max_rate_interval: u64,

        // the max fee percentage that can be charged on a vault
        max_fee_percentage: u64,
    }   

   
   
    // === Public Functions ===

    /// Returns the current pause status of the protocol
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Returns:
    /// - The current pause status of the protocol
    public fun get_protocol_pause_status(_config: &ProtocolConfig): bool {
        abort 0
    }

    /// Asserts if the config version matches the protocol version
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Aborts with:
    /// - EUnsupportedPackage: If the version does not match
    public fun verify_supported_package(_config: &ProtocolConfig) {
        abort 0
    }

    /// Returns the platform fee recipient
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Returns:
    /// - The platform fee recipient
    public fun get_platform_fee_recipient(_config: &ProtocolConfig): address {
        abort 0
    }

    /// Returns the min rate
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Returns:
    /// - The min rate
    public fun get_min_rate(_config: &ProtocolConfig): u64 {
        abort 0
    }

    /// Returns the max rate
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Returns:
    /// - The max rate
    public fun get_max_rate(_config: &ProtocolConfig): u64 {
        abort 0
    }

    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Returns:
    /// - The default rate  
    public fun get_default_rate(_config: &ProtocolConfig): u64 {
        abort 0
    }

    /// Returns the min rate interval
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Returns:
    /// - The min rate interval
    public fun get_min_rate_interval(_config: &ProtocolConfig): u64 {
        abort 0
    }

    /// Returns the max rate interval
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Returns:
    /// - The max rate interval
    public fun get_max_rate_interval(_config: &ProtocolConfig): u64 {
        abort 0
    }

    /// Returns the max allowed fee percentage that can be charged on a vault
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Returns:
    /// - The max allowed fee percentage
    public fun get_max_allowed_fee_percentage(_config: &ProtocolConfig): u64 {
        abort 0
    }


    /// Asserts if the protocol is not paused
    ///
    /// Parameters:
    /// - config: The protocol config
    ///
    /// Aborts with:
    /// - EProtocolPaused: If the protocol is paused
    public fun verify_protocol_not_paused(_config: &ProtocolConfig) {
        abort 0
    }
}