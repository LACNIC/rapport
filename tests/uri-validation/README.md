# Rapport – Test Suite: Certificate URI Field Validation
## SIA / AIA Extension URI Sanitization and Conformance

> **Scope:** Tests verifying that an RPKI Relying Party correctly validates and sanitizes the URI values carried in the SIA (Subject Information Access) and AIA (Authority Information Access) certificate extensions before using them as network endpoints or converting them to local filesystem paths. Every URI in these extensions is a `uniformResourceIdentifier` inside a `GeneralName` (RFC 5280 section 4.2.1.6), which is defined as **IA5String** — code points 0x00–0x7F only. On top of that encoding constraint, each field has its own scheme requirement (rsync or https) and the validator must never use a malformed URI as a filesystem path without sanitization.
>
> ---
>
> **Motivation — FORT issue #119.** When Fort downloads an object via rsync, it maps the URI's path suffix directly to a local cache path:
>
> ```
> rsync://host/rpki/test/ca/A.roa   →   /cache/rsync/.../test/ca/A.roa
>                 ─────────────                         ─────────────
>                 suffix copied directly to local path
> ```
>
> This algorithmic conversion is the attack surface: if the URI contains path traversal sequences (`../../`), control characters, or double-slash / dot-dot combinations that Unix and RFC 3986 interpret differently, an attacker who controls a certificate's SIA/AIA content could read or overwrite files outside the intended cache directory. The suite exercises this surface systematically across all URI-bearing fields and across two distinct threat layers:
>
> - **Filesystem-path attacks (T8, T9, T10):** only apply to fields whose scheme is `rsync://`, because Fort maps those URIs to local paths. Fields with scheme `https://` (rpkiNotify) are never converted to filesystem paths, so path traversal is not a risk there.
> - **Encoding / syntax attacks (T1–T7):** apply to all fields regardless of scheme — they test scheme conformance, IA5String encoding, URI syntax, and robustness against malformed inputs.
>
> ---
>
> **Anchoring.** Tests are named as `<field>-t<N>-<vector>`, e.g. `sia-carepository-t8-path-traversal`. Each field has a P0 baseline that confirms the fixture works before comparing against the attack vectors.

---

## URI Fields Under Test

| # | Field | Extension | RFC | Required scheme | Barry override path | URI→path risk |
|---|---|---|---|---|---|---|
| 1 | **caRepository** | SIA | RFC 6487 section 4.8.8.1 | `rsync://` | `sia.extnValue.0.accessLocation.value` | Yes |
| 2 | **rpkiManifest** | SIA | RFC 6487 section 4.8.8.1 | `rsync://` | `sia.extnValue.1.accessLocation.value` | Yes |
| 3 | **rpkiNotify** | SIA | RFC 8182 section 3.2 | `https://` | `rpp.notification` | No |
| 4 | **caIssuers** | AIA | RFC 6487 section 4.8.7 | `rsync://` | `aia.extnValue.0.accessLocation.value` | Yes |

---

## Test Vectors

### Layer 1 — Scheme validation (all fields)

| Vector | Tag | Attack |
|---|---|---|
| **T1** | `wrong-scheme` | Valid RPKI scheme, wrong for the field (`https://` in rsync field, `rsync://` in rpkiNotify) |
| **T2** | `foreign-scheme` | Scheme outside the RPKI transport set entirely (`ftp://`) |

**Anchoring:** RFC 6487 section 4.8.8 (SIA caRepository and rpkiManifest require rsync), RFC 6487 section 4.8.7 (AIA caIssuers requires rsync), RFC 8182 section 3.2 (rpkiNotify requires https).

---

### Layer 2 — Encoding conformance (all fields)

| Vector | Tag | Attack |
|---|---|---|
| **T3** | `non-ia5-utf8` | Byte outside IA5 (0x00–0x7F) that IS valid UTF-8 (e.g. `ó`, U+00F3, bytes 0xC3 0xB3) |
| **T4** | `non-ia5-non-utf8` | Byte outside IA5 (0x00–0x7F) that is NOT valid UTF-8 (e.g. 0xFF) |
| **T5** | `control-chars` | Raw control character within IA5 range but prohibited in URIs (e.g. tab 0x09) |

