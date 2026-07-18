# Rapport – Test Suite: RFC 6487 Section 5
## Resource Certificate Revocation Lists

> **Scope:** RFC 6487 section 5 (Proposed Standard, February 2012) profiles the Certificate Revocation Lists (CRLs) used in the RPKI. It imposes requirements that are stricter than the generic X.509 CRL profile of RFC 5280: only version 2 CRLs are acceptable, CRL extensions other than Authority Key Identifier (AKI) and the CRL Number are forbidden entirely. Section 7.2 (condition 5) binds CRL validity to the CA's public key: a certificate is only identified as revoked if the CRL that lists it is itself valid and was signed with the same key used to sign the certificate.
>
> **Relationship to RFC 5280:** RFC 6487 section 5 ¶1 requires that every RPKI CRL be "consistent with RFC 5280". Temporal constraints on the `thisUpdate` and `nextUpdate` fields are not re-defined in RFC 6487 but are inherited from RFC 5280 sections 5.1.2.4 and 5.1.2.5.

---

## Key Concepts

| Concept | Section | Impact on validator |
|---|---|---|
| Only version 2 CRLs are valid in the RPKI; RPs are not required to process version 1 CRLs | section 5 ¶1 | A version 1 CRL must be rejected; revocation status of covered certificates becomes unknown |
| CRL entry extensions are prohibited | section 5 ¶1, section 5 ¶6 | CRL extensions other than Authority Key Identifier and the CRL Number are entirely prohibited |
| Every RPKI CRL MUST include the Authority Key Identifier (AKI) extension | section 5 ¶6 | A CRL without AKI cannot be bound to the issuing CA and must be rejected |
| The CRL issuer name MUST match the subject name of the issuing CA certificate | section 5 ¶2, section 7.2 condition 5 | An issuer mismatch means the CRL cannot be applied to that CA's certificates |
| The CRL MUST be signed with the same key used to sign the certificates it covers | section 7.2 condition 5 | A CRL that fails signature verification is invalid; revocation status of covered certificates is unknown |
| A certificate whose serial number appears in a valid CRL is revoked | section 7.2 condition 5 | Objects signed by a revoked certificate must not be validated, even if the certificate still appears in the manifest |
| A CRL whose `nextUpdate` is in the past is stale | section 5 ¶1 + RFC 5280 section 5.1.2.5 | An expired CRL makes revocation status unknown |
| A CRL whose `thisUpdate` is in the future is not yet valid | section 5 ¶1 + RFC 5280 section 5.1.2.4 | A not-yet-valid CRL makes revocation status unknown |

---

## Test Cases

---

### 5-1-a - `crl-wrong-version`

**Description:**
This test checks that the validator rejects a CRL encoded as version 1. RFC 6487 section 5 requires that every CA issue a version 2 CRL and states explicitly that Relying Parties are not required to process version 1 CRLs — a stricter stance than RFC 5280, which does require RPs to process them. When the CRL for a CA is rejected, the revocation status of all certificates issued by that CA is unknown, and those certificates must not be used in path validation.

---

### 5-1-b - `crl-expired`

**Description:**
This test checks that the validator treats a CRL whose `nextUpdate` field is set to a date in the past as stale and therefore invalid. RFC 6487 section 5 requires CRLs to be consistent with RFC 5280; RFC 5280 section 6.3.3 requires that the current time be before `nextUpdate` for a CRL to be considered current. An expired CRL means the CA has not confirmed that the revocation data is still current, so the revocation status of all certificates covered by that CRL is unknown. The validator must not treat covered certificates as confirmed un-revoked on the basis of a stale CRL.

---

### 5-1-c - `crl-future-thisupdate`

**Description:**
This test checks that the validator rejects a CRL whose `thisUpdate` field is set to a date in the future. RFC 5280 section 5.1.2.4 defines `thisUpdate` as the issue date of the CRL — the date on which the revocation information was known to be accurate. A `thisUpdate` in the future means the CRL purports to have been issued at a point that has not yet occurred, making it not yet valid.

---

### 5-2 - `crl-wrong-issuer`

**Description:**
This test checks that the validator rejects a CRL whose `issuer` field does not match the `subject` field of the CA certificate that is purportedly responsible for it. RFC 6487 section 5 ¶2 requires the CRL issuer name to match the CA's name. A CRL with a mismatched issuer cannot be associated with the CA whose certificates it claims to cover, and cannot be used to determine the revocation status of those certificates.

---

### 5-6-a - `crl-missing-aki`

**Description:**
This test checks that the validator rejects a CRL from which the Authority Key Identifier (AKI) extension has been omitted. RFC 6487 section 5 ¶6 requires every RPKI CRL to include both the Authority Key Identifier and the CRL Number extensions. The AKI cryptographically binds the CRL to the issuing CA's key pair and is a prerequisite for the key-identity check that RFC 6487 section 7.2 condition 5 imposes.

---

### 5-6-b - `crl-wrong-aki`

**Description:**
This test checks that the validator rejects a CRL whose AKI extension is present, well-formed, and uses the correct (`keyIdentifier`-only) method, but whose `keyIdentifier` value does not actually match the issuing CA's public key. This is deliberately distinct from `crl-missing-aki`, which tests the extension's absence: this one tests that the validator recomputes the SHA-1 of the CA's actual public key and compares it against the AKI, rather than merely checking that the field exists.

---

### 7.2-condition-5-a - `crl-bad-signature`

**Description:**
This test checks how the validator handles a CRL whose cryptographic signature does not verify with the issuing CA's public key. RFC 6487 section 7.2 condition 5 requires that the CRL be "itself valid" for revocation status to be established. A CRL that fails signature verification is not valid, so the revocation status of all certificates it purportedly covers is unknown. The validator must not treat those certificates as confirmed un-revoked.

---

### 7.2-condition-5-b - `crl-revokes-child`

**Description:**
This test checks that the validator correctly honours a valid CRL that lists an active certificate's serial number as revoked. The CA's manifest points to a valid, correctly signed CRL; that CRL explicitly revokes the serial number of one of the CA's child certificates, which is still published in the repository and still listed in the manifest. The validator must treat the child certificate as revoked and must not validate any objects whose trust path passes through it, regardless of the fact that the child certificate is still present in the manifest.

---

*End of RFC 6487 section 5 test suite — 8 test cases*
