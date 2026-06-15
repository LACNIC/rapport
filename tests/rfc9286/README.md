# Rapport – Test Suite: RFC 9286
## Manifests for the Resource Public Key Infrastructure (RPKI)

> **Scope:** Tests derived from RFC 9286 focus on the manifest processing pipeline
> that a Relying Party MUST execute for every CA publication point. The validator
> must enforce all five sequential validation checkpoints (section 6.2 through
> section 6.5), apply the correct failed-fetch fallback behavior (section 6.6) on
> any failure, and never import objects from an incomplete or inconsistent fetch
> into its validated object set.

---

## Key Concepts

| Concept | Section | Impact on validator |
|---|---|---|
| Manifest lists every current signed object + hash at a publication point | section 2, section 4.2.1 | If the list and reality disagree, the fetch fails |
| One-time-use EE certificate signs exactly one manifest | section 3, section 5.1 | EE must not be reused; revocation of old EE is mandatory |
| `manifestNumber` MUST increase monotonically | section 4.2.1 | A non-increasing number triggers cache fallback |
| `thisUpdate` MUST be more recent than any previously validated manifest | section 4.2.1 | A regressed timestamp triggers cache fallback |
| Current time MUST fall between `thisUpdate` and `nextUpdate` | section 6.3 | Stale or premature manifest triggers cache fallback |
| All files in `fileList` MUST be retrievable | section 6.4 | Any missing file triggers cache fallback |
| Hash of every retrieved file MUST match `fileList` entry | section 6.5 | Any hash mismatch triggers cache fallback |
| Failed fetch → use cached objects, warn, stop subordinate processing | section 6.6 | Cache is never poisoned by a failed cycle |
| CRL MUST appear in a valid manifest; EE MUST NOT appear on the CRL | section 6 | Violation of either triggers cache fallback |
| All manifest-listed files MUST reside at the same publication point | section 6.1 | Cross-point file references are hard failures |

---

## Test Cases

---

### 3-2 - `one-time-use-ee-certificate-reuse`

**Description:**
This test checks that the validator rejects a manifest signed by an EE
certificate that should have been revoked when the previous manifest was
replaced, detects the reuse through the current CRL, treats the fetch as
a failed fetch, falls back to cached objects, and does not import any
objects listed in the non-compliant manifest.

**Related sections:** section 3 (CA MUST sign only one manifest with each
generated private key and MUST generate a new key pair for each new
version of the manifest), section 5.1 (step 2: CA MUST revoke the EE
certificate used for the manifest being replaced; step 6: private key
MUST be destroyed after signing)

---

### 4.2.1-4.4.2 - `manifest-number-non-monotonic-rollback`

**Description:**
This test checks that the validator detects a non-monotonic
`manifestNumber` — both the rollback case (new number lower than cached)
and the equality case (new number equal to cached) — treats the condition
as a failed fetch in both sub-tests, falls back to the cached manifest
and its associated objects, does not replace any cached objects with those
from the non-compliant manifest, and emits a warning in each case.

**Related sections:** section 4.2.1 (issuer MUST increase `manifestNumber`
monotonically; each RP MUST verify that a purported new manifest contains
a higher `manifestNumber` than previously validated manifests; if equal or
lower, RP SHOULD use locally cached versions per section 6.6)

---

### 4.2.1-4.6 - `thisupdate-regression`

**Description:**
This test checks that the validator detects a new manifest whose
`thisUpdate` timestamp is earlier than that of the previously validated
manifest, treats this regression as a failed fetch, falls back to the
cached manifest and its associated objects, and does not update the cache
with any object referenced by the regressed manifest.

**Related sections:** section 4.2.1 (issuer MUST ensure that `thisUpdate`
is more recent than any previously generated manifest; each RP MUST
verify that this field value is greater than the most recent manifest it
has validated; if smaller, RP SHOULD use locally cached versions per
section 6.6)

---

### 6-1 - `objects-not-on-manifest-excluded-from-validation`

**Description:**
This test checks that the validator excludes from its active validated
object set any signed object present at a publication point that is not
listed in the current manifest, confirms that the presence of unlisted
files does not cause the fetch itself to fail, and confirms that those
files cannot be used by an attacker to introduce unauthorized route origin
entries through side-loading.

**Related sections:** section 6 (any files not listed on the manifest
MUST NOT be used for validation of certificates, ROAs, and CRLs),
section 8 (manifests allow RP to detect unauthorized object removal or
substitution of stale versions)

---

### 6-6-a - `crl-absent-from-manifest-filelist`

**Description:**
This test checks that the validator detects the absence of a CRL entry in
the manifest's `fileList`, treats this as a failed fetch because the CRL
is considered missing, falls back to the previously cached object set, and
does not use any objects from that fetch for validation. A second sub-test
verifies that the same failure behavior is triggered when the CRL filename
is listed in the manifest but the CRL file itself is unavailable at the
publication point.

**Related sections:** section 6 (if the CRL is not listed on a valid,
current manifest, the fetch has failed; CRL is considered missing; proceed
to section 6.6), section 7 (a CA's manifest MUST always contain at least
one entry corresponding to a CRL issued by the CA)

---

### 6-6-b - `ee-certificate-revoked-chicken-and-egg`

