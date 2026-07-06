# Rapport – Test Suite: RFC 9697
## Detecting RPKI Repository Delta Protocol (RRDP) Session Desynchronization

> **Scope:** RFC 9697 updates RFC 8182 section 3.4.1 by describing a SHOULD-level detection mechanism for a subtle form of RRDP desynchronization: a Repository Server that, over time, serves a *different* Delta File for the same `session_id` and `serial` than it originally advertised. Because the `session_id` and the notification's current `serial` are unchanged across this mutation, none of the detection mechanisms already covered elsewhere in this suite set (session change non-contiguous delta chain, single-fetch hash mismatch) catch it — those all operate within a single notification fetch, while this mutation is only visible by **comparing two fetches over time**.
>
> The mechanism (RFC 9697 section 3): a Relying Party records the `serial` and `hash` of each Delta File it has actually applied. On every subsequent Update Notification File fetch with the same `session_id`, it checks whether the `hash` now advertised for any previously-applied `serial` still matches what it recorded. A mismatch means that serial's Delta File was mutated after the fact — a violation of the immutability principle described in RFC 9697 section 2. Recovery (section 4) is to issue a warning and fall back to downloading and processing the current Snapshot File (RFC 8182 section 3.4.3), discarding the delta chain for that round even though it may, taken in isolation, have looked perfectly applicable.

> **Test identifiers:** Each test is identified by the **paragraph anchor** of the main paragraph it relates to in `RFC 9697` (e.g. `#section-3` → `3`). When more than one test relates to the same paragraph, a sub-index (`-a`, `-b`, `-c`, …) is appended (`3-a`, `3-b`, …).

---

## Key Concepts

| Concept | Section | Impact on validator |
|---|---|---|
| Delta Files for a given `session_id` and `serial` are expected to be an immutable record; serving different content for the same pair violates the principle of least astonishment | section 2 | A Relying Party that cannot detect a mutation may silently diverge from other Relying Parties that fetched before or after the change |
| A Relying Party SHOULD record the `serial` and `hash` of every Delta File it applies | section 3 | Provides the baseline needed to detect a later, silent mutation |
| On every later fetch with the same `session_id`, the RP SHOULD compare previously-recorded hashes against the hash now advertised for the same serials | section 3, example in 3.1 | A mismatch for any previously-applied serial means that Delta File was unexpectedly mutated |
| On detecting a mutation, the RP SHOULD warn and SHOULD fall back to the current Snapshot File | section 4 | The delta chain for that round is distrusted entirely, even if it would otherwise have applied cleanly |

---

## Test Cases

---

### 3-a - `delta-hash-mutation-detected-forces-snapshot-resync`

**Description:**
This test checks that the Relying Party detects when the hash advertised for a previously-applied delta serial changes in a later Update Notification File fetch under the same `session_id`, and that it responds by discarding the delta chain for that round and falling back to the Snapshot File instead of applying an otherwise-valid new delta. The scenario requires three synchronization rounds, because a hash is only recorded once a delta has actually been applied (the very first, cold-cache synchronization uses the Snapshot File and has no applied delta to record):

1. An initial synchronization (serial 1) establishes the baseline repository state via the Snapshot File.
2. A second synchronization advances the session by one valid, correctly hashed delta (serial 1 → 2). The Relying Party applies it, and is expected to record its `serial` and `hash`.
3. A third synchronization advances again with a new, valid delta (serial 2 → 3). The Update Notification File for this round still lists the prior delta (serial 2) as part of its history, but with a `hash` value different from the one applied in round 2 — the file appears to have mutated without any change to `session_id` or the notification's current `serial`. The underlying Delta File for serial 2 is left untouched; the tamper is confined to the `hash` attribute of its entry in the notification.

The Relying Party MUST NOT apply the new, valid serial-3 delta in this round; it MUST fall back to downloading and processing the current Snapshot File, and the resulting object set MUST reflect that snapshot rather than an incrementally-applied delta.

---

### 3-b - `unchanged-delta-hashes-apply-new-delta`

**Description:**
This test checks the negative-control counterpart of test `3-a`: a Relying Party that detects no hash mutation must not spuriously distrust the delta chain. The scenario follows the same three-round structure (initial snapshot sync, then one applied delta from serial 1 to 2), but in the third round the prior delta (serial 2) is carried forward in the new Update Notification File with its `hash` value **unchanged** alongside the new, valid serial-3 delta. No mutation has occurred. The Relying Party MUST apply the new delta normally and MUST NOT fall back to the Snapshot File on account of the desynchronization check; the resulting object set reflects the incrementally-applied delta chain. This guards against an overly strict or miscalibrated implementation of the section 3 comparison producing false positives on perfectly ordinary, unmutated delta chains.

---

*End of RFC 9697 test suite — 2 test cases*
