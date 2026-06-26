# Rapport – Test Suite: RFC 9674
## Same-Origin Policy for the RPKI Repository Delta Protocol (RRDP)

> **Scope:** RFC 9674 (Standards Track, December 2024) updates RFC 8182 by imposing a Same-Origin Policy (SOP) on RRDP. The tests in this suite cover the Relying Party requirements added by section 3.2: that every `uri` attribute in the Update Notification File (the `<snapshot>` reference and any `<delta>` references) MUST share the same origin — scheme, host, and port — as the Update Notification File itself. A same-origin violation means the file (or the RRDP session) MUST be rejected and RRDP cannot be used; per RFC 8182 section 3.4.5, the Relying Party then falls back to an alternate access mechanism advertised in the SIA (rsync).

---

## Key Concepts

| Concept | Section | Impact on validator |
|---|---|---|
| Cross-origin references let one Repository Server point at another, inflating resource use for clients and the referenced server | section 2 | The Relying Party must refuse to act on a notification that references foreign-origin resources |
| Every `uri` in the Update Notification File MUST share the notification's scheme, host, and port | section 3.1 (server), section 3.2 (RP) | A `<snapshot>` or `<delta>` reference at a different origin makes the notification invalid |
| On a same-origin verification failure, the file MUST be rejected and RRDP cannot be used | section 3.2 | The whole notification is rejected — no snapshot fallback, since the snapshot is referenced by that same notification |
| The Relying Party MUST NOT follow HTTP redirection toward a different origin when fetching RRDP files | section 3.2 | A cross-origin redirect on the notification, snapshot, or delta causes the RRDP session to be rejected |
| When RRDP cannot be used, the Relying Party falls back to an alternate access mechanism per the SIA | RFC 8182 section 3.4.5 | rsync (RFC 6481 section 3) is the mandatory fallback transport |

---

## Test Cases

---

### 3.2-a - `notification-cross-origin-uri-rejected`

**Description:**
This test checks that the Relying Party verifies that the `uri` attributes in the Update Notification File share the same origin — scheme, host, and port — as the Update Notification File itself, and rejects the notification when a referenced `uri` points to a different origin. The condition is a property of the notification document, so rejecting it means rejecting the entire Notification File rather than only the offending reference: the `<snapshot>` reference and its hash live inside the same notification, so once the notification is rejected the snapshot it advertises cannot be used either, and there is no fallback to the RRDP snapshot. With no usable RRDP path for the repository, the Relying Party is expected to fall back to an alternate access mechanism advertised in the SIA — rsync.

---

### 3.2-b - `notification-cross-origin-redirect-rejected`

**Description:**
This test checks that the Relying Party does not follow HTTP redirection toward a different origin when downloading the Update Notification, Snapshot, or Delta files. The harness serves the Notification File URI (or a referenced Snapshot/Delta URI) as an HTTP 3xx redirect whose `Location` points to a different origin than the one advertised in the RRDP SIA AccessDescription. The Relying Party MUST NOT follow the redirect; it MUST reject the RRDP session and treat RRDP as unusable, then fall back to rsync per the SIA.

---

*End of RFC 9674 test suite — 2 test case*
