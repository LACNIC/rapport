# Rapport – Test Suite: draft-ietf-sidrops-8210bis
## The RPKI to Router Protocol, Version 2
### Reference version: draft-ietf-sidrops-8210bis-25

> **Scope:** Tests derived from this draft focus on the RPKI-to-Router (RTR)
> protocol that a cache uses to deliver validated RPKI data — IPv4/IPv6 prefix
> VRPs, Router Keys, and ASPA records — to routers. The cache server under test must
> correctly implement protocol version negotiation, PDU structure enforcement,
> session and serial management, incremental and full update sequences, and the
> specific semantics of ASPA and prefix payload PDUs including their delta
> (announce/withdraw) mechanics.

---

## Key Concepts

| Concept | Section | Impact on cache server under test |
|---|---|---|
| Protocol versions 0, 1, and 2 coexist; version is negotiated per session | section 7 | Cache must downgrade or reject based on router's offered version |
| Session ID binds a Serial Number space to one cache instance | section 5.1, section 2 | Session ID mismatch must cause Error Report and session teardown |
| Serial Number is a 32-bit strictly increasing counter; wrap-around applies | section 2, section 4, section 5.1 | Cache Reset must be issued when serial is outside the available window |
| Reset Query requests the full active database; Serial Query requests incremental changes | section 5.3, section 5.4 | Cache must respond correctly to each query type |
| Cache Has No Data Available is signaled with Error Report PDU | section 8.4 | Cache must not respond with payload PDUs when data is not yet available |
| PDU Length MUST NOT exceed 65,535 octets | section 5.1 | Fragmented or oversized PDUs must be handled or rejected |
| ASPA PDU announcement MUST contain at least one Provider AS; withdrawal MUST have no Provider list and Length == 12 | section 5.12 | Malformed ASPA PDUs must trigger Error Code 9 |
| For a given Customer AS, the router MUST see at most one active ASPA from a cache at any time | section 5.12 | Cache must merge multiple RPKI ASPA records into one PDU |
| Cache MUST merge announce/withdraw for same prefix/AS into minimal VRP | section 5.6 | Delta changes must be coalesced before delivery |
| Multiple distinct ROAs sharing one {Prefix, Len, Max-Len, AS} must produce exactly one VRP | section 5.6, section 5.7 | Cache must coalesce equivalent ROAs (cert reissuance, ownership transfer) so the router holds one VRP per tuple |
| Flags field lowest-order bit: 1 = announce, 0 = withdraw | section 5.1 | Incorrect flag values produce wrong router state |

---

## Test Cases

---

### section-4-5 - `serial-number-wraparound-at-2pow32-boundary`

**Description:**
This test checks that the cache treats the Serial Number as a 32-bit strictly
increasing unsigned integer that wraps from 2^32-1 (`0xFFFFFFFF`) to 0, and that it
uses RFC1982 Serial Number Arithmetic — not a naive unsigned comparison — when
computing the changes "since" the serial in a Serial Query. With the cache at serial
`0xFFFFFFFF` and the router synchronised to it, the cache completes one validated
update, wrapping its serial to `0` with a minimal delta. The router then sends a Serial Query 
carrying `0xFFFFFFFF`. The cache MUST recognise that `0xFFFFFFFF` precedes `0` by a single
increment — not that it is ahead — and respond with a Cache Response, the
one-increment delta (withdraw before announce), and an End of Data PDU carrying
Serial Number `0`. It MUST NOT treat `0xFFFFFFFF` as newer than `0` (returning an
empty delta) nor emit a Cache Reset, since the requested serial is still within the
window. A follow-up Serial Query at serial `0` then yields a null delta, confirming
`0` is the live current version and not an uninitialised or reset state.

**Related sections:** section 2 (Glossary — the Serial Number is a 32-bit strictly
increasing unsigned integer which wraps from 2^32-1 to 0, see [RFC1982], and is
incremented when the cache successfully completes an update), section 4 (the Serial
Number comparison used to determine changes "since the given Serial Number" MUST take
wrap-around into account, see [RFC1982]; the router adopts the serial carried in the
End of Data PDU), section 5.3 (the cache returns the minimum set of changes; a Cache
Reset is sent only when the requested serial is no longer available), section 5.8
(End of Data carries the cache's new Serial Number, here `0`), section 11.2.1 (all
withdraw PDUs are sent before any announce PDUs), [RFC1982] (for 32-bit serials,
`0xFFFFFFFF` is less than `0`).

