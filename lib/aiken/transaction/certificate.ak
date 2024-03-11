use aiken/transaction/credential.{
  ColdCommitteeCredential, Credential, DRepCredential, HotCommitteeCredential,
  PoolId, VerificationKeyHash,
}
use aiken/transaction/governance.{Delegatee}
use aiken/transaction/value.{Lovelace}

/// An on-chain certificate attesting of some operation. Publishing
/// certificates / triggers different kind of rules; most of the time,
/// they require signatures from / specific keys.
pub type Certificate {
  // Register staking credential with an optional deposit amount
  RegisterStaking(Credential, Option<Lovelace>)
  // Un-Register staking credential with an optional refund amount
  UnRegisterStaking(Credential, Option<Lovelace>)
  // Delegate staking credential to a Delegatee
  DelegateStaking(Credential, Delegatee)
  // Register and delegate staking credential to a Delegatee in one certificate. Noter that
  // deposit is mandatory.
  RegisterAndDelegate(Credential, Delegatee, Lovelace)
  // Register a DRep with a deposit value. The optional anchor is omitted.
  RegisterDRep(DRepCredential, Lovelace)
  // Update a DRep. The optional anchor is omitted.
  UpdateDRep(DRepCredential)
  // UnRegister a DRep with mandatory refund value
  UnregisterDRep(DRepCredential, Lovelace)
  // A digest of the PoolParams
  PoolRegister(
    // poolId
    PoolId,
    // pool VFR
    VerificationKeyHash,
  )
  // The retirement certificate and the Epoch in which the retirement will take place
  PoolRetire(VerificationKeyHash, Int)
  // Authorize a Hot credential for a specific Committee member's cold credential
  AuthorizeHotCommittee(ColdCommitteeCredential, HotCommitteeCredential)
  ResignColdCommittee(ColdCommitteeCredential)
}
