# Rapport – Test Suite: RFC 8182
## The RPKI Repository Delta Protocol (RRDP)

> **Scope:** Tests derived from RFC 8182 focus on the behavior that a Relying Party MUST enforce when interacting with an RRDP repository. The validator must correctly process the Update Notification File and verify its session_id against local state (section 3.4.1), apply Delta Files only when a contiguous serial chain exists (section 3.4.1, 3.4.2), fall back to the Snapshot File whenever a Delta File is rejected (section 3.4.2), enforce hash verification for both Delta and Snapshot Files (sections 3.4.2, 3.4.3), guard against cross-server object withdrawal (section 3.4.2), cross-check session_id and serial between the Snapshot File and the Notification File (section 3.5.2.3), reject malformed Delta Files that violate the RELAX NG schema (section 3.5.3.3), discard all prior session state on re-initialization (section 3.3.1), and preserve its last known good cache when the repository is entirely unreachable (section 3.4.5).

> **Test identifiers:** Each test is identified by the **paragraph anchor** of the main paragraph it relates to in `RFC 8182` (e.g. `#section-3.4.1` → `3.4.1`). When more than one test relates to the same paragraph, a sub-index (`-a`, `-b`, `-c`, …) is appended (`3.4.1-a`, `3.4.1-b`, …).

---

## Key Concepts

| Concept | Section | Impact on validator |
|---|---|---|
| Relying Party records session_id and serial on first fetch; a changed session_id MUST trigger a full resync via the Snapshot File | section 3.4.1 | Validator must detect session_id mismatch and discard incremental state |
| If no contiguous chain of Delta Files exists from the last known serial to the current one, the Relying Party MUST fall back to the Snapshot File | section 3.4.1 | Validator must recognize gaps in the delta sequence and not apply a partial chain |
| The hash of every Delta File MUST be verified against the value in the Update Notification File before the file is processed | section 3.4.2 | A hash mismatch MUST cause the delta to be rejected; the validator MUST then fall back to the Snapshot File |
| The serial declared inside a Delta File MUST match the serial the notification attributes to that delta | section 3.4.2 | A mismatch between the delta's internal serial and the announced serial MUST cause the delta to be rejected |
| A withdraw or replace may only act on an object the issuing repository actually published | section 3.4.2 | Validator must reject a withdraw targeting an object its own repository never published |
| The hash of every Snapshot File MUST be verified against the value in the Update Notification File before the file is processed | section 3.4.3 | A hash mismatch MUST cause the snapshot to be rejected |
| The session_id and serial in a Snapshot File MUST match the values referenced in the Update Notification File | section 3.5.2.3 | Validator must cross-check both attributes and reject the file on any mismatch |
| A Relying Party MUST reject any Delta File that is not well-formed or does not conform to the RELAX NG schema | section 3.5.3.3 | Malformed or schema-violating Delta Files must be rejected; the validator falls back to the Snapshot File |
| On re-initialization the Repository Server generates a new session_id and serial ONE; a Relying Party that detects the new session_id MUST discard all prior state | section 3.3.1 | Validator must not retain any delta or object state from a previous session |
| On RRDP failure the Relying Party first attempts the SIA-advertised rsync mechanism; if rsync also fails, it keeps its last known good cache | section 3.4.5 | When both RRDP and the rsync fallback fail, the validator must preserve cached objects rather than produce an empty or reduced VRP set |

---


## Test Cases

---

### 3.4.1-a - `session-id-mismatch-triggers-snapshot-fallback`

**Description:**
This test checks that the validator detects a change in the `session_id` attribute of the Update Notification File relative to the last known value it recorded for that notification location, discards all delta-based incremental state associated with the previous session, and performs a full resynchronization by downloading and processing the Snapshot File referenced in the current Update Notification File. The validator MUST NOT attempt to apply any Delta Files belonging to the superseded session.

---

### 3.4.1-b - `delta-chain-gap-triggers-snapshot-fallback`

**Description:**
This test checks that the validator detects a gap in the sequence of Delta Files advertised by the Update Notification File — that is, a state in which no contiguous chain of delta serial numbers exists between the validator's last processed serial and the current repository serial — abandons the incremental update path, and falls back to downloading and processing the current Snapshot File.

---

### 3.4.2-a - `delta-hash-mismatch-rejected`

**Description:**
This test checks that the validator verifies the SHA-256 hash of each downloaded Delta File against the `hash` attribute of the corresponding `<delta>` element in the Update Notification File, rejects any Delta File whose content does not match the advertised hash, and immediately falls back to processing the current Snapshot File rather than proceeding with any subsequent deltas. The test supplies a Delta File whose content has been tampered with so that its actual hash diverges from the value in the Notification File. The validator MUST NOT apply any changes from the rejected delta to its local object store.

---

### 3.4.2-b - `delta-serial-mismatch-rejected`

**Description:**
This test checks that the validator verifies the serial number declared inside a Delta File against the serial that the Update Notification File attributes to that delta, and rejects the delta when the two do not match. The test presents a contiguous, correctly-counted single-delta update (so this is distinct from a non-contiguous delta chain) in which the Delta File's own root-element `serial` attribute differs from the `serial` of the `<delta>` reference that lists it in the notification — for example, the notification advertises the delta as serial 2 while the Delta File internally declares serial 99. The file's content hash is kept consistent with the notification so that hash verification passes first and the serial check is the operative one. The validator MUST reject the delta on the internal-versus-announced serial mismatch and fall back to processing the current Snapshot File.

