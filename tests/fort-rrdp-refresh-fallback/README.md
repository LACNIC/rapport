# Rapport – Test Suite: FORT Refresh & Fallback Behavior
## RRDP Serial Fallback on Invalid RPP — Implementation-Defined Recovery

> **Scope:** This suite tests how FORT selects which RRDP serial to serve when the newest serial produces an invalid Repository Publication Point (RPP). This is **not** governed by any RFC — RFC 8182 (RRDP), RFC 9286 (manifests), and RFC 6481 (repository structure) all describe how to fetch, order, and validate objects, but none prescribe what a Relying Party must do when the most recent serial validates at the RRDP transport layer yet fails RPKI validation of its RPP contents. FORT's chosen policy is the system under test.

> **FORT's policy:** When the newest serial results in an invalid RPP, FORT does not immediately fall back to the last known-good serial it was serving. Instead it walks backward through the intermediate serials, giving each a chance, and serves the highest one that yields a valid RPP. The newest serial's data is still cached as the RRDP refresh state (so the next serial can build on it) but is not served. Serials strictly between the newest and the one finally served are discarded. The previously-served fallback is only served again if every newer serial fails.

> **Terminology used throughout:**
> - **Served serial** — the serial whose VRPs FORT actually exposes via RTR.
> - **Fallback** — the last known-good served serial, retained as a safety net if newer serials fail. Recorded per publication point in the cache JSON, with a manifest number.
> - **Refresh state** — the newest fetched serial's RRDP metadata/content, cached (as a numbered step in the cage JSON) so the next delta can be applied even if this serial is not served.
> - **RPP-fatal / non-fatal** — whether a validation failure rejects the whole publication point (manifest/CRL) or only the offending object (a single ROA).
> - **Cage** — FORT's per-publication-point cache directory, described by a `.json` file recording its sessions, per-serial steps, fallbacks, and the files each references. A fort2 feature.

> **Test identifiers:** Each test is identified by a short tag describing the scenario condition and the expected outcome.

---

## Key Concepts

| Concept | Impact on the RP under test |
|---|---|
| RRDP transport validity is distinct from RPKI RPP validity | A delta can apply cleanly at the RRDP layer yet yield an RPP that fails RPKI validation |
| A single invalid ROA is NOT RPP-fatal | Only that ROA's VRP is dropped; the rest of the serial is served; no fallback |
| An invalid manifest/CRL cert IS RPP-fatal | The whole publication point is rejected; the backward-walk fallback triggers |
| Newest RPP-fatal serial does not force immediate fallback to last-served | FORT walks backward, giving intermediate serials a chance |
| Backward walk serves the highest valid serial | RPP-fatal serials between the newest and the served one are discarded |
| Newest serial is cached as a refresh step even when RPP-fatal | Its full file set (including the offending object) is retained in the cage JSON so the next delta can build on it |
| The previous fallback is served only if all newer serials are RPP-fatal | It is never discarded while a newer valid candidate exists |
| Refresh state must not leak into served VRPs | Cached-but-not-served data must never appear in RTR output |
| Cache classification is observable via the cage JSON | Served, fallback, and refresh states are distinguishable in the cache, not just in the served VRP set |

---

## Test Cases

---

### Group A — Backward Walk Depth (RPP-fatal via corrupt manifest)

These tests exercise how far back FORT walks when a contiguous run of newest serials is RPP-fatal. Invalidity is induced by corrupting the child CA's **manifest** (`A.mft`) at the target serial, which is RPP-fatal and therefore triggers the fallback.

---

#### a-1 — `newest-invalid-serves-previous`

**Description:**
Serial 4's RPP is RPP-fatal (corrupt `A.mft`); serials 3 and 2 are valid. FORT must serve serial 3, register serial 3 as the fallback for CA `A`, and cache serial 4 as the refresh step without serving it.

---

#### a-2 — `two-newest-invalid-serves-third`

**Description:**
Serials 4 and 3 are both RPP-fatal (corrupt `A.mft` at each); serial 2 is valid. FORT must walk backward past serials 4 and 3 and serve serial 2, registering serial 2 as the fallback. Serial 4 is cached as the refresh step; serial 3 is discarded.

---

#### a-3 — `all-updates-invalid-keeps-fallback`