---

### section-5.1-2.10 - `serial-query-with-incorrect-session-id`

**Description:**
This test checks that the cache detects a Session ID mismatch when a Serial Query
arrives carrying a Session ID that does not match the Session ID previously
established for the session, and responds by immediately terminating the session
with an Error Report PDU carrying Error Code 0 ("Corrupt Data"), causing the
router to flush all data learned from that cache.

**Related sections:** section 5.1 (if either the router or the cache finds that
the value of the Session ID it is using is not the same as the other's, the party
which detects the mismatch MUST immediately terminate the session with an Error
Report PDU with code 0, "Corrupt Data", and the router MUST flush all data learned
from that cache), section 5.3 (per section 5.1, if the Serial Query contains a
Session ID that is not equal to that previously established, the cache terminates
the session with an Error Report PDU with code 0)

---

### section-5.1-2.12 - `session-depends-on-version`

**Description:**
This test checks that the cache binds the Session ID to the negotiated protocol
version, so that sessions established at different versions are distinct even when
served by the same cache. The cache is probed with a Reset Query at protocol versions
0, 1, and 2 by two independent routers, and the Session ID carried in each Cache
Response is compared. For a given version, both routers MUST receive the same Session
ID (it identifies the cache's session for that version, independent of which router
asks); across versions, the same cache MUST issue different Session IDs
(v0 ≠ v1 ≠ v2). This follows from sessions being specific to a protocol version: a
Serial Number is commensurate only when Protocol Version, Session ID, and Serial
Number all match, so cache servers SHOULD NOT reuse a Session ID across versions, and
routers MUST treat sessions with different Protocol Version fields as separate even if
the Session ID happens to coincide.

**Related sections:** section 5.1 (Session ID — sessions are specific to a particular
protocol version; the full test for whether Serial Numbers are commensurate requires
comparing Protocol Version, Session ID, and Serial Number; to reduce the risk of
confusion cache servers SHOULD NOT use the same Session ID across multiple protocol
versions, but even if they do, routers MUST treat sessions with different Protocol
Version fields as separate sessions even if they happen to have the same Session ID),
section 7 (once a Protocol Version is negotiated it is fixed for the life of the
session; Session ID and Serial Number values are specific to a particular protocol
version, see section 5.1 for the interaction between Protocol Version and Session ID).

---

### section-5.3-3 - `serial-query-with-serial-equal-to-server-serial`

**Description:**
This test checks that the cache correctly responds to a Serial Query whose Serial
Number field is equal to the cache's current Serial Number — meaning the router
is already fully up to date — by sending a Cache Response followed immediately
by an End of Data PDU with no intervening payload PDUs, correctly signaling that
there are no changes to deliver.

**Related sections:** section 5.3 (the cache replies to a Serial Query with all
announcements and withdrawals which have occurred since the Serial Number
specified; this may be the null set, in which case the End of Data PDU is still
sent), section 4 (the cache responds to the Serial Query with all data changes
which took place since the given Serial Number; this may be the null set, in which
case the End of Data PDU is still sent)

---

### section-5.3-4-a - `aspa-net-zero-delta-across-multiple-serials`

**Description:**
This test checks that the cache coalesces intermediate ASPA changes across multiple
serial increments and returns a net-zero delta — an empty payload set — when the
queried range withdraws and then re-announces a record with identical content. ASPA A
is active at serial 1, withdrawn at serial 2, and re-announced unchanged at serial 3;
a Serial Query at serial 1 MUST therefore yield a Cache Response immediately followed
by an End of Data PDU with no intervening payload PDUs, since the net change for
Customer AS A is zero. The router retains ASPA A unchanged, its final table identical
to the pre-query state.

**Related sections:** section 5.3 (the cache MUST return the minimum set of
changes needed to bring the router to the current state; if a record underwent
multiple changes between the queried serial and the current serial and the net
result is no change, the data stream MUST NOT mention that record; the data stream
will include, for any given {Customer AS}, at most one withdrawal followed by at
most one announcement), section 5.12 (ASPA PDU semantics: a withdrawal removes
the record; a subsequent announcement with the same Customer AS reinstates it;
the cache MUST reflect only the net outcome when responding to a Serial Query
spanning multiple serials).

---

### section-5.3-4-b - `roa-net-zero-delta-across-multiple-serials`