**Description:**
This test checks that the validator detects the chicken-and-egg condition
in which the EE certificate used to sign the current manifest appears on
the current CRL, treats the fetch as failed, falls back to the previously
cached objects, and does not accept or cache any objects whose validation
chain depends on the revoked EE certificate.

**Related sections:** section 6 (if the EE certificate for the current
manifest is revoked, i.e., it appears in the current CRL, then the CA or
publication point manager has made a serious error; the fetch has failed;
proceed to section 6.6)

---

### 6.1-1 - `files-not-co-residing-at-manifest-publication-point`

**Description:**
This test checks that the validator detects when a file listed in the
manifest does not physically reside at the publication point URI specified
by the `id-ad-caRepository` SIA of the associated CA certificate, treats
the fetch as failed, emits a warning, and does not add the remotely
residing object to its validated cache.

**Related sections:** section 6.1 (all files referenced by the manifest
MUST be located at the publication point specified by the
`id-ad-caRepository` URI from the same CA certificate's SIA; the manifest
and the files it references MUST reside at the same publication point; if
not, RP MUST treat the fetch as failed and issue a warning)

---

### 6.1-2 - `key-rollover-independent-manifest-processing`

**Description:**
This test checks that the validator processes each manifest independently
during a CA key rollover in which two CA instances share the same
repository publication point, correctly associates each manifest with only
its respective CA instance using the `id-ad-rpkiManifest` URI from each
CA certificate's SIA, does not mix objects between the two instances, and
cleanly transitions the cache when the old CA instance's products are
eventually removed from the publication point.

**Related sections:** section 2 (where multiple CA instances share a
common publication point, the repository will contain multiple manifests;
each manifest describes only the collection of published products of its
associated CA instance), section 5.2 (when a CA entity is performing a
key rollover, two CA instances MAY simultaneously publish into the same
repository publication point), section 6.1 (manifest processing MUST be
performed separately for each CA instance, guided by the SIA
`id-ad-rpkiManifest` URI in each CA certificate)

---

### 6.2-1 - `manifest-unreachable-via-sia-uri`

**Description:**
This test checks that the validator treats an unreachable manifest as a
failed fetch at the earliest step of the processing pipeline, falls back
to the previously cached manifest and its associated objects without
proceeding to any subsequent validation steps, emits a warning, and
suspends subordinate object processing for that CA instance until the
next successful fetch.

**Related sections:** section 6.2 (RP MUST fetch the manifest identified
by the SIA `id-ad-rpkiManifest` URI; if RP cannot retrieve a manifest
using this URI or if the manifest is not valid, RP MUST treat this as a
failed fetch; proceed to section 6.6), section 6.6 (RP MUST NOT try to
acquire and validate subordinate signed objects until next scheduled fetch)

---

### 6.3-1-a - `stale-manifest-nextupdate-exceeded`

**Description:**
This test checks that the validator detects a manifest whose `nextUpdate`
timestamp has already elapsed, classifies it as stale, treats the entire
fetch as failed, falls back to the previously cached objects for that CA
instance, does not import any subordinate objects from the affected
publication point, and emits a human-readable warning identifying the
stale manifest.

**Related sections:** section 6.3 (if current time is later than
`nextUpdate`, manifest is stale; RP MUST treat this as a failed fetch),
section 6.6 (failed fetch: RP MUST issue warning, MUST continue using
cached objects)

---

### 6.3-1-b - `premature-manifest-thisupdate-in-future`

**Description:**
This test checks that the validator detects a manifest whose `thisUpdate`
field is set to a future timestamp, treats it as a failed fetch due to a
possible CA or RP clock error, falls back to the previously cached
objects, does not accept or cache the premature manifest, and emits a
warning indicating the premature condition.

**Related sections:** section 6.3 (if current time is earlier than
`thisUpdate`, the CA may have made an error or the RP's local notion of
time may be in error; RP MUST treat this as a failed fetch; proceed to
section 6.6)

---

### 6.4-1 - `missing-file-in-filelist`

**Description:**
This test checks that the validator detects when a file listed in the
manifest's `fileList` cannot be retrieved from the publication point,
treats the entire fetch as failed without partially importing the objects
that were successfully retrieved, falls back to the complete set of
previously cached objects, and emits a warning. No object from the failed
fetch must enter the validator's active object set.

**Related sections:** section 6.4 (RP MUST acquire all files enumerated
in the manifest; if any file cannot be retrieved, RP MUST treat this as a
failed fetch; proceed to section 6.6), section 6 (unless ALL files
enumerated in a manifest can be obtained, the fetch is considered to have
failed)

---

### 6.5-1 - `hash-mismatch-on-retrieved-object`

**Description:**
This test checks that the validator computes the SHA-256 hash of every
file retrieved from a publication point, detects any mismatch against the
corresponding entry in the manifest's `fileList`, treats the fetch as
failed upon detecting the mismatch, falls back to the previously cached
object set, and does not add the tampered or corrupted object to the
validated object set.

**Related sections:** section 6.5 (RP MUST verify that the hash value of
each file listed in the manifest matches the value obtained by hashing the
file acquired from the publication point; if computed hash does not match,
fetch has failed; proceed to section 6.6)

---

*End of RFC 9286 test suite — 13 test cases*