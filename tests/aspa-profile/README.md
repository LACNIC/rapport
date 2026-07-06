# Rapport – Test Suite: draft-ietf-sidrops-aspa-profile
## A Profile for Autonomous System Provider Authorization
### Reference version: draft-ietf-sidrops-aspa-profile-26

> **Scope:** Tests derived from the ASPA profile draft focus on the structural, cryptographic, and semantic validation rules that a Relying Party MUST apply when processing an Autonomous System Provider Authorization (ASPA) object. An ASPA is a CMS-protected signed object that authorizes one or more Provider Autonomous Systems (PAS) on behalf of a Customer AS (CAS). The validator must enforce the content type OID, the ASN.1 field constraints, the provider list invariants, and the EE certificate extension requirements defined in this draft.

> **Test identifiers:** Each test is identified by the **paragraph anchor** of the main paragraph it relates to in `draft-26` (e.g. `#section-2-1` → `2-1`). When more than one test relates to the same paragraph, a sub-index (`-a`, `-b`, `-c`, …) is appended (`2-1-a`, `2-1-b`, …).

---

## Key Concepts

| Concept | Section | Impact on validator |
|---|---|---|
| ASPA content type OID MUST be `1.2.840.113549.1.9.16.1.49` in both eContentType and signerInfo | section 2 | Wrong OID means the object must be rejected |
| `version` field MUST be 1 and MUST be explicitly encoded | section 3.1 | Any other value or absent encoding is invalid |
| `customerASID` is a positive integer in the range 1..4294967295 | section 3.2, ASN.1 `CAS` type | Value 0 or out-of-range is invalid |
| `customerASID` MUST NOT appear in the `providers` field | section 3.3 | Self-referencing provider entry must be rejected |
| `providers` elements MUST be in ascending numerical order | section 3.3 | Unsorted list must be rejected |
| Each `providers` `PAS` value MUST be unique | section 3.3 | Duplicates must cause rejection |
| `PAS` value 0 MUST be the sole element if present | section 3.3 | AS 0 alongside other entries must be rejected |
| Provider value range is 0..4294967295; values above are out of range | section 3, ASN.1 `PAS` type | Value ≥ 4294967296 is structurally invalid |
| `customerASID` MUST match the EE certificate's AS Identifier Delegation Extension | section 4 | Mismatch causes validation failure |
| AS Identifier Delegation Extension MUST contain exactly one `id` element | section 4 | `inherit` or `range` elements cause rejection |
| IP Address Delegation Extension MUST be absent | section 4 | Presence of this extension causes rejection |
| Implementations SHOULD impose an upper bound of 4,000–10,000 providers | section 5.4 | Exceeding the threshold SHOULD invalidate all related ASPAs |

---

## Test Cases

---

### 2-1-a — `valid-eContentType`

**Description:**
This test checks that the validator accepts an ASPA object whose `eContentType` in the `encapContentInfo` structure correctly carries the OID `1.2.840.113549.1.9.16.1.49` (`id-ct-ASPA`), and that the same OID is present in the `content-type` signed attribute within the `signerInfo` structure, allowing the object to proceed through subsequent validation steps.

---

### 2-1-b — `invalid-eContentType`

**Description:**
This test checks that the validator rejects an ASPA object whose `eContentType` field in the `encapContentInfo` structure does not carry the OID `1.2.840.113549.1.9.16.1.49` (`id-ct-ASPA`), treating it as a structurally non-compliant signed object that cannot be used for route leak detection.

---

### 2-1-c — `valid-content-type-signed-attribute`

**Description:**
This test checks that the validator accepts an ASPA object whose `content-type` signed attribute within the `signerInfo` structure (`signerInfos.0.signedAttrs.content-type`) correctly carries the OID `1.2.840.113549.1.9.16.1.49` (`id-ct-ASPA`), matching the `eContentType` in the `encapContentInfo` structure, allowing the object to proceed through subsequent validation steps.

---

### 2-1-d — `invalid-content-type-signed-attribute`

**Description:**
This test checks that the validator rejects an ASPA object whose `content-type` signed attribute within the `signerInfo` structure (`signerInfos.0.signedAttrs.content-type`) does not carry the OID `1.2.840.113549.1.9.16.1.49` (`id-ct-ASPA`) — for example, when it differs from the OID present in the `eContentType` of the `encapContentInfo` structure — treating it as a structurally non-compliant signed object that cannot be used for route leak detection.

---

### 3-3-a — `valid-ASID-in-provider-list-minimum-non-zero-value`

**Description:**
This test checks that the validator accepts an ASPA object whose `providers` field contains an ASID with the value `1`, which is within the valid range `0..4294967295` defined by the ASN.1 specification, and that no rejection is triggered solely by this value.

---

### 3-3-b — `valid-ASID-in-provider-list-below-maximum-value`

**Description:**
This test checks that the validator accepts an ASPA object whose `providers` field contains an ASID with the value `4294967294`, which is one below the maximum allowed value and is within the valid range `0..4294967295`, confirming that near-maximum values are processed correctly.

---

### 3-3-c — `valid-ASID-in-provider-list-maximum-value`