**Description:**
This test checks that the cache coalesces intermediate IPv4/IPv6 Prefix VRP changes
across multiple serial increments and returns a net-zero delta — an empty payload set
— when the queried range withdraws and then re-announces a ROA with an identical
`{Prefix, Len, Max-Len, AS}` tuple. ROA R is active at serial 1, withdrawn at serial
2, and re-announced unchanged at serial 3; a Serial Query at serial 1 MUST yield a
Cache Response immediately followed by an End of Data PDU with no intervening payload
PDUs, since the net change for the tuple is zero. The router retains ROA R unchanged,
its final table identical to the pre-query state.

**Related sections:** section 5.3 (the cache MUST return the minimum set of
changes needed to bring the router to the current state; if a record underwent
multiple changes between the queried serial and the current serial and the net
result is no change, the data stream MUST NOT mention that record; the data stream
will include, for any given {Prefix, Len, Max-Len, AS}, at most one withdrawal
followed by at most one announcement), section 5.6 (IPv4 Prefix PDU semantics:
a withdrawal with Flags=0 deletes one previously announced Prefix PDU with the
exact same Prefix, Length, Max-Len, and AS; a subsequent announcement with the
same tuple reinstates it; the cache MUST reflect only the net outcome when
responding to a Serial Query spanning multiple serials).

---

### section-5.3-4-c - `high-cardinality-mixed-bulk-delta`

**Description:**
This test checks that the cache correctly produces a large-scale incremental update
spanning all three payload PDU types — IPv4 Prefix, IPv6 Prefix, and ASPA — within a
single serial increment, with no omissions, duplicates, or ordering violations. The
two validated snapshots are constructed so that the sorted record lists interleave
additions and removals (every other entry changes between snapshots), stressing all
branches of the cache's internal sort-and-diff algorithm.

It also verifies the distinct update semantics per payload type: a VRP
`{Prefix, Len, Max-Len, AS}` tuple change is expressed as a withdrawal of the old
tuple followed by an announcement of the new one, whereas an ASPA provider-list change
is expressed as a single replacement announcement (`Flags=1`) with no prior
withdrawal. The expected delta totals 170 payload PDUs — 70 ASPA (10 modified
announcements, 30 withdrawals, 30 new announcements), 80 IPv4 Prefix (10 withdraw + 10
announce for Max-Len changes, 30 withdrawals, 30 announcements), and 20 IPv6 Prefix
(10 withdrawals, 10 announcements) — delivered with all withdrawals before
announcements for the IP Prefix PDUs. The router's resulting table MUST match the
serial-2 dataset exactly: 55 ASPAs, 55 IPv4 VRPs, and 10 IPv6 VRPs.

**Related sections:** section 5.3 (the cache MUST return the minimum set of changes
needed to bring the router to the current state; multiple changes for the same
record MUST be merged), section 5.6 (IPv4 Prefix PDU; `Flags=1` announces,
`Flags=0` withdraws; the identity key is the full `{Prefix, Len, Max-Len, AS}`
tuple; changing any field requires a withdrawal of the old tuple and an announcement
of the new one), section 5.7 (the behaviour specified for IPv4 Prefix PDU is also
applicable to IPv6 Prefix PDU), section 5.12 (ASPA PDU; the identity key is the
Customer AS alone; receipt of an ASPA PDU announcement when the router already holds
an ASPA for the same Customer AS replaces the previous record — no prior withdrawal
is required or expected; `Flags=0` withdraws the entire record, `Length=12`, no
Provider list), section 11.2.1 (IP Prefix PDUs: caches MUST send all withdraw PDUs
before any announce PDUs within a Serial Query response; this ordering requirement
applies to IPv4 and IPv6 Prefix PDUs and does not extend to ASPA PDUs, whose
replacement semantics make an explicit withdrawal unnecessary).

---

### section-5.6-3-a - `ipv4-prefix-delta-simple-change-adding-prefix`

**Description:**
This test checks that during a simple incremental update covering a single serial
increment, the cache correctly delivers an IPv4 Prefix PDU with the Flags field
set to 1 (announce) for a newly added IPv4 VRP, with all fields correctly populated
including a Prefix whose unused bits are zeroed, and that the cache has not
delivered a prior withdrawal for the same tuple in the same delta.