**Description:**
Serials 4, 3, and 2 are all RPP-fatal. No newer serial is valid, so FORT retains serial 1 — the original fallback — as both served serial and fallback. Serial 4 is cached as the refresh step; serials 2 and 3 are discarded. This is the floor of the backward walk.

---

### Group B — Recovery (refresh state is usable)

Group A confirms the newest RPP-fatal serial is cached as a refresh step. Group B confirms that refresh step is actually usable: a later valid serial applies on top of it as a delta, not via a snapshot re-fetch.

---

#### b-1 — `recovery-builds-on-cached-refresh`

**Description:**
Continues the a-1 state (serial 4 RPP-fatal, serving serial 3, serial 4 cached as refresh). A serial 5 arrives with a valid RPP whose delta is constructed on top of the cached serial 4 refresh state. FORT must apply serial 5's delta on top of serial 4 (not snapshot-refetch) and serve serial 5's VRPs.

---

#### b-2 — `recovery-jumps-from-deep-fallback`

**Description:**
Continues the A-3 state (serials 2, 3, 4 all RPP-fatal, serving fallback serial 1). A serial 5 arrives valid, built on the cached serial 4 refresh state. FORT must jump from serving serial 1 to serving serial 5 in one step, applying serial 5's delta over the cached serial 4 refresh.

---

### Group C — Non-Contiguous RPP-Fatal Failure

Group A corrupts contiguously from the newest serial. Group C corrupts an intermediate serial's manifest while the newest is valid, probing whether FORT's policy concerns the newest serial specifically or any serial in the chain.

---

#### c-1 — `intermediate-invalid-newest-valid`

**Description:**
Serial 3's manifest is RPP-fatal but serial 4 (the newest) is valid. Since serial 4's delta builds on serial 3's RRDP state, this tests whether FORT can serve serial 4 when an intermediate serial's RPP failed. Records which outcome occurs: FORT serves serial 4 (the later valid serial supersedes the intermediate failure) or falls back.

---

#### c-2 — `deep-intermediate-invalid-newest-valid`

**Description:**
Serial 2's manifest is RPP-fatal while serials 3 and 4 are valid. Extends c-1 to a deeper gap. Records whether FORT serves serial 4 (walking over the earlier RPP-fatal serial 2 via valid serial 3) or falls back.

---

### Group D — ROA-Level (non-fatal) and Edge Cases

---

#### d-1 — `invalid-roa-does-not-induce-fallback`

**Description:**
The counterpart to Group A, capturing the non-fatal ROA behavior explicitly. Serial 4 adds A4 with an **invalid ROA signature** (not a corrupt manifest). Per FORT's policy, a single bad ROA is not RPP-fatal: FORT invalidates only A4 (no VRP for it) and accepts serial 4 as the served state, with A4 still present in the RPP-level fallback and refresh cache. No backward-walk fallback to serial 3 occurs — FORT stays on serial 4.

---

#### d-2 — `first-iteration-invalid-no-fallback`

**Description:**
The first iteration FORT processes is RPP-fatal (corrupt `A.mft` at serial 1) with no prior known-good serial. FORT has nothing to serve. Tests the floor of the policy: an empty served set, no phantom fallback.

---

#### d-3 — `invalid-roa-excluded-after-fallback-revalidation`

**Description:**
Builds on d-1 to confirm that FORT's fallback is a *re-validated RPP*, not a frozen VRP set. When FORT is forced back onto a cached serial, it re-validates that RPP before serving it — and an invalid ROA inside it is re-rejected on that pass. Two iterations:

*Iteration 1 (the d-1 state).* Serials 1–4, with `A4.roa`'s signature invalid at serial 4 and `A.mft` valid. Serial 4 is served, VRPs are A1+A2+A3 (A4 self-invalidates), and `A4.roa` sits in serial 4's fallback/refresh cache without yielding a VRP.

*Iteration 2 (everything fails).* A new serial 5 arrives RPP-fatal (corrupt `A.mft`). FORT cannot serve serial 5 and walks back to serial 4, re-validating its RPP to serve it. `A4.roa` is re-checked, its signature fails again, so A4's resource is still absent from the served set and `A4.roa` remains in serial 4's fallback (cached, never served).

---

*End of FORT Refresh & Fallback test suite — 10 test cases across 4 groups*
