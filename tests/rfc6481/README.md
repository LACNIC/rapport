# Rapport – Test Suite: RFC 6481
## A Profile for Resource Certificate Repository Structure

> **Scope:** Tests derived from RFC 6481 focus on the structural and operational
> requirements that a Relying Party MUST enforce when interacting with RPKI
> repository publication points. The validator must verify that each publication
> point contains the mandatory manifest (section 2.1), that CA repository
> publication points satisfy the content and naming constraints defined in
> section 2.2, that the repository access method is available and consistent
> with the SIA of each certificate (section 3), that certificate reissuance
> overwrites rather than accumulates objects at the publication point (section 4),
> and that the local cache synchronization algorithm is robust against transient
> inconsistency and degenerate hierarchy structures (section 5).

---

## Key Concepts

| Concept | Section | Impact on validator |
|---|---|---|
| Every repository publication point MUST contain a manifest | section 2.1 | Absence of manifest causes the publication point to be rejected |
| Manifest and repository contents may be transiently misaligned during updates | section 2.1 | Validator must tolerate intermediate states without treating them as permanent failures |
| CA publication point contains current certs, current CRL, current manifest, and current signed objects | section 2.2 | Stale CRLs or manifests that have not been replaced must not be accepted |
| Objects published outside the location indicated by the SIA MUST be rejected | section 2.2, 3 | Validator must cross-check the SIA URI against the actual retrieval location |
| Publication repository MUST be accessible via rsync; additional methods are optional | section 3 | If the primary access method is unavailable, validator must fall back to an alternate method if specified in the SIA |
| Reissued certificates SHOULD overwrite the previous instance at the same publication point | section 4 | Validator must correctly replace and validate reissued certificates without retaining stale copies |
| During key rollover, two CA instances MAY share the same publication point | section 2.2, 4 | Both manifests must be processed independently; objects must not be mixed between instances |
| Repository traversal MUST support a configurable maximum chain length | section 5 | Validator must detect and break SIA pointer loops or excessive depth |
| Synchronization SHOULD use manifests to verify consistency of each publication point | section 5 | Validator must tolerate transient inconsistency without silently accepting a partially updated state |
| Rsync must be available; SIA access methods must match actual retrieval mechanisms | section 3 | Validator must fall back to alternate access methods when the primary is unavailable |

---

## Test Cases

---

### 2.1-a - `missing-manifest-at-publication-point`

**Description:**
This test checks that the validator detects a repository publication point that
contains no manifest, rejects the entire publication point and all objects within
it, does not import any certificates, CRLs, or signed objects from a manifest-less
publication point into its validated object set, and emits a human-readable warning
identifying the affected publication point URI.

**Related sections:** section 2.1 (every repository publication point MUST contain
a manifest; the manifest contains the names and hash values of all objects currently
published by a CA or EE), section 5 (RPs SHOULD use retrieved manifests to ensure
synchronization against a current, consistent state of each repository publication
point), section 6 (replacement of newer objects with older instances is detectable
through the use of manifests; without a manifest, such substitution attacks cannot
be detected)

---

### 2.1-b - `transient-inconsistency-during-fetch`

**Description:**
This test checks that the validator tolerates a transient state in which the
manifest and the repository directory contents are not precisely aligned at the
moment of retrieval — a condition that may arise because repository operators cannot
guarantee atomic updates — proceeds without treating the intermediate state as a
permanent failure, and either retries the synchronization or defers object import
until a consistent state is observed. The validator MUST NOT silently accept objects
that are listed on an old manifest but absent from the directory, nor objects present
in the directory but not yet reflected on the current manifest.

**Related sections:** section 2.1 (if no directory management regime is in place,
RPs MAY be exposed to intermediate repository states where the manifest and the
repository contents may not be precisely aligned; specific cases and actions in such
a situation of misalignment are considered in RFC 6486), section 3 (RPs SHOULD NOT
assume that a consistent repository and manifest state are assured, and they SHOULD
organize their retrieval operations accordingly), section 5 (possible algorithms
include performing synchronization across the repository twice in succession, or
performing a manifest retrieval both before and after the synchronization of the
directory contents, and repeating the synchronization function if the second copy
of the manifest differs from the first)

---

### 2.2-a - `stale-crl-not-replaced`

**Description:**
This test checks that the validator detects a CA repository publication point in
which the previously issued CRL has not been replaced by the current one — i.e., the
old CRL is still present alongside a newer CRL issued by the same CA key pair —
rejects the stale CRL, uses only the most recently issued CRL for revocation
checking, and does not accept revocation status derived from an outdated CRL that
should have been overwritten.

**Related sections:** section 2.2 (a CA's publication repository contains the most
recent CRL issued by this CA; CAs MUST NOT continue to publish previous CRLs in
the repository publication point; it MUST replace, i.e., overwrite, previous CRLs
signed by the same CA instance), section 5 (RPs SHOULD use manifests to ensure
synchronization against a current, consistent state of each repository publication
point)

---

### 2.2-b - `stale-manifest-not-replaced`

**Description:**
This test checks that the validator detects a CA repository publication point in
which the previous manifest has not been replaced by a new one — i.e., an outdated
manifest is still present — rejects the stale manifest, treats the publication
point fetch as failed if no valid current manifest is available, falls back to the
previously cached objects per the failed-fetch procedure, and emits a warning
identifying the stale manifest.