**Description:**
This test checks that the validator accepts an ASPA object whose `providers` field contains an ASID with the value `4294967295`, which is the maximum value defined by the ASN.1 type `PAS ::= INTEGER (0..4294967295)`, confirming that the boundary value is handled correctly and does not cause an off-by-one rejection.

---

### 3-3-d — `invalid-ASID-in-provider-list`

**Description:**
This test checks that the validator rejects an ASPA object whose `providers` field contains an ASID with the value `4294967296`, which exceeds the maximum value of `4294967295` defined by the ASN.1 type `PAS ::= INTEGER (0..4294967295)`, making the encoded value structurally out of the permitted range.

---

### 3.1-1-a — `valid-version`

**Description:**
This test checks that the validator accepts an ASPA object whose `version` field is explicitly encoded as `1`, recognizing this as the only valid version value defined by the specification, and allows the object to proceed to subsequent structural and semantic validation steps.

---

### 3.1-1-b — `invalid-version-wrong-value`

**Description:**
This test checks that the validator rejects an ASPA object whose `version` field in the `ASProviderAttestation` structure is explicitly set to `2`, which does not comply with the requirement that the version MUST be `1`, and that the object is not used for any routing security decision.

---

### 3.1-1-c — `invalid-version-missing-explicit-encoding`

**Description:**
This test checks that the validator rejects an ASPA object whose `version` field is absent or encoded as a default (i.e., omitted from the DER encoding, implying the ASN.1 DEFAULT value of `0`), since the specification requires that the version MUST be `1` and MUST be explicitly encoded, making both value `0` and an implicit encoding non-compliant.

---

### 3.2-1-a — `valid-customerASID-minimum-value`

**Description:**
This test checks that the validator accepts an ASPA object whose `customerASID` field is set to `1`, the minimum value permitted by the ASN.1 type `CAS ::= INTEGER (1..4294967295)`, confirming that the lower boundary of the Customer AS range is handled correctly and does not cause an off-by-one rejection.

---

### 3.2-1-b — `valid-customerASID-low-value`

**Description:**
This test checks that the validator accepts an ASPA object whose `customerASID` field is set to `2`, an ordinary value well within the valid range of the ASN.1 type `CAS ::= INTEGER (1..4294967295)`, confirming that a typical small Customer AS identifier is processed without rejection.

---

### 3.2-1-c — `valid-customerASID-below-maximum-value`

**Description:**
This test checks that the validator accepts an ASPA object whose `customerASID` field is set to `4294967294`, which is one below the maximum allowed value and is within the valid range of the ASN.1 type `CAS ::= INTEGER (1..4294967295)`, confirming that near-maximum Customer AS identifiers are processed correctly.

---

### 3.2-1-d — `valid-customerASID-maximum-value`

**Description:**
This test checks that the validator accepts an ASPA object whose `customerASID` field is set to `4294967295`, the maximum value defined by the ASN.1 type `CAS ::= INTEGER (1..4294967295)`, confirming that the upper boundary of the Customer AS range is handled correctly and does not cause an off-by-one rejection.

---

### 3.2-1-e — `invalid-customerASID-above-maximum-value`

**Description:**
This test checks that the validator rejects an ASPA object whose `customerASID` field is set to `4294967296`, which is one beyond the maximum value of `4294967295` defined by the ASN.1 type `CAS ::= INTEGER (1..4294967295)`, making the encoded value structurally out of the permitted range.

---

### 3.2-1-f — `customerASID-0`

**Description:**
This test checks that the validator rejects an ASPA object whose `customerASID` field is set to `0`, which falls outside the valid range of the ASN.1 type `CAS ::= INTEGER (1..4294967295)` and violates the requirement that the Customer AS identifier must be a positive integer.

---

### 3.3-4.1.1-a — `customerASID-in-provider-list`

**Description:**
This test checks that the validator rejects an ASPA object whose `providers` field contains the same AS number as the `customerASID`, since the Customer AS is explicitly prohibited from authorizing itself as one of its own providers.

---

### 3.3-4.2.1-a — `sorted-provider-list`

**Description:**
This test checks that the validator accepts an ASPA object whose `providers` field contains multiple ASID entries arranged in strict ascending numerical order, confirming that a canonically ordered provider list satisfies the ordering constraint and does not cause a validation failure.

---

### 3.3-4.2.1-b — `unsorted-provider-list`

**Description:**
This test checks that the validator rejects an ASPA object whose `providers` field contains ASID entries that are not arranged in ascending numerical order, since the specification requires the provider list to be in canonical ascending order and any deviation from that order makes the object non-compliant.

---

### 3.3-4.3.1 — `duplicate-customerASID-in-provider-list`

**Description:**
This test checks that the validator rejects an ASPA object whose `providers` field contains the `customerASID` value appearing more than once, violating both the prohibition on the customer AS appearing in the provider list and the requirement that every ASID value in the provider list must be unique.

---

### 3.3-4.4.1-a — `ASID-0-as-sole-provider`

**Description:**
This test checks that the validator accepts an ASPA object whose `providers` field contains exactly one element with ASID value `0`, recognizing this as a valid single-item provider list that satisfies the constraint allowing AS 0 only as a sole entry.