**Related sections:** section 5.6 (IPv4 Prefix PDU; announcement flag = 1; the
cache server MUST set the remaining bits of the Prefix to zero; the cache MUST
ensure that it has told the router to have one and only one IPv4 VRP for a unique
{Prefix, Len, Max-Len, AS} at any one point in time), section 8.2 (Typical
Exchange).

---

### section-5.6-3-b - `ipv4-prefix-delta-simple-change-updating-as`

**Description:**
This test checks that during a simple incremental update, the cache correctly
represents a change to the Autonomous System Number associated with an existing
IPv4 prefix by delivering a withdrawal PDU for the old {Prefix, Len, Max-Len,
old-AS} tuple followed by an announcement PDU for the new {Prefix, Len, Max-Len,
new-AS} tuple, and that the cache does not attempt to deliver these as a single
in-place update, since the {Prefix, Len, Max-Len, AS} tuple is the primary key
for VRP identity.

**Related sections:** section 5.6 (a withdrawal deletes one previously announced
Prefix PDU with the exact same Prefix, Length, Max-Len, and AS; changing the AS
effectively means withdrawing the old entry and announcing a new one), section 5.3
(the cache MUST merge changes to present the simplest possible view), section 11.2.1
(caches MUST send all withdraw PDUs before any announce PDUs).

---

### section-5.6-3-c - `ipv4-prefix-delta-bulk-change-adding-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an IPv4 Prefix PDU with the Flags field set to 1 (announce) for each
IPv4 VRP that was newly added to the RPKI dataset within the queried serial range,
with correct Prefix, Prefix Length, Max Length, and Autonomous System Number
fields, and that the cache merges multiple changes for the same {Prefix, Len,
Max-Len, AS} tuple into at most one announcement.

**Related sections:** section 5.6 (IPv4 Prefix PDU; the lowest-order bit of the
Flags field is 1 for an announcement), section 5.3 (the cache MUST return the
minimum set of changes; if a prefix underwent multiple changes, the cache MUST
merge those changes; the data stream will include at most one withdrawal followed
by at most one announcement).

---

### section-5.6-3-d - `ipv4-prefix-delta-bulk-change-removing-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an IPv4 Prefix PDU with the Flags field set to 0 (withdraw) for each
IPv4 VRP that was removed from the RPKI dataset within the queried serial range,
with the exact same {Prefix, Len, Max-Len, AS} tuple as the previously announced
record, effectively deleting the router's stored VRP entry.

**Related sections:** section 5.6 (the lowest-order bit of the Flags field is 0
for a withdrawal; a withdraw effectively deletes one previously announced Prefix
PDU with the exact same Prefix, Length, Max-Len, and AS), section 5.3 (the cache
MUST merge changes; if all changes cancel out, the data stream will not mention
the prefix/AS at all).

---

### section-5.6-5 - `equivalent-roas-coalesced-to-single-vrp`

**Description:**
This test checks that the cache delivers one and only one IPvX VRP for a unique
`{Prefix, Len, Max-Len, AS}` tuple even when its validated dataset holds multiple
distinct ROAs that map to that same router-level tuple — a real RPKI occurrence during
certificate reissuance or an address-ownership transfer up the validation chain, where
the ROAs differ only in validation path (important to the RPKI, not to the router).
With ROA-A and ROA-B (different CAs/paths) both authorizing `{10.1.0.0/16-16, AS
10001}` present at once, a Reset Query MUST yield exactly one IPv4 Prefix PDU
(`Flags=1`) for the tuple — not two — and the router holds a single entry (a router
receiving the tuple twice SHOULD raise Error Code 7). Across a reissuance where ROA-A
is removed but the equivalent ROA-B remains, the Serial Query response MUST contain no
IPv4 Prefix PDU for the tuple: the VRP stays continuously present and the change is
invisible to the router. The same behaviour applies to IPv6 VRPs (section 5.7).

**Related sections:** section 5.6 (IPv4 Prefix — in the RPKI there is an actual need
for what may appear to a router as identical IPvX PDUs, e.g. an upstream certificate
being reissued or an address-ownership transfer up the validation chain; such ROAs
share the same `{Prefix, Len, Max-Len, AS}` but differ in validation path, which is
important to the RPKI but not to the router; the cache server MUST ensure it has told
the router client to have one and only one IPvX VRP for a unique
`{Prefix, Len, Max-Len, AS}` at any one point in time; the cache MUST merge
announce/withdraw ROAs for the same tuple into the minimal or no VRP; a router
receiving a tuple identical to one already active SHOULD raise a Duplicate
Announcement Received error), section 5.7 (the behaviour specified for the IPv4 Prefix
PDU is also applicable to the IPv6 Prefix PDU), section 5.3 (the cache returns the
minimum set of changes; if changes cancel out, the data stream does not mention the
prefix/AS at all), section 12 (Error Code 7, Duplicate Announcement Received).

