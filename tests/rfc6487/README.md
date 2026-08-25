# Rapport – Test Suite: RFC 6487 Resource Certificate Profile Conformance

> **Scope:** RFC 6487 (Proposed Standard, February 2012) defines the profile for X.509 resource certificates and their CRLs in the RPKI. It imposes requirements stricter than the generic PKIX profiles of RFC 5280 and RFC 3779: only specific extensions are permitted, certain fields have fixed values, and validation includes RPKI-specific constraints (resource encompassment, same-key CRL verification). Section 9 requires the RP to **reject** certificates that do not conform to this profile, *including certificates that would be valid under RFC 5280 but carry a prohibited extension or omit a required one*. This strict-minimalism enforcement is the property under test.
>
> The suite covers the full RFC as it applies to a **validator (Relying Party)**:
>
> - **Section 2** — resource extension requirements (presence, criticality)
> - **Section 4** — certificate field and extension profile (the bulk of the suite)
> - **Section 5** — CRL profile (8 automated cases)
> - **Section 7** — resource and path validation
>
> Sections 6 (certificate requests), 8 (design notes), and 9 (operational considerations) are out of scope: section 6 is CA-side, sections 8–9 are non-normative or operational.

---

## Key Concepts

| Concept | Section | Impact on validator |
|---|---|---|
| Every resource certificate MUST contain at least one INR extension (IP and/or AS), marked critical | section 2, section 4.8.10, section 4.8.11 | A certificate without any resource extension, or with a non-critical one, must be rejected |
| Only version 3 certificates are valid in the RPKI | section 4.1 | A v1 or v2 certificate must be rejected; stricter than RFC 5280 |
| The issuer and subject names MUST contain exactly one CommonName | section 4.4, section 4.5 | A DN with no CommonName or with forbidden attribute types must be rejected |
| The certificate MUST be within its validity period (notBefore to notAfter) | section 4.6, section 7.2 | An expired or not-yet-valid certificate must not produce VRPs |
| Only the extensions listed in section 4.8 are permitted; all others are forbidden | section 4.8, section 9 | A certificate with any unlisted extension — even one valid under RFC 5280 — must be rejected |
| Basic Constraints MUST be present (critical) in CA certificates and MUST NOT be present in EE certificates; pathLenConstraint is forbidden | section 4.8.1 | Missing, extra, or malformed Basic Constraints must cause rejection |
| SKI MUST be present in all resource certificates; AKI MUST be present except in self-signed certificates | section 4.8.2, section 4.8.3 | Missing SKI or AKI must cause rejection; AKI must not contain authorityCertIssuer or authorityCertSerialNumber |
| Key Usage MUST be present, critical, and set to exactly keyCertSign+cRLSign (CA) or digitalSignature (EE) | section 4.8.4 | Wrong bits, missing extension, or non-critical marking must cause rejection |
| EKU MUST NOT appear in CA certificates or in EE certificates used for RPKI object verification | section 4.8.5 | Presence of EKU in a CA or object-verifying EE certificate must cause rejection |
| CRLDP MUST be present (except self-signed), with a single DistributionPoint, fullName only, no CRLIssuer, no Reasons | section 4.8.6 | Missing or malformed CRLDP must cause rejection |
| AIA MUST be present (except self-signed), with a single caIssuers rsync URI | section 4.8.7 | Missing AIA must cause rejection |
| SIA MUST be present in CA certificates (with caRepository and rpkiManifest); EE SIA MUST have signedObject | section 4.8.8 | Missing SIA or missing required AccessMethod must cause rejection |
| Certificate Policies MUST be present (critical), with exactly the RPKI CP OID | section 4.8.9 | Missing, non-critical, or wrong-OID Certificate Policies must cause rejection |
| Only version 2 CRLs are valid in the RPKI; RPs are not required to process version 1 CRLs | section 5 paragraph 1 | A version 1 CRL must be rejected |
| CRL extensions other than AKI and CRL Number are entirely prohibited | section 5 paragraph 1, section 5 paragraph 6 | A CRL carrying any other extension (e.g. deltaCRLIndicator) must be rejected |
| Every RPKI CRL MUST include the Authority Key Identifier (AKI) extension | section 5 paragraph 6 | A CRL without AKI cannot be bound to the issuing CA and must be rejected |
| The CRL issuer name MUST match the subject name of the issuing CA certificate | section 5 paragraph 2, section 7.2 condition 5 | An issuer mismatch means the CRL cannot be applied to that CA's certificates |
| A CRL whose `nextUpdate` is in the past is stale; a CRL whose `thisUpdate` is in the future is not yet valid | section 5 paragraph 1 + RFC 5280 section 5.1.2.4/5.1.2.5 | An expired or future CRL makes revocation status unknown |
| The CRL MUST be signed with the same key used to sign the certificates it covers | section 7.2 condition 5 | A CRL signed with a different key is invalid; revocation status is unknown |
| The issuer's INRs MUST encompass the subject's INRs at every step of the path | section 7.1 | An over-claiming child must be rejected (or pruned per RFC 8360) |
| A certificate whose serial number appears in a valid CRL is revoked | section 7.2 condition 5 | Objects signed by a revoked certificate must not be validated |

