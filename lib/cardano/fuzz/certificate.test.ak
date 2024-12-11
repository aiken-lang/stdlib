use aiken/fuzz.{label}
use cardano/certificate.{
  AlwaysAbstain, AlwaysNoConfidence, AuthorizeConstitutionalCommitteeProxy,
  DelegateBlockProduction, DelegateBoth, DelegateCredential, DelegateVote,
  RegisterAndDelegateCredential, RegisterCredential,
  RegisterDelegateRepresentative, RegisterStakePool, Registered,
  RetireFromConstitutionalCommittee, RetireStakePool, UnregisterCredential,
  UnregisterDelegateRepresentative, UpdateDelegateRepresentative,
}
use cardano/fuzz/certificate.{any_certificate,
  any_delegate, any_drep} as fuzz_cert

test prop_any_certificate(c via any_certificate()) {
  label(
    when c is {
      RegisterCredential(_, _) -> @"RegisterCredential"
      UnregisterCredential(_, _) -> @"UnregisterCredential"
      DelegateCredential(_, _) -> @"DelegateCredential"
      RegisterAndDelegateCredential(_, _, _) -> @"RegisterAndDelegateCredential"
      RegisterDelegateRepresentative(_, _) -> @"RegisterDelegateRepresentative"
      UpdateDelegateRepresentative(_) -> @"UpdateDelegateRepresentative"
      UnregisterDelegateRepresentative(_, _) ->
        @"UnregisterDelegateRepresentative"
      RegisterStakePool(_, _) -> @"RegisterStakePool"
      RetireStakePool(_, _) -> @"RetireStakePool"
      AuthorizeConstitutionalCommitteeProxy(_, _) ->
        @"AuthorizeConstitutionalCommitteeProxy"
      RetireFromConstitutionalCommittee(_) ->
        @"RetireFromConstitutionalCommittee"
    },
  )
  True
}

/// Test for any_delegate generator
test prop_any_delegate(d via any_delegate()) {
  label(
    when d is {
      DelegateBlockProduction(_) -> @"DelegateBlockProduction"
      DelegateVote(_) -> @"DelegateVote"
      DelegateBoth(_, _) -> @"DelegateBoth"
    },
  )
  True
}

/// Test for any_drep (DelegateRepresentative) generator
test prop_any_drep(drep via any_drep()) {
  label(
    when drep is {
      Registered(_) -> @"Registered"
      AlwaysAbstain -> @"AlwaysAbstain"
      AlwaysNoConfidence -> @"AlwaysNoConfidence"
    },
  )
  True
}