---

### section-5.7-3-a - `ipv6-prefix-delta-simple-change-adding-prefix`

**Description:**
This test checks that during a simple incremental update covering a single serial
increment, the cache correctly delivers an IPv6 Prefix PDU with the Flags field
set to 1 (announce) for a newly added IPv6 VRP, with all 128-bit prefix bits
beyond the prefix length zeroed, and that the cache ensures the router holds one
and only one VRP for the unique {Prefix, Len, Max-Len, AS} tuple at that point in
time.

**Related sections:** section 5.7 (IPv6 Prefix PDU; the behaviour for IPv4 Prefix
PDU applies, including zeroing unused prefix bits and the one-and-only-one VRP
constraint), section 8.2 (Typical Exchange).

---

### section-5.7-3-b - `ipv6-prefix-delta-simple-change-updating-as`

**Description:**
This test checks that during a simple incremental update, the cache correctly
represents a change to the Autonomous System Number associated with an existing
IPv6 prefix by delivering a withdrawal PDU for the old {Prefix, Len, Max-Len,
old-AS} tuple followed by an announcement PDU for the new {Prefix, Len, Max-Len,
new-AS} tuple, and that the withdrawal is delivered before the announcement in
accordance with the ordering requirements for IP Prefix PDUs.

**Related sections:** section 5.7 (behaviour for IPv6 Prefix PDU mirrors that of
IPv4 Prefix PDU; a withdrawal deletes one previously announced Prefix PDU with the
exact same Prefix, Length, Max-Len, and AS; changing the AS requires a withdrawal
and a new announcement), section 11.2.1 (IP Prefix PDUs: caches MUST send all
withdraw PDUs before any announce PDUs).

---

### section-5.7-3-c - `ipv6-prefix-delta-bulk-change-adding-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an IPv6 Prefix PDU with the Flags field set to 1 (announce) for each
IPv6 VRP newly added within the queried serial range, with correct 128-bit Prefix,
Prefix Length (0..128), Max Length (0..128), and Autonomous System Number fields,
and with unused prefix bits zeroed, merging multiple changes for the same tuple
into at most one announcement.

**Related sections:** section 5.7 (IPv6 Prefix PDU; the behaviour specified for
the IPv4 Prefix PDU is also applicable to the IPv6 Prefix PDU; PDU Length=32),
section 5.3 (the cache MUST return the minimum set of changes and MUST merge
multiple changes for the same prefix/AS).

---

### section-5.7-3-d - `ipv6-prefix-delta-bulk-change-removing-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an IPv6 Prefix PDU with the Flags field set to 0 (withdraw) for each
IPv6 VRP removed within the queried serial range, with the exact same {Prefix,
Len, Max-Len, AS} tuple as the previously announced record, effectively deleting
the router's stored IPv6 VRP entry.

**Related sections:** section 5.7 (the behaviour specified for the IPv4 Prefix PDU
is also applicable to the IPv6 Prefix PDU; a withdrawal deletes one previously
announced Prefix PDU with the exact same fields), section 5.3 (if all changes for
a prefix/AS cancel out, the data stream will not mention it at all).

---

### section-5.9-2 - `serial-query-with-serial-outside-of-window`

**Description:**
This test checks that the cache responds to a Serial Query whose Serial Number
refers to a point in history that is no longer available in the cache's incremental
update window — because the cache has since cleaned up old delta data or the
router waited too long between polls — by sending a Cache Reset PDU, informing
the router that it cannot provide an incremental update from that serial and must
fall back to a Reset Query.

**Related sections:** section 5.9 (the cache sends a Cache Reset PDU in response
to a Serial Query in order to inform the router that the cache cannot provide an
incremental update starting from the Serial Number specified by the router),
section 8.3 (No Incremental Update Available: the cache may respond to a Serial
Query with a Cache Reset, informing the router that the cache cannot supply an
incremental update from the specified Serial Number)

---