**T3/T4 anchoring:** RFC 5280 section 4.2.1.6 (`GeneralName` `uniformResourceIdentifier` is `IA5String`), ITU-T T.50 / ISO 646 (IA5 character set: 0x00–0x7F).

**T5 anchoring:** RFC 3986 section 2.4 (control characters are excluded from URI syntax and must be percent-encoded or absent).

---

## Layer 3 — URI syntax (all fields)

| Vector | Tag | Attack |
|---|---|---|
| **T6** | `empty` | Empty string (not a valid URI for any access method) |
| **T7** | `no-host` | Empty host component (`rsync:///path` or `https:///path`) |

**T6 anchoring:** RFC 6487 section 4.8.8 (SIA: caRepository, rpkiManifest), RFC 6487 section 4.8.7 (AIA: caIssuers), RFC 8182 section 3.2 (SIA: rpkiNotify) — accessLocation must be a meaningful URI in all cases.

**T7 anchoring:** Scheme-specific requirement — both rsync and https need a host to be meaningful. Note: RFC 3986 section 3.2.2 technically allows an empty `reg-name`, so this is a scheme-level violation, not a generic-syntax one.

---

### Layer 4 — Filesystem-path attacks (rsync fields only)

> These vectors exploit the algorithmic conversion of rsync URI suffixes to local filesystem paths (issue #119). They do **not** apply to `rpkiNotify` (https), because that URI is never converted to filesystem paths.

| Vector | Tag | Attack |
|---|---|---|
| **T8** | `path-traversal` | `/../../../` sequences within the rsync path to escape the cache directory |
| **T9** | `double-slash-dot-dotting` | `//..` sequences exploiting the `//` semantic difference between Unix and RFC 3986 |
| **T10** | `percent-encoded-traversal` | `%2E%2E` (percent-encoded `..`) to bypass dot-segment filters that check literal `..` but not its encoded form |

**T8 anchoring:** Issue #119, CWE-22 (Path Traversal). The traversal sequences are placed **after** the rsync module path (`rpki/`), within the suffix that Fort maps to the local filesystem, so rsync itself does not reject them before Fort sees them.

**T9 anchoring:** Issue #119, RFC 3986 section 3.3 (empty path segments), RFC 3986 section 5.2.4 (dot-segment removal). The attack exploits that `//` means different things:

| Interpreter | `ca//..` resolves to |
|---|---|
| Unix filesystem | `ca/..` → go up past `ca` (compresses `//` to `/`) |
| RFC 3986 | `ca/` → `..` removes the empty segment, not `ca` |

If the validator converts the URI to a path without normalizing under RFC 3986 rules first, Unix applies its own interpretation and each `//..` escapes one more level than the URI semantically allows.

**T10 anchoring:** Issue #119, RFC 3986 section 2.3 (unreserved characters are equivalent whether percent-encoded or not), CWE-22. The dot character (`.`, 0x2E) is `unreserved` in RFC 3986, so `%2E` MUST be decoded to `.` during normalization. A correct normalizer decodes `%2E%2E` → `..` and then resolves the dot-segment. A naive filter that looks for literal `..` without first decoding percent-encoding would miss `%2E%2E` entirely — a classic web security bypass. This test confirms that Fort's decode→normalize pipeline runs in the correct order.

---

## Applicability Matrix

| Vector | Layer | caIssuers | caRepository | rpkiManifest | rpkiNotify |
|---|---|---|---|---|---|
| **T1** wrong-scheme | Scheme | ✓ | ✓ | ✓ | ✓ |
| **T2** foreign-scheme | Scheme | ✓ | ✓ | ✓ | ✓ |
| **T3** non-ia5-utf8 | Encoding | ✓ | ✓ | ✓ | ✓ |
| **T4** non-ia5-non-utf8 | Encoding | ✓ | ✓ | ✓ | ✓ |
| **T5** control-chars | Encoding | ✓ | ✓ | ✓ | ✓ |
| **T6** empty | Syntax | ✓ | ✓ | ✓ | ✓ |
| **T7** no-host | Syntax | ✓ | ✓ | ✓ | ✓ |
| **T8** path-traversal | Filesystem | ✓ | ✓ | ✓ | — |
| **T9** double-slash-dot | Filesystem | ✓ | ✓ | ✓ | — |
| **T10** pct-encoded-traversal | Filesystem | ✓ | ✓ | ✓ | — |

---

## Complete Test Inventory

> Every row is a separate test directory under `tests/fort-uri-validation/`. All attack vectors assert **zero VRPs** (`check_vrps` with no arguments). The P0 baseline asserts the VRP is **present** (`check_vrps "..."`) confirming the fixture works.

### AIA caIssuers — 11 tests

| Directory | Vector | Injected value | Assertion |
|---|---|---|---|
| `aia-caissuers-p0-baseline` | — | `rsync://localhost:8873/rpki/$TEST/ta.cer` (explicit) | VRP present |
| `aia-caissuers-t1-wrong-scheme` | T1 | `https://localhost:8443/$TEST/ta.cer` | 0 VRPs |
| `aia-caissuers-t2-foreign-scheme` | T2 | `ftp://localhost/rpki/$TEST/ta.cer` | 0 VRPs |
| `aia-caissuers-t3-non-ia5-utf8` | T3 | `rsync://localhost:8873/rpki/$TEST/tá.cer` | 0 VRPs |
| `aia-caissuers-t4-non-ia5-non-utf8` | T4 | `rsync://localhost:8873/rpki/$TEST/t\xFFa.cer` | 0 VRPs |
| `aia-caissuers-t5-control-chars` | T5 | `rsync://localhost:8873/rpki/$TEST/t\ta.cer` | 0 VRPs |
| `aia-caissuers-t6-empty` | T6 | *(empty string)* | 0 VRPs |
| `aia-caissuers-t7-no-host` | T7 | `rsync:///rpki/$TEST/ta.cer` | 0 VRPs |
| `aia-caissuers-t8-path-traversal` | T8 | `rsync://localhost:8873/rpki/$TEST/../../../etc/passwd` | 0 VRPs |
| `aia-caissuers-t9-double-slash-dot` | T9 | `rsync://localhost:8873/rpki/$TEST//..//..//../../etc/passwd` | 0 VRPs |
| `aia-caissuers-t10-pct-encoded-traversal` | T10 | `rsync://localhost:8873/rpki/$TEST/%2E%2E/%2E%2E/%2E%2E/etc/passwd` | 0 VRPs |

### SIA caRepository — 11 tests

| Directory | Vector | Injected value | Assertion |
|---|---|---|---|
| `sia-carepository-p0-baseline` | — | `rsync://localhost:8873/rpki/$TEST/ca` (explicit) | VRP present |
| `sia-carepository-t1-wrong-scheme` | T1 | `https://localhost:8443/$TEST/ca` | 0 VRPs |
| `sia-carepository-t2-foreign-scheme` | T2 | `ftp://localhost/rpki/$TEST/ca` | 0 VRPs |
| `sia-carepository-t3-non-ia5-utf8` | T3 | `rsync://localhost:8873/rpki/$TEST/cá` | 0 VRPs |
| `sia-carepository-t4-non-ia5-non-utf8` | T4 | `rsync://localhost:8873/rpki/$TEST/c\xFF` | 0 VRPs |
| `sia-carepository-t5-control-chars` | T5 | `rsync://localhost:8873/rpki/$TEST/c\ta` | 0 VRPs |
| `sia-carepository-t6-empty` | T6 | *(empty string)* | 0 VRPs |
| `sia-carepository-t7-no-host` | T7 | `rsync:///rpki/$TEST/ca` | 0 VRPs |
| `sia-carepository-t8-path-traversal` | T8 | `rsync://localhost:8873/rpki/$TEST/ca/../../../etc/passwd` | 0 VRPs |
| `sia-carepository-t9-double-slash-dot` | T9 | `rsync://localhost:8873/rpki/$TEST/ca//..//..//../../etc/passwd` | 0 VRPs |
| `sia-carepository-t10-pct-encoded-traversal` | T10 | `rsync://localhost:8873/rpki/$TEST/ca/%2E%2E/%2E%2E/%2E%2E/etc/passwd` | 0 VRPs |

### SIA rpkiManifest — 11 tests

| Directory | Vector | Injected value | Assertion |
|---|---|---|---|
| `sia-rpkimanifest-p0-baseline` | — | `rsync://localhost:8873/rpki/$TEST/ca/ca.mft` (explicit) | VRP present |
| `sia-rpkimanifest-t1-wrong-scheme` | T1 | `https://localhost:8443/$TEST/ca/ca.mft` | 0 VRPs |
| `sia-rpkimanifest-t2-foreign-scheme` | T2 | `ftp://localhost/rpki/$TEST/ca/ca.mft` | 0 VRPs |
| `sia-rpkimanifest-t3-non-ia5-utf8` | T3 | `rsync://localhost:8873/rpki/$TEST/ca/cá.mft` | 0 VRPs |
| `sia-rpkimanifest-t4-non-ia5-non-utf8` | T4 | `rsync://localhost:8873/rpki/$TEST/ca/ca\xFF.mft` | 0 VRPs |
| `sia-rpkimanifest-t5-control-chars` | T5 | `rsync://localhost:8873/rpki/$TEST/ca/ca\t.mft` | 0 VRPs |
| `sia-rpkimanifest-t6-empty` | T6 | *(empty string)* | 0 VRPs |
| `sia-rpkimanifest-t7-no-host` | T7 | `rsync:///rpki/$TEST/ca/ca.mft` | 0 VRPs |
| `sia-rpkimanifest-t8-path-traversal` | T8 | `rsync://localhost:8873/rpki/$TEST/ca/../../../etc/passwd` | 0 VRPs |
| `sia-rpkimanifest-t9-double-slash-dot` | T9 | `rsync://localhost:8873/rpki/$TEST/ca/ca.mft//..//..//..//../../etc/passwd` | 0 VRPs |
| `sia-rpkimanifest-t10-pct-encoded-traversal` | T10 | `rsync://localhost:8873/rpki/$TEST/ca/%2E%2E/%2E%2E/%2E%2E/etc/passwd` | 0 VRPs |

### SIA rpkiNotify — 8 tests

| Directory | Vector | Injected value | Assertion |
|---|---|---|---|
| `sia-rpkinotify-p0-baseline` | — | `https://localhost:8443/$TEST/notif-ca.xml` (explicit) | VRP present |
| `sia-rpkinotify-t1-wrong-scheme` | T1 | `rsync://localhost:8873/rpki/$TEST/notification.xml` | 0 VRPs |
| `sia-rpkinotify-t2-foreign-scheme` | T2 | `ftp://localhost/$TEST/notification.xml` | 0 VRPs |
| `sia-rpkinotify-t3-non-ia5-utf8` | T3 | `https://localhost:8443/$TEST/notificación-ca.xml` | 0 VRPs |
| `sia-rpkinotify-t4-non-ia5-non-utf8` | T4 | `https://localhost:8443/$TEST/notificati\xFFn-ca.xml` | 0 VRPs |
| `sia-rpkinotify-t5-control-chars` | T5 | `https://localhost:8443/$TEST/notificat\tion-ca.xml` | 0 VRPs |
| `sia-rpkinotify-t6-empty` | T6 | *(empty string)* | 0 VRPs |
| `sia-rpkinotify-t7-no-host` | T7 | `https:///$TEST/notification-ca.xml` | 0 VRPs |

*T8, T9 and T10 do not apply — rpkiNotify URIs (https) are never converted to filesystem paths.*

---

*Suite total: **41 test cases** (4 baselines + 37 attack vectors) across 4 URI fields and 10 attack vectors.*