---

### 3.4.2-c - `withdraw-of-object-not-published-by-this-repository-rejected`

**Description:**
This test checks the effective enforcement of the same-Repository-Server requirement: a `<withdraw>` (or a replacing `<publish>`) may only act on an object the issuing repository actually published. A validator that scopes each repository's object set to that repository's own notification enforces this structurally — a withdraw targeting a URI the repository never published cannot resolve to a known file. The test presents a contiguous, correctly-counted single-delta update whose delta has been augmented with an extra `<withdraw>` for a URI this notification never published (a `.roa` at a foreign repository path); the delta's content hash is kept consistent with the notification so hash verification passes first and the unknown-object check is the operative one. The validator MUST reject the delta and fall back to processing the current Snapshot File, leaving its object store unchanged for the foreign URI.

---

### 3.4.3 - `snapshot-hash-mismatch-rejected`

**Description:**
This test checks that the validator verifies the SHA-256 hash of a downloaded Snapshot File against the `hash` attribute of the `<snapshot>` element in the Update Notification File, and rejects the Snapshot File if the content does not match the advertised hash. Because a rejected Snapshot File means that RRDP cannot be used for the affected repository at this time, the validator MUST NOT import any objects from the corrupted snapshot into its validated object store, and MUST treat the repository as unreachable for this validation run, falling back to whatever alternative access mechanism is configured.

---

### 3.4.5 - `rrdp-and-rsync-fallback-both-fail-cache-preserved`

**Description:**
This test checks the Relying Party's behavior when RRDP fails, the Relying Party falls back to the rsync access mechanism advertised in the SIA, and **rsync also fails**. The point is the correct ordering and the final resort: RRDP failure does not go straight to "keep the old cache" — the Relying Party must first attempt the SIA-advertised alternate mechanism (rsync); only when that alternate mechanism is also unusable may the Relying Party fall back to its last known good cache.

The publication point advertises both an `rpkiNotify` (RRDP) and a `caRepository` (rsync) SIA. After an initial successful synchronization that populates the cache, both transports are made unusable for a second validation run: RRDP fails (the repository becomes unreachable, or a fetched file is rejected) and the rsync fallback also fails (the rsync endpoint is unreachable). The validator MUST then preserve all previously validated objects in its local cache and MUST NOT discard or invalidate them solely because both transports are unavailable; the second run's effective VRP set MUST remain consistent with the last known good state from the first run.

---

### 3.5.2.3-a - `snapshot-session-id-cross-check`

**Description:**
This test checks that the validator verifies the `session_id` declared inside a downloaded Snapshot File against the `session_id` the Update Notification File associates with it, and rejects the snapshot when they do not match. The snapshot is reached through a session-change resync (so the validator already holds a valid RRDP cache, avoiding the cold-cache snapshot path), and its internal `session_id` is altered so it no longer matches the value announced by the notification, while the snapshot's content hash is kept consistent with the notification so that hash verification passes first and the `session_id` cross-check is the operative one. The validator MUST reject the snapshot; with no usable RRDP path it falls back to the alternate access mechanism advertised in the SIA (rsync).

---

### 3.5.2.3-b - `snapshot-serial-cross-check`

**Description:**
This test checks that the validator verifies the `serial` declared inside a downloaded Snapshot File against the `serial` the Update Notification File associates with it, and rejects the snapshot when they do not match. As in the `session_id` case, the snapshot is reached through a session-change resync to avoid the cold-cache snapshot path, and its internal `serial` is altered so it no longer matches the announced serial, with the content hash kept consistent so that hash verification passes first and the `serial` cross-check is the operative one. The validator MUST reject the snapshot; with no usable RRDP path it falls back to the alternate access mechanism advertised in the SIA (rsync).

---

### 3.5.3.3-a - `delta-malformed-xml-rejected`

**Description:**
This test checks that the validator rejects a Delta File that is not well-formed XML, does not apply any object changes from the invalid file, and falls back to the current Snapshot File. The delta's root element is closed with a mismatched tag so the document is not well-formed; its content hash is kept consistent with the notification so that hash verification passes first and the well-formedness check is the operative one. Because a rejected delta (unlike a rejected snapshot) still leaves a valid RRDP snapshot to fall back to, the validator converges on the snapshot contents.

---

### 3.5.3.3-b - `delta-wrong-namespace-rejected`

**Description:**
This test checks that the validator rejects a Delta File whose XML namespace is not `http://www.ripe.net/rpki/rrdp`, does not apply any object changes from it, and falls back to the current Snapshot File. The delta's root-element `xmlns` is rewritten to a foreign namespace; its content hash is kept consistent with the notification so that hash verification passes first and the schema check is the operative one. The validator converges on the snapshot contents.

---

### 3.5.3.3-c - `delta-invalid-version-rejected`

**Description:**
This test checks that the validator rejects a Delta File whose `version` attribute is not `"1"`, does not apply any object changes from it, and falls back to the current Snapshot File. The delta's root-element `version` is set to `"2"`; its content hash is kept consistent with the notification so that hash verification passes first and the schema check is the operative one. The validator converges on the snapshot contents.

---

*End of RFC 8182 test suite — 12 test cases*
