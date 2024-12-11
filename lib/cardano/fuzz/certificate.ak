use aiken/fuzz.{
  and_then, bytearray_between, constant, int, int_between, map, map2, map3,
}
use cardano/certificate.{
  AlwaysAbstain, AlwaysNoConfidence, AuthorizeConstitutionalCommitteeProxy,
  Certificate, Delegate, DelegateBlockProduction, DelegateBoth,
  DelegateCredential, DelegateRepresentative, DelegateVote,
  RegisterAndDelegateCredential, RegisterCredential,
  RegisterDelegateRepresentative, RegisterStakePool, Registered,
  RetireFromConstitutionalCommittee, RetireStakePool, UnregisterCredential,
  UnregisterDelegateRepresentative, UpdateDelegateRepresentative,
}
use cardano/fuzz/address.{any_credential}

pub fn any_certificate() -> Fuzzer<Certificate> {
  let choice <- and_then(int_between(0, 10))
  when choice is {
    0 -> any_register_cert()
    1 -> any_unregister_cert()
    2 -> any_delegate_cert()
    3 -> any_reg_and_delegate_cert()
    4 -> any_register_drep_cert()
    5 -> any_update_drep_cert()
    6 -> any_unregister_drep_cert()
    7 -> any_register_pool_cert()
    8 -> any_retire_pool_cert()
    9 -> any_authorize_cc_cert()
    10 -> any_retire_cc_cert()
    _ -> fail @"Fail"
  }
}

pub fn any_register_cert() -> Fuzzer<Certificate> {
  map(
    any_credential(),
    fn(credential) { RegisterCredential(credential, Never) },
  )
}

pub fn any_unregister_cert() -> Fuzzer<Certificate> {
  map(
    any_credential(),
    fn(credential) { UnregisterCredential(credential, Never) },
  )
}

pub fn any_delegate_cert() -> Fuzzer<Certificate> {
  map2(any_credential(), any_delegate(), fn(c, d) { DelegateCredential(c, d) })
}

pub fn any_reg_and_delegate_cert() -> Fuzzer<Certificate> {
  map3(
    any_credential(),
    any_delegate(),
    int(),
    fn(c, d, i) { RegisterAndDelegateCredential(c, d, i) },
  )
}

pub fn any_register_drep_cert() -> Fuzzer<Certificate> {
  map2(
    any_credential(),
    int(),
    fn(c, i) { RegisterDelegateRepresentative(c, i) },
  )
}

pub fn any_update_drep_cert() -> Fuzzer<Certificate> {
  map(any_credential(), fn(c) { UpdateDelegateRepresentative(c) })
}

pub fn any_unregister_drep_cert() -> Fuzzer<Certificate> {
  map2(
    any_credential(),
    int(),
    fn(c, i) { UnregisterDelegateRepresentative(c, i) },
  )
}

pub fn any_register_pool_cert() -> Fuzzer<Certificate> {
  map2(
    bytearray_between(32, 32),
    bytearray_between(32, 32),
    fn(b, b2) { RegisterStakePool(b, b2) },
  )
}

pub fn any_retire_pool_cert() -> Fuzzer<Certificate> {
  map2(bytearray_between(32, 32), int(), fn(b, i) { RetireStakePool(b, i) })
}

pub fn any_authorize_cc_cert() -> Fuzzer<Certificate> {
  map2(
    any_credential(),
    any_credential(),
    fn(c, c2) { AuthorizeConstitutionalCommitteeProxy(c, c2) },
  )
}

pub fn any_retire_cc_cert() -> Fuzzer<Certificate> {
  map(any_credential(), fn(c) { RetireFromConstitutionalCommittee(c) })
}

pub fn any_delegate() -> Fuzzer<Delegate> {
  let choice <- and_then(int_between(0, 2))
  when choice is {
    0 -> map(bytearray_between(32, 32), fn(b) { DelegateBlockProduction(b) })
    1 -> map(any_drep(), fn(drep) { DelegateVote(drep) })
    2 ->
      map2(
        bytearray_between(32, 32),
        any_drep(),
        fn(b, drep) { DelegateBoth(b, drep) },
      )
    _ -> fail
  }
}

pub fn any_drep() -> Fuzzer<DelegateRepresentative> {
  let choice <- and_then(int_between(0, 2))
  when choice is {
    0 -> map(any_credential(), fn(c) { Registered(c) })
    1 -> constant(AlwaysAbstain)
    2 -> constant(AlwaysNoConfidence)
    _ -> fail
  }
}
