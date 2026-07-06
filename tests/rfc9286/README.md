# Rapport – Test Suite: RFC 9286
## Manifests for the Resource Public Key Infrastructure (RPKI)

> **Scope:** Tests derived from RFC 9286 focus on the manifest processing pipeline that a Relying Party MUST execute for every CA publication point. The validator must enforce all five sequential validation checkpoints (section 6.2 through section 6.5), apply the correct failed-fetch fallback behavior (section 6.6) on any failure, and never import objects from an incomplete or inconsistent fetch into its validated object set.

> **Test identifiers:** Each test is identified by the **paragraph anchor** of the main paragraph it relates to in `RFC 9286` (e.g. `#section-3-2` → `3-2`). When more than one test relates to the same paragraph, a sub-index (`-a`, `-b`, `-c`, …) is appended (`3-2-a`, `3-2-b`, …).

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
This test checks that the validator rejects a manifest signed by an EE certificate that should have been revoked when the previous manifest was replaced, detects the reuse through the current CRL, treats the fetch as a failed fetch, falls back to cached objects, and does not import any objects listed in the non-compliant manifest.

---

### 4.2.1-4.4.2 - `manifest-number-non-monotonic-rollback`

**Description:**
This test checks that the validator detects a non-monotonic `manifestNumber` — both the rollback case (new number lower than cached) and the equality case (new number equal to cached) — treats the condition as a failed fetch in both sub-tests, falls back to the cached manifest and its associated objects, does not replace any cached objects with those from the non-compliant manifest, and emits a warning in each case.

---

### 4.2.1-4.6 - `thisupdate-regression`

**Description:**
This test checks that the validator detects a new manifest whose `thisUpdate` timestamp is earlier than that of the previously validated manifest, treats this regression as a failed fetch, falls back to the cached manifest and its associated objects, and does not update the cache with any object referenced by the regressed manifest.

---

### 6-1 - `objects-not-on-manifest-excluded-from-validation`

**Description:**
This test checks that the validator excludes from its active validated object set any signed object present at a publication point that is not listed in the current manifest, confirms that the presence of unlisted files does not cause the fetch itself to fail, and confirms that those files cannot be used by an attacker to introduce unauthorized route origin entries through side-loading.

---

### 6-6-a - `crl-absent-from-manifest-filelist`

**Description:**
This test checks that the validator detects the absence of a CRL entry in the manifest's `fileList`, treats this as a failed fetch because the CRL is considered missing, falls back to the previously cached object set, and does not use any objects from that fetch for validation. A second sub-test verifies that the same failure behavior is triggered when the CRL filename is listed in the manifest but the CRL file itself is unavailable at the publication point.

---

### 6-6-b - `ee-certificate-revoked-chicken-and-egg`

**Description:**
This test checks that the validator detects the chicken-and-egg condition in which the EE certificate used to sign the current manifest appears on the current CRL, treats the fetch as failed, falls back to the previously cached objects, and does not accept or cache any objects whose validation chain depends on the revoked EE certificate.

---

### 6.1-1 - `files-not-co-residing-at-manifest-publication-point`

**Description:**
This test checks that the validator detects when a file listed in the manifest does not physically reside at the publication point URI specified by the `id-ad-caRepository` SIA of the associated CA certificate, treats the fetch as failed, emits a warning, and does not add the remotely residing object to its validated cache.

---

### 6.1-2 - `key-rollover-independent-manifest-processing`

**Description:**
This test checks that the validator processes each manifest independently during a CA key rollover in which two CA instances share the same repository publication point, correctly associates each manifest with only its respective CA instance using the `id-ad-rpkiManifest` URI from each CA certificate's SIA, does not mix objects between the two instances, and cleanly transitions the cache when the old CA instance's products are eventually removed from the publication point.

---

### 6.2-1 - `manifest-unreachable-via-sia-uri`

**Description:**
This test checks that the validator treats an unreachable manifest as a failed fetch at the earliest step of the processing pipeline, falls back to the previously cached manifest and its associated objects without proceeding to any subsequent validation steps, emits a warning, and suspends subordinate object processing for that CA instance until the next successful fetch.

---

### 6.3-1-a - `stale-manifest-nextupdate-exceeded`

**Description:**
This test checks that the validator detects a manifest whose `nextUpdate` timestamp has already elapsed, classifies it as stale, treats the entire fetch as failed, falls back to the previously cached objects for that CA instance, does not import any subordinate objects from the affected publication point, and emits a human-readable warning identifying the stale manifest.

---

### 6.3-1-b - `premature-manifest-thisupdate-in-future`

**Description:**
This test checks that the validator detects a manifest whose `thisUpdate` field is set to a future timestamp, treats it as a failed fetch due to a possible CA or RP clock error, falls back to the previously cached objects, does not accept or cache the premature manifest, and emits a warning indicating the premature condition.

---

### 6.4-1 - `missing-file-in-filelist`

**Description:**
This test checks that the validator detects when a file listed in the manifest's `fileList` cannot be retrieved from the publication point, treats the entire fetch as failed without partially importing the objects that were successfully retrieved, falls back to the complete set of previously cached objects, and emits a warning. No object from the failed fetch must enter the validator's active object set.

---

### 6.5-1 - `hash-mismatch-on-retrieved-object`

**Description:**
This test checks that the validator computes the SHA-256 hash of every file retrieved from a publication point, detects any mismatch against the corresponding entry in the manifest's `fileList`, treats the fetch as failed upon detecting the mismatch, falls back to the previously cached object set, and does not add the tampered or corrupted object to the validated object set.

---

*End of RFC 9286 test suite — 13 test cases*