---

## Test Cases

---

## Section 2 — Resource Description and Criticality

---

### 2-a - `certificate-without-any-inr-extension-rejected`

**Description:**
This test checks that the validator rejects a resource certificate containing neither the IP Address Delegation nor the AS Identifier Delegation extension. Section 2 requires every resource certificate to carry at least one INR extension. The objects beneath the rejected CA disappear from the VRP set while unrelated CAs stay valid.

---

### 2-b - `ip-extension-not-critical-rejected`

**Description:**
This test checks that the validator rejects a certificate whose IP resource extension is present but not marked critical. Section 2 and section 4.8.10/4.8.11 require these extensions to be critical.

---

### 2-c - `as-extension-not-critical-rejected`

**Description:**
This test checks that the validator rejects a certificate whose AS resource extension is present but not marked critical. Section 2 and section 4.8.10/4.8.11 require these extensions to be critical.

---

## Section 4.1 – 4.7 — Certificate Identity and Validity Fields

---

### 4.1-a - `certificate-version-not-3-rejected`

**Description:**
This test checks that the validator rejects a certificate encoded as X.509 v2 (version field = 1 instead of 2, which represents v3). Section 4.1 requires version 3. This is stricter than RFC 5280, which does require RPs to process v1/v2.

---

### 4.4-a - `issuer-without-commonname-rejected`

**Description:**
This test checks that the validator rejects a certificate whose issuer DN contains an organizationName attribute instead of the required CommonName. Section 4.4 requires exactly one CommonName (PrintableString) and at most one serialNumber; no other attribute types are permitted.

---

### 4.6-a - `expired-certificate-rejected`

**Description:**
This test checks that the validator rejects a certificate whose notAfter is in the past (validity period 2020-01-01 to 2020-12-31). Section 4.6 and section 7.2 require the current time to lie within the validity interval. The validator MUST NOT emit VRPs derived from an expired certificate.

---

### 4.6-b - `not-yet-valid-certificate-rejected`

**Description:**
This test checks that the validator rejects a certificate whose notBefore is in the future (validity period 2099-01-01 to 2099-12-31). The validator MUST NOT treat a not-yet-valid certificate as currently valid.

---

## Section 4.8 — Extension Presence, Criticality, and Value

---

### 4.8-a - `unrecognized-critical-extension-rejected`

**Description:**
This test checks that the validator rejects a certificate carrying an extension with an unknown OID (1.2.3.4.5.6.7.8.9) marked critical. Both RFC 5280 and section 4.8 require rejection of unrecognized critical extensions. This is the baseline sanity check for the whole extension-profile group.

---

### 4.8-b - `prohibited-noncritical-extension-rejected`

**Description:**
This test checks that the validator rejects a certificate carrying a standard RFC 5280 extension not part of the RPKI profile (Name Constraints, OID 2.5.29.30), marked non-critical. Section 9 requires the RP to reject it anyway — this is the defining strict-minimalism test for distinguishing a real RPKI validator from a generic PKIX one.

---

### 4.8.1-a - `ca-certificate-missing-basic-constraints-rejected`

**Description:**
This test checks that the validator rejects a CA certificate with no Basic Constraints extension. Section 4.8.1 requires it (critical) when the subject is a CA. The validator must prune the CA's entire subtree.

---

### 4.8.1-b - `ee-certificate-with-basic-constraints-rejected`

**Description:**
This test checks that the validator rejects a ROA whose EE certificate carries a Basic Constraints extension. Section 4.8.1 says Basic Constraints MUST NOT be present when the subject is not a CA.

---

### 4.8.1-c - `basic-constraints-with-pathlenconstraint-rejected`

**Description:**
This test checks that the validator rejects a CA certificate whose Basic Constraints carries a pathLenConstraint (set to 0). Section 4.8.1 forbids pathLenConstraint in RPKI certificates.

---

### 4.8.2-a - `certificate-missing-ski-rejected`

**Description:**
This test checks that the validator rejects a certificate with no Subject Key Identifier extension. Section 4.8.2 requires SKI in all resource certificates.

---

### 4.8.3-a - `nonselfsigned-certificate-missing-aki-rejected`

**Description:**
This test checks that the validator rejects a subordinate (non-self-signed) certificate with no Authority Key Identifier extension. Section 4.8.3 requires AKI except in self-signed certificates.

---

### 4.8.3-b - `aki-with-authoritycertserialnum-rejected`