**Related sections:** section 2.2 (when a new instance of a manifest is published,
it MUST replace the previous manifest to avoid confusion; CAs MUST NOT continue to
publish previous CA manifests in the repository publication point)

---

### 2.2-c - `object-published-outside-sia-location`

**Description:**
This test checks that the validator detects a signed object that has been published
at a repository location other than the one indicated by the `id-ad-caRepository`
SIA of the issuing CA certificate, rejects the out-of-place object, does not import
it into the validated object set, and emits a warning identifying the URI mismatch.
A second sub-test verifies that the validator also rejects objects whose SIA EE
certificate reference points to a location that is not the authoritative publication
point of the issuing CA.

**Related sections:** section 2.2 (signed objects are published in the repository
publication point referenced by the SIA of the CA certificate that issued the EE
certificate used to validate the digital signature of the signed object), section 3
(signed objects are published in the location indicated by the SIA field of the EE
certificate used to verify the signature of each object; signed objects are
published in the repository publication point of the CA certificate that issued the
EE certificate)

---

### 3 - `fallback-to-alternate-access-method`

**Description:**
This test checks that the validator falls back to an alternate repository access
method — as specified in the SIA of the associated CA or EE certificate — when the
primary access method (rsync) is unavailable, successfully retrieves all objects
using the alternate mechanism, validates them correctly, and does not report a
failed fetch solely on the basis of the primary method being unreachable. The test
also verifies that the validator does not attempt access methods that are not
enumerated in the SIA.

**Related sections:** section 3 (the publication repository MUST be available using
rsync; support of additional retrieval mechanisms is the choice of the repository
operator; the supported retrieval mechanisms MUST be consistent with the
accessMethod element value(s) specified in the SIA of the associated CA or EE
certificate)

---

### 4-a - `certificate-reissued-at-same-publication-point`

**Description:**
This test checks that the validator correctly handles a CA certificate that has been
reissued — for example, due to changes in the set of number resources — at the same
repository publication point, accepts the reissued certificate as the authoritative
replacement for the previous one, does not retain or use the overwritten certificate
in any subsequent validation, and confirms that subordinate objects whose AIA
extensions point to that publication point remain valid across the reissuance event.

**Related sections:** section 4 (if a CA certificate is reissued, it should not be
necessary to reissue all certificates issued under it; a CA SHOULD use a name for
its repository publication point that persists across certificate reissuance events;
reissued CA certificates SHOULD use the same repository publication point as
previously issued CA certificates having the same subject and subject public key,
such that certificate reissuance SHOULD intentionally overwrite the previously
issued certificate within the repository publication point)

---

### 4-b - `two-manifests-coexist-during-key-rollover`

**Description:**
This test checks that the validator accepts a repository publication point in which
two manifests from two distinct CA instances coexist as a transient state during a
key rollover, processes each manifest independently and associates it with its
respective CA instance via the `id-ad-rpkiManifest` SIA pointer in each CA
certificate, does not mix the subordinate products of the old and new CA instances,
and cleanly transitions to the new CA instance's products once the old CA's objects
are removed from the publication point.

**Related sections:** section 2.2 (in cases of key rollover, the entity SHOULD
continue to use the same repository publication point for both CA instances during
the key rollover; in such cases, the repository publication point will contain the
CRL, manifest and subordinate certificates of both CA instances), section 4 (the
RPKI key rollover procedure requires that the subordinate products of the old CA be
overwritten in the common repository publication point by subordinate products issued
by the new CA)

---

### 5-a - `sia-pointer-loop-detected-and-broken`

**Description:**
This test checks that the validator detects a cycle in the SIA pointer graph — a
condition in which following the `id-ad-caRepository` or `id-ad-rpkiManifest`
pointers of a set of CA certificates eventually leads back to a previously visited
publication point — terminates the traversal at the point of cycle detection,
does not enter an infinite loop, does not import any objects reachable exclusively
through the cyclic path, and emits a warning identifying the cycle.

**Related sections:** section 5 (such a repository traversal process SHOULD support
a locally configured maximal chain length from the initial trust anchors; if this
is not done, then there might be a SIA pointer loop, or other degenerate forms of
the logical RPKI hierarchy, that would cause an RP to malfunction when performing
a repository synchronization operation with the RP's local RPKI cache)

---

### 5-b - `certificate-chain-exceeds-maximum-depth`

**Description:**
This test checks that the validator enforces a locally configured maximum chain
length from the initial trust anchors, terminates further traversal when the chain
depth exceeds this limit, does not process or import any objects at publication
points reachable only beyond the configured depth, and emits a warning identifying
the chain length violation. The test verifies that the limit is applied consistently
across all traversal paths originating from each trust anchor.

**Related sections:** section 5 (such a repository traversal process SHOULD support
a locally configured maximal chain length from the initial trust anchors; if this
is not done, then there might be a SIA pointer loop, or other degenerate forms of
the logical RPKI hierarchy, that would cause an RP to malfunction when performing
a repository synchronization operation with the RP's local RPKI cache)

---

*End of RFC 6481 test suite — 10 test cases*