---

### 3.3-4.4.1-b — `ASID-0-alongside-other-providers`

**Description:**
This test checks that the validator rejects an ASPA object whose `providers` field contains AS 0 alongside one or more other ASID values, since the specification requires that AS 0 can only appear as a single-item list and MUST NOT appear together with any other elements.

---

### 4-1-a — `invalid-certificate-signature`

**Description:**
This test checks that the validator rejects an ASPA object whose EE certificate carries an invalid cryptographic signature — i.e., the signature computed over the certificate's `tbsCertificate` does not verify against the issuing CA's public key — treating the certificate as untrustworthy and the entire ASPA as invalid.

---

### 4-1-b — `invalid-object-signature`

**Description:**
This test checks that the validator rejects an ASPA object whose CMS `SignerInfo` signature — computed over the `eContent` (the DER-encoded `ASProviderAttestation`) — does not verify correctly against the EE certificate's public key, ensuring that tampered or corrupted ASPA payloads are never used for routing decisions.

---

### 4-2.1.1-a — `customerASID-matches-AS-resource-extension`

**Description:**
This test checks that the validator accepts an ASPA object whose `customerASID` field value exactly matches the single AS identifier contained in the EE certificate's AS Identifier Delegation Extension, confirming that the mandatory consistency check between the eContent and the EE certificate extension passes without error.

---

### 4-2.1.1-b — `customerASID-does-not-match-AS-resource-extension`

**Description:**
This test checks that the validator rejects an ASPA object whose `customerASID` field value does not match the ASN identifier contained in the AS Identifier Delegation Extension of the EE certificate embedded within the ASPA's CMS structure, since the draft requires an exact match between the two values as a mandatory validation step.

---

### 4-2.1.1-c — `customerASID-is-not-subset-of-parent`

**Description:**
This test checks that the validator rejects an ASPA object whose EE certificate's AS Identifier Delegation Extension contains an AS number that is not within the set of AS resources delegated to the issuing CA by its parent certificate, confirming that the RPKI resource certification chain constraint is enforced end-to-end for ASPA objects.

---

### 4-2.2.1-a — `inherit-elements-in-as-resource-extension`

**Description:**
This test checks that the validator rejects an ASPA object whose EE certificate contains an AS Identifier Delegation Extension with one or more `inherit` elements, since the specification explicitly prohibits the use of `inherit` elements in this extension for ASPA EE certificates.

---

### 4-2.2.1-b — `range-elements-in-AS-resource-extension`

**Description:**
This test checks that the validator rejects an ASPA object whose EE certificate contains an AS Identifier Delegation Extension that includes one or more `range` elements, since the specification requires the extension to contain exactly one `id` element and explicitly prohibits `range` elements.

---

### 4-2.3.1 — `ip-resource-extension-is-present`

**Description:**
This test checks that the validator rejects an ASPA object whose EE certificate contains an IP Address Delegation Extension, since the specification mandates that this extension MUST be absent in ASPA EE certificates, and its presence indicates a non-compliant object.

---

### 5.1-1 — `multiple-aspas-for-same-customerASID`

**Description:**
This test checks the behavior of the validator when multiple structurally and cryptographically valid ASPA objects exist in the repository for the same `customerASID`. The draft does not define any normative validator behavior for this scenario — the recommendation to maintain a single ASPA per Customer AS is directed at CA operators and hosting software, not at Relying Parties. The purpose of this test is therefore to observe and document the validator's actual behavior (e.g., accepting all, accepting only the most recently signed, or flagging the condition) without asserting a mandatory pass/fail outcome derived from the draft. The result serves as an implementation characterization data point.

---

### 5.4-2-a — `provider-count-below-threshold`

**Description:**
This test checks that the validator accepts an ASPA object whose `providers` field contains 3,999 entries, which is below the suggested lower bound of 4,000 for implementation-defined upper limits, confirming that provider lists well within the practical threshold are processed without rejection due to size constraints.

---

### 5.4-2-b — `provider-count-at-threshold`

**Description:**
This test checks that the validator accepts an ASPA object whose `providers` field contains exactly 4,000 entries, which is at the lower boundary of the suggested upper bound range of 4,000–10,000, confirming that the boundary value itself is treated as within the acceptable limit and does not trigger an invalid threshold condition.

---

### 5.4-2-c — `provider-count-above-threshold`

**Description:**
This test checks that the validator treats an ASPA object as invalid when its `providers` field contains more entries than the implementation's configured upper bound (tested here with 4,001 entries, which exceeds a threshold set at 4,000), and that the validator does not emit a partial provider list but instead invalidates all ASPA objects associated with that `customerASID` and logs an error identifying the affected Customer AS.

---

### 5.4-2-d — `big-aspa`

**Description:**
This test checks that the validator handles an ASPA object with an unusually large number of provider entries without crashing, hanging, or producing corrupted output, and that it correctly applies the configured upper bound threshold to decide whether the object should be accepted or invalidated, logging an appropriate error if the threshold is exceeded.

---

*End of draft-ietf-sidrops-aspa-profile test suite — 36 test cases*