**Description:**
This test checks that the validator rejects a certificate whose AKI includes the authorityCertSerialNumber field. Section 4.8.3 forbids both authorityCertIssuer and authorityCertSerialNumber.

---

### 4.8.3-c - `aki-with-authorityCertIssuer-rejected`

**Description:**
This test checks that the validator rejects a certificate whose AKI includes the authorityCertIssuer field. Section 4.8.3 forbids both authorityCertIssuer and authorityCertSerialNumber.

---

### 4.8.4-a - `certificate-missing-key-usage-rejected`

**Description:**
This test checks that the validator rejects a certificate with no Key Usage extension. Section 4.8.4 requires it as a critical extension in all resource certificates.

---

### 4.8.4-b - `key-usage-not-critical-rejected`

**Description:**
This test checks that the validator rejects a certificate whose Key Usage extension is present but not marked critical. Section 4.8.4 requires Key Usage to be a critical extension.

---

### 4.8.4-c - `ca-key-usage-wrong-bits-rejected`

**Description:**
This test checks that the validator rejects a CA certificate whose Key Usage is set to digitalSignature (0x80) instead of the required keyCertSign + cRLSign (0x06). Section 4.8.4 fixes exactly those two bits for CA certificates.

---

### 4.8.4-d - `ee-key-usage-wrong-bits-rejected`

**Description:**
This test checks that the validator rejects a ROA whose EE certificate has Key Usage set to keyCertSign (0x04) instead of the required digitalSignature (0x80). Section 4.8.4 fixes digitalSignature as the only bit for EE certificates.

---

### 4.8.5-a - `ca-certificate-with-eku-rejected`

**Description:**
This test checks that the validator rejects a CA certificate carrying an Extended Key Usage extension (OID 2.5.29.37). Section 4.8.5 forbids EKU in any CA certificate.

---

### 4.8.5-b - `rpki-object-ee-with-eku-rejected`

**Description:**
This test checks that the validator rejects a ROA whose EE certificate carries an Extended Key Usage extension (OID 2.5.29.37). Section 4.8.5 forbids EKU in EE certificates used to verify RPKI objects. Router EE certificates (RFC 8209) are a separate profile and out of scope.

---

### 4.8.6-a - `nonselfsigned-certificate-missing-crldp-rejected`

**Description:**
This test checks that the validator rejects a subordinate certificate with no CRL Distribution Points extension. Section 4.8.6 requires CRLDP except in self-signed certificates.

---

### 4.8.6-b - `crldp-duplicate-distributionpoint-rejected`

**Description:**
This test checks that the validator rejects a certificate with two CRLDP extensions (duplicate OID 2.5.29.31). Section 4.8.6 requires a single DistributionPoint; RFC 5280 also forbids duplicate extension OIDs.

---

### 4.8.7-a - `nonselfsigned-certificate-missing-aia-rejected`

**Description:**
This test checks that the validator rejects a subordinate certificate with no Authority Information Access extension. Section 4.8.7 requires a single caIssuers rsync URI except in self-signed certificates.

---

### 4.8.8-a - `ca-certificate-missing-sia-rejected`

**Description:**
This test checks that the validator rejects a CA certificate with no Subject Information Access extension. Section 4.8.8.1 requires SIA in CA certificates. SIA location violations (object published elsewhere) are covered by rfc6481/2.2-c/2.2-d; this test targets presence.

---

### 4.8.8-b - `ca-sia-missing-manifest-accessmethod-rejected`

**Description:**
This test checks that the validator rejects a CA certificate whose SIA has id-ad-caRepository but the id-ad-rpkiManifest AccessDescription is replaced with a bogus OID (1.2.3.4.5.6.7.8.9). Section 4.8.8.1 requires both caRepository and rpkiManifest in the SIA.

---

### 4.8.8-c - `ee-sia-missing-signedobject-rejected`

**Description:**
This test checks that the validator rejects a ROA whose EE certificate's SIA has its id-ad-signedObject AccessDescription replaced with a bogus OID (1.2.3.4.5.6.7.8.9). Section 4.8.8.2 requires exactly id-ad-signedObject; other AccessMethods MUST NOT be used.

---

### 4.8.9-a - `certificate-missing-certificate-policies-rejected`

**Description:**
This test checks that the validator rejects a certificate with no Certificate Policies extension. Section 4.8.9 requires it (critical) with exactly one policy.

---

### 4.8.9-b - `certificate-policies-wrong-oid-rejected`

**Description:**
This test checks that the validator rejects a certificate whose Certificate Policies extension's OID is replaced with a bogus value (1.2.3.4.5.6.7.8.9), making the extension unrecognizable as Certificate Policies. Section 4.8.9 requires CP with the RPKI CP OID 1.3.6.1.5.5.7.14.2.

---

### 4.8.10-a - `ip-resources-inherit-honored`