### section-5.12-6 - `multiple-aspa-records-unioned-to-single-pdu`

**Description:**
This test checks that when the cache's validated data holds multiple distinct valid
ASPA records for the same Customer AS, it forms the union of their Provider AS sets and
delivers exactly one ASPA PDU for that Customer AS — so the router sees at most one
active ASPA per Customer AS from the cache. With record R1 `{10001, 10002}` and record
R2 `{10002, 10003}` for Customer AS 10 present at once, a Reset Query MUST yield a
single ASPA PDU (`Flags=1`) carrying the union `{10001, 10002, 10003}` in increasing
order with no duplicate — never two PDUs for the same Customer AS. When a contributing
record changes (R2 replaced by R2' `{10004}`, making the union `{10001, 10002,
10004}`), the Serial Query response MUST carry a single replacement announcement with
the new merged list and no prior withdrawal; only if the union becomes empty is a
single withdrawal (`Flags=0`, `Length=12`) sent. The merged announcement must still
satisfy the ASPA PDU constraints: at least one provider, unique and in increasing
numeric order, and no AS 0 in a multi-provider PDU (otherwise Error Code 9).

**Related sections:** section 5.12 (ASPA PDU — the router MUST see at most one ASPA
from a particular cache for a particular Customer AS active at any time; because the
global RPKI may present multiple valid ASPA records for a single customer to one RP
cache, the cache MUST form the union of those records into one ASPA PDU; receipt of an
ASPA announcement for a Customer AS the router already holds replaces the previous one,
so no prior withdrawal is required; the cache MUST deliver the complete data of an ASPA
record in a single PDU; Provider AS numbers appear in increasing numeric order and each
MUST be unique; an announcement MUST contain at least one Provider AS or Error Code 9
is returned; a multi-provider announcement MUST NOT contain AS 0 or Error Code 9 is
returned; `Flags=0` withdraws the entire record with `Length=12` and no Provider list),
section 5.3 (the cache returns the minimum set of changes, merging multiple changes for
the same ASPA/Customer into at most one withdrawal followed by at most one
announcement; if changes cancel out the Customer AS is not mentioned), section 11.2.3
(ASPA PDU ordering is by Customer AS, with announcements before withdrawals), section
10 (when combining ASPA data, AS 0 handling must be reconciled — a cache excludes AS 0
from a synthesised multi-provider list).

---

### section-5.12-7-a - `aspa-delta-simple-change-adding-provider`

**Description:**
This test checks that during a simple incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for an existing Customer AS to
which one new Provider AS was added in the single serial increment being queried,
with the updated complete provider list in ascending numerical order, replacing
the previous record at the router.

**Related sections:** section 5.12 (receipt of an ASPA PDU announcement when the
router already has an ASPA PDU with the same Customer AS replaces the previous
one; the cache MUST deliver the complete data of an ASPA record in a single ASPA
PDU; each Provider AS Number MUST be unique and in increasing numeric order)

---

### section-5.12-7-b - `aspa-delta-simple-change-removing-provider`

**Description:**
This test checks that during a simple incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for an existing Customer AS from
which one Provider AS was removed in the single serial increment being queried,
with the updated complete provider list reflecting the removal and in ascending
numerical order.

**Related sections:** section 5.12 (receipt of an ASPA PDU announcement when the
router already has an ASPA PDU with the same Customer AS replaces the previous
one; the cache MUST deliver the complete data of an ASPA record in a single ASPA
PDU)

---

### section-5.12-7-c - `aspa-delta-bulk-change-adding-provider`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for a Customer AS whose provider
list was extended with one or more new Provider AS entries within the queried
serial range, with the updated and complete provider list in ascending numerical
order, replacing the previously announced record at the router.

**Related sections:** section 5.12 (receipt of an ASPA PDU announcement when the
router already has an ASPA PDU with the same Customer Autonomous System Number
from that cache replaces the previous one; the cache MUST deliver the complete
data of an ASPA record in a single ASPA PDU; Provider AS Numbers MUST be in
increasing numeric order), section 5.3 (the cache MUST merge multiple changes to
present the simplest possible view).

---

### section-5.12-7-d - `aspa-delta-bulk-change-removing-provider`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for a Customer AS whose provider
list was reduced by the removal of one or more Provider AS entries within the
queried serial range, with the updated and complete provider list reflecting the
removal, replacing the previously announced record at the router.

**Related sections:** section 5.12 (receipt of an ASPA PDU announcement when the
router already has an ASPA PDU with the same Customer AS replaces the previous
one; the cache MUST deliver the complete data of an ASPA record in a single ASPA
PDU), section 5.3 (the cache MUST merge changes to present the simplest possible
view).

---

### section-5.12-8-a - `aspa-delta-simple-change-adding-customer`

**Description:**
This test checks that during a simple incremental update (Serial Query response
covering a single serial increment), the cache correctly delivers an ASPA
announcement PDU for a newly added Customer AS, with the Flags field set to 1
(announce) and containing the complete initial provider list in ascending order.

**Related sections:** section 5.12 (the Flags field set to 1 indicates the
announcement of a new ASPA record; an ASPA announcement PDU MUST contain at
least one Provider Autonomous System Number), section 8.2 (Typical Exchange:
the cache sends all data newer than the serial in the Serial Query)

---

### section-5.12-8-b - `aspa-delta-bulk-change-adding-customer`

**Description:**
This test checks that during a bulk incremental update (Serial Query response
covering multiple serial increments), the cache correctly delivers an ASPA
announcement PDU for a Customer AS that was newly added to the RPKI dataset
within the queried serial range, with the Flags field set to 1 (announce) and
containing the complete provider list as it exists at the cache's current serial.

**Related sections:** section 5.12 (the ASPA PDU Flags field set to 1 indicates
the announcement of a new ASPA record or a replacement for a previously announced
record; receipt of an ASPA PDU announcement when the router already has an ASPA
PDU with the same Customer AS replaces the previous one), section 5.3 (the cache
MUST return the minimum set of changes needed to bring the router into sync;
multiple changes between serial numbers MUST be merged)

---

### section-5.12-9-a - `aspa-delta-simple-change-removing-customer`

**Description:**
This test checks that during a simple incremental update, the cache correctly
delivers an ASPA withdrawal PDU for a Customer AS that was entirely removed
in the single serial increment being queried, with the Flags field set to 0
(withdraw), no Provider list, and PDU Length equal to 12.

**Related sections:** section 5.12 (if the announce/withdraw flag is set to 0,
the entire ASPA record MUST be removed from the router; there MUST be no Provider
list and the PDU Length MUST be 12)

---

### section-5.12-9-b - `aspa-delta-bulk-change-removing-customer`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an ASPA withdrawal PDU for a Customer AS that was entirely removed from
the RPKI dataset within the queried serial range, with the Flags field set to 0
(withdraw), only the Customer AS Number present, no Provider list, and the PDU
Length equal to 12.

**Related sections:** section 5.12 (if the announce/withdraw flag is set to 0,
the entire ASPA record from that cache for that Customer AS MUST be removed from
the router; in this case the Customer AS MUST be provided, there MUST be no
Provider list, and the PDU Length MUST be 12).

---

### section-7-1 - `supported-version-2`

**Description:**
This test checks that the cache correctly establishes a session at protocol
version 2 when a router sends an initial query with Protocol Version field set
to `2`, responds with a Cache Response at version `2`, and supports the full
feature set of version 2 including ASPA PDUs throughout the session.

**Related sections:** section 7 (once a router has established a transport
connection to a cache, it MUST attempt to open a session by issuing a Reset Query
or Serial Query with the highest version the router implements; if the cache
supports that version, it responds with a Cache Response of that version and the
session is considered open)

---

### section-7-3-a - `supported-version-0`

**Description:**
This test checks that the cache correctly establishes a session at protocol
version 0 when a router sends an initial Reset Query or Serial Query with
Protocol Version field set to `0`, responding with a Cache Response at version
`0` and conducting the entire subsequent exchange using only PDUs with the
version 0 format, without including version-2-only features such as ASPA PDUs.

**Related sections:** section 7 (if a cache which supports version C receives a
query with Protocol Version Q < C, and the cache can support version Q, the cache
MUST establish the session at protocol version Q and respond with a Cache Response
of that Protocol Version; all PDUs MUST have the negotiated lower version number
in their version fields)

---

### section-7-3-b - `supported-version-1`

**Description:**
This test checks that the cache correctly establishes a session at protocol
version 1 when a router sends an initial query with Protocol Version field set
to `1`, responds with a Cache Response at version `1`, and uses only PDUs
compatible with version 1 for the duration of the session, omitting ASPA PDUs
which are exclusive to version 2.

**Related sections:** section 7 (if the cache can support version Q, the cache
MUST establish the session at protocol version Q and respond with a Cache Response
of that Protocol Version; in any downgraded combination, new features of the
higher version will not be available)

---

### section-7-4 - `unsupported-version`

**Description:**
This test checks that the cache correctly rejects a version negotiation attempt
when a router sends an initial query with a Protocol Version that the cache
does not support — specifically a version higher than the cache's maximum
supported version — by responding with an Error Report PDU carrying Error Code 4
("Unsupported Protocol Version") at the cache's own highest supported version,
and that the router can then retry at a lower version.

**Related sections:** section 7 (if the cache which supports version C receives a
query of version Q > C, the cache MUST send an Error Report with Protocol Version
C and Error Code 4; the router SHOULD send another query with Protocol Version Q
equal to the version C in the Error Report)

---

### section-7-12 - `unexpected-version`

**Description:**
This test checks that once a protocol version has been successfully negotiated
and the session is considered open, the cache drops the session and sends an
Error Report PDU with Error Code 8 ("Unexpected Protocol Version") if it
subsequently receives any PDU carrying a Protocol Version field that differs from
the negotiated version, except when that PDU is itself an Error Report PDU.

**Related sections:** section 7 (if either party receives a PDU for a different
Protocol Version once negotiation completes, that party MUST drop the session;
unless the PDU containing the unexpected Protocol Version was itself an Error
Report PDU, the party dropping the session SHOULD send an Error Report with
Error Code 8, "Unexpected Protocol Version")

---

### section-8.4-2 - `reset-query-with-no-data-available`

**Description:**
This test checks that the cache responds to a Reset Query with an Error Report PDU
indicating that no data is available — rather than a Cache Response followed by an
empty payload set — when the cache has not yet successfully built or recovered its
RPKI dataset, for example immediately after a restart before the first validated
fetch from the Global RPKI completes.

**Related sections:** section 8.4 (the cache may respond to a Reset Query with an
Error Report PDU informing the router that the cache cannot supply any update at
all; the most likely cause is that the cache has lost state and has not yet
recovered; a router is more likely to see this when it initially connects and
issues a Reset Query while the cache is still rebuilding its database)

---

### section-9-1-a - `fragmented-reset-query`

**Description:**
This test checks that the cache correctly handles a Reset Query PDU that arrives
fragmented across multiple TCP segments — i.e., the complete 8-octet PDU is not
received in a single read — by reassembling it correctly before processing, and
responding with the expected Cache Response followed by the full active dataset
and an End of Data PDU, without errors caused by partial PDU processing.

**Related sections:** section 5.4 (Reset Query PDU has a fixed Length=8; the cache
responds with a Cache Response followed by zero or more payload PDUs and an End of
Data PDU), section 9 (the transport-layer session carries binary PDUs in a
persistent reliable session; a cache SHOULD NOT use a separate TCP segment for
each PDU, implying routers must handle PDUs that span segments).

---

### section-9-1-b - `fragmented-serial-query`

**Description:**
This test checks that the cache correctly handles a Serial Query PDU that arrives
fragmented across multiple TCP segments — i.e., the complete 12-octet PDU is split
across at least two reads — by fully reassembling it before processing, and
responding with the expected incremental update (or Cache Reset if the serial is
outside the window) without errors attributable to partial PDU reception.

**Related sections:** section 5.3 (Serial Query PDU has a fixed Length=12; the
cache replies with a Cache Response if it has a record of changes since the Serial
Number specified by the router, followed by zero or more payload PDUs and an End
of Data PDU), section 9 (transport carries binary PDUs in a persistent reliable
session)

---

### section-12-2.12 - `unsupported-pdu-type`

**Description:**
This test checks that the cache correctly handles receiving a PDU whose PDU Type
field contains a value not recognized or supported in the negotiated protocol
version, by responding with an appropriate Error Report PDU and either terminating
or recovering the session gracefully, without crashing or entering an undefined
state.

**Related sections:** section 5.1 (PDU Type is an 8-bit unsigned integer denoting
the type of the PDU; the protocol is extensible to support new PDUs with new
semantics), section 5.11 (Error Report PDU is used by either party to report an
error to the other), section 12 (Error Codes — implementations should report
unrecognized PDU types).

---

*End of draft-ietf-sidrops-8210bis-25 test suite — 35 test cases*