**Description:**
This test checks that the validator correctly resolves the `inherit` element in a CA certificate's IP resource extension. The child CA uses inherit; its parent has explicit IP resources (192.0.2.0/24). A subordinate ROA claims a prefix within the inherited range. If the validator handles inherit correctly, the VRP appears.

---

## Section 5 — Resource Certificate Revocation Lists

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
This test checks that the validator rejects a CRL whose `issuer` field does not match the `subject` field of the CA certificate that is purportedly responsible for it. RFC 6487 section 5 paragraph 2 requires the CRL issuer name to match the CA's name. A CRL with a mismatched issuer cannot be associated with the CA whose certificates it claims to cover, and cannot be used to determine the revocation status of those certificates.

---

### 5-6-a - `crl-missing-aki`

**Description:**
This test checks that the validator rejects a CRL from which the Authority Key Identifier (AKI) extension has been omitted. RFC 6487 section 5 paragraph 6 requires every RPKI CRL to include both the Authority Key Identifier and the CRL Number extensions. The AKI cryptographically binds the CRL to the issuing CA's key pair and is a prerequisite for the key-identity check that RFC 6487 section 7.2 condition 5 imposes.

---

### 5-6-b - `crl-wrong-aki`

**Description:**
This test checks that the validator rejects a CRL whose AKI extension is present, well-formed, and uses the correct (keyIdentifier-only) method, but whose keyIdentifier value does not actually match the issuing CA's public key. This is deliberately distinct from crl-missing-aki, which tests the extension's absence: this one tests that the validator recomputes the SHA-1 of the CA's actual public key and compares it against the AKI, rather than merely checking that the field exists.

---

## Section 7.1 — Resource Validation

---

### 7.1-a - `ip-resource-overclaim-child-rejected`

**Description:**
This test checks that the validator rejects a subordinate certificate that claims IP resources (10.0.0.0/8) not encompassed by its issuer (192.0.2.0/24). Section 7.1 requires the issuer's resources to encompass the subject's. The intersection is empty, so even under RFC 8360 (validation reconsidered) the child has no valid resources.

---

### 7.1-b - `as-resource-overclaim-child-rejected`

**Description:**
This test checks that the validator rejects a subordinate certificate that claims AS resources (AS1–AS100) not encompassed by its issuer (AS64512). Section 7.1 requires the issuer's resources to encompass the subject's. The intersection is empty.

---

## Section 7.2 — Path Validation

---

### 7.2-a - `certificate-signature-not-verifiable-rejected`

**Description:**
This test checks that the validator rejects a certificate whose signature does not verify under the issuer's public key (corrupted signature bits). Section 7.2 condition 1 requires the certificate to be verifiable. The validator must prune the entire subtree.

---

### 7.2-b - `crl-signed-with-different-key-than-issuer-rejected`

**Description:**
This test checks that the validator rejects a CRL whose signature does not verify against the CA's public key. Section 7.2 condition 5 and section 10 (Security Considerations) require the CRL-validating key to equal the certificate-issuing key. A CRL with an unverifiable signature is not authoritative, so the revocation status of all covered certificates is unknown.

---

### 7.2-c - `broken-issuer-subject-chain-rejected`

**Description:**
This test checks that the validator rejects a certificate whose AKI keyIdentifier does not match the issuer's (TA's) public key. Section 7.2 requires the signing chain to be consistent across the path. The AKI mismatch means the certificate claims a different issuer key than the one that actually signed it.

---

### 7.2-condition-5-a - `crl-bad-signature`

**Description:**
This test checks that the validator handles correctly a CRL whose cryptographic signature does not verify with the issuing CA's public key. RFC 6487 section 7.2 condition 5 requires that the CRL be "itself valid" for revocation status to be established. A CRL that fails signature verification is not valid, so the revocation status of all certificates it purportedly covers is unknown. The validator must not treat those certificates as confirmed un-revoked.

---

### 7.2-condition-5-b - `crl-revokes-child`

**Description:**
This test checks that the validator correctly honours a valid CRL that lists an active certificate's serial number as revoked. The CA's manifest points to a valid, correctly signed CRL; that CRL explicitly revokes the serial number of one of the CA's child certificates, which is still published in the repository and still listed in the manifest. The validator must treat the child certificate as revoked and must not validate any objects whose trust path passes through it, regardless of the fact that the child certificate is still present in the manifest.

---

### 7.2-d - `excessive-path-length-halts`

**Description:**
This test checks that the validator halts when a certification path or SIA-pointer loop exceeds its configured maximum depth. Section 7.2 permits an RP to halt with a failure. Already covered by rfc6481/5-a-sia-pointer-loop and rfc6481/5-b-certificate-chain-exceeds-maximum-depth — listed here for section 7 completeness only.

---

*End of RFC 6487 Resource Certificate Profile suite — 45 test cases*
