# Rapport – Test Suite: IP Address Syntax and Boundary Value Validation

> **Scope:** Tests verifying that an RPKI Relying Party correctly validates IP address prefixes, prefix lengths, and maxLength values in both certificate resource extensions (RFC 3779, referenced by RFC 6487 section 4.8.10) and ROA payloads (RFC 6482 / RFC 9582). The suite exercises boundary values, edge cases, and invalid combinations that a validator must handle correctly; either accepting valid resources and producing the correct VRPs, or rejecting invalid resources and suppressing the affected VRPs.
>
> ---
>
> **Motivation.** IP addresses in RPKI appear in two distinct ASN.1 structures:
>
> - **Certificate IP resources** (RFC 3779 `IPAddrBlocks`): encoded as BIT STRINGs where the significant bits equal the prefix length. These define what resources a CA is authorized to allocate.
> - **ROA IP address blocks** (RFC 6482 `ROAIPAddress`): each entry has a prefix (BIT STRING), an optional `maxLength` (INTEGER), and is grouped by address family. These define what prefixes an AS is authorized to originate.
>
> The validator must enforce constraints at both levels: structural validity of the BIT STRING encoding, prefix length bounds per address family, maxLength bounds and relationship to prefix length, and containment of ROA prefixes within the issuing CA's resources.

---

## Key Concepts

| Concept | RFC | Impact on validator |
|---|---|---|
| IPv4 prefix length MUST be in the range 0–32 | RFC 3779, RFC 6482 | A prefix with length > 32 must be rejected |
| IPv6 prefix length MUST be in the range 0–128 | RFC 3779, RFC 6482 | A prefix with length > 128 must be rejected |
| ROA maxLength must be >= prefix length | RFC 6482 section 3 | A ROA with maxLength < prefix length must be rejected |
| ROA maxLength must be <= 32 (IPv4) or <= 128 (IPv6) | RFC 6482 section 3 | A ROA with maxLength exceeding the address family limit must be rejected |
| ROA maxLength is optional; when absent it defaults to prefix length | RFC 6482 section 3 | A ROA without maxLength should produce a VRP with maxLength = prefix length |
| ROA prefixes must be contained within the issuing CA's IP resources | RFC 6482 section 4 | A ROA prefix outside the CA's resources must be rejected |
| A /0 prefix represents the entire address space of its family | RFC 3779 | The validator must accept /0 as a valid prefix |
| A /32 (IPv4) or /128 (IPv6) prefix represents a single host address | RFC 3779 | The validator must accept the maximum-length prefix as valid |

---

## Test Cases

---

## Group 1 — IPv4 Prefix Length Boundaries

---

### 01 - `ipv4-prefix-length-24-accepted`

**Description:**
This test checks that the validator accepts a ROA with a standard IPv4 prefix length (/24). Baseline sanity check confirming the fixture works before testing boundary values.

---

### 02 - `ipv4-prefix-length-0-accepted`

**Description:**
This test checks that the validator accepts a ROA with an IPv4 prefix of /0 (0.0.0.0/0), representing the entire IPv4 address space. A CA with all IPv4 resources issues a ROA for 0.0.0.0/0; the resulting VRP must appear.

---

### 03 - `ipv4-prefix-length-32-accepted`

**Description:**
This test checks that the validator accepts a ROA with an IPv4 prefix of /32 (a single host address). This is the maximum valid prefix length for IPv4 and must be handled correctly.

---

### 04 - `ipv4-prefix-length-33-rejected`

**Description:**
This test checks that the validator rejects a ROA with an IPv4 prefix length of /33, which exceeds the 32-bit address space. The BIT STRING encoding would require 5 bytes with 7 unused bits.
---

## Group 2 — IPv6 Prefix Length Boundaries

---

### 05 - `ipv6-prefix-length-48-accepted`

**Description:**
This test checks that the validator accepts a ROA with a standard IPv6 prefix length (/48). Baseline sanity check for IPv6.

---

### 06 - `ipv6-prefix-length-0-accepted`

**Description:**
This test checks that the validator accepts a ROA with an IPv6 prefix of /0 (::/0), representing the entire IPv6 address space. A CA with all IPv6 resources issues a ROA for ::/0; the resulting VRP must appear.

---

### 07 - `ipv6-prefix-length-128-accepted`

**Description:**
This test checks that the validator accepts a ROA with an IPv6 prefix of /128 (a single host address). This is the maximum valid prefix length for IPv6 and must be handled correctly.

---

### 08 - `ipv6-prefix-length-129-rejected`

**Description:**
This test checks that the validator rejects a ROA with an IPv6 prefix length of /129, which exceeds the 128-bit address space.

---

## Group 3 — ROA maxLength Validation (IPv4)

---

### 09 - `ipv4-maxlength-absent-defaults-to-prefix-length`

**Description:**
This test checks that the validator correctly handles a ROA with no maxLength field. RFC 6482 section 3 says maxLength defaults to the prefix length when absent. A ROA for 1.1.0.0/24 without maxLength must produce a VRP with maxLength = 24.

---

### 10 - `ipv4-maxlength-equals-prefix-length-accepted`

**Description:**
This test checks that the validator accepts a ROA whose maxLength equals its prefix length (e.g., 1.1.0.0/24 with maxLength = 24). This is the most restrictive valid maxLength and is explicitly permitted by RFC 6482 section 3.

---

### 11 - `ipv4-maxlength-greater-than-prefix-accepted`

**Description:**
This test checks that the validator accepts a ROA whose maxLength is greater than its prefix length but within bounds (e.g., 1.1.0.0/24 with maxLength = 28). The VRP must reflect maxLength = 28.

---

### 12 - `ipv4-maxlength-32-accepted`

**Description:**
This test checks that the validator accepts a ROA whose maxLength is 32; the maximum valid value for IPv4 (e.g., 1.1.0.0/24 with maxLength = 32). This allows the most specific announcements possible.

---

### 13 - `ipv4-maxlength-33-rejected`

**Description:**
This test checks that the validator rejects a ROA whose maxLength is 33, exceeding the IPv4 address family limit.

---

### 14 - `ipv4-maxlength-less-than-prefix-rejected`

**Description:**
This test checks that the validator rejects a ROA whose maxLength is less than its prefix length (e.g., 1.1.0.0/24 with maxLength = 20).

---

## Group 4 — ROA maxLength Validation (IPv6)

---

### 15 - `ipv6-maxlength-absent-defaults-to-prefix-length`

**Description:**
This test checks that the validator correctly handles a ROA with no maxLength field for an IPv6 prefix. A ROA for 2001:db8::/32 without maxLength must produce a VRP with maxLength = 32.

---

### 16 - `ipv6-maxlength-equals-prefix-length-accepted`

**Description:**
This test checks that the validator accepts a ROA whose maxLength equals its IPv6 prefix length (e.g., 2001:db8::/32 with maxLength = 32).

---

### 17 - `ipv6-maxlength-greater-than-prefix-accepted`

**Description:**
This test checks that the validator accepts a ROA whose maxLength is greater than its IPv6 prefix length but within bounds (e.g., 2001:db8::/32 with maxLength = 48). The VRP must reflect maxLength = 48.

---

### 18 - `ipv6-maxlength-128-accepted`

**Description:**
This test checks that the validator accepts a ROA whose maxLength is 128; the maximum valid value for IPv6. This allows the most specific announcements possible.

---

### 19 - `ipv6-maxlength-129-rejected`

**Description:**
This test checks that the validator rejects a ROA whose maxLength is 129, exceeding the IPv6 address family limit.

---

### 20 - `ipv6-maxlength-less-than-prefix-rejected`

**Description:**
This test checks that the validator rejects a ROA whose maxLength is less than its IPv6 prefix length (e.g., 2001:db8::/32 with maxLength = 24).

---

## Group 5 — ROA Resource Containment

---

### 21 - `roa-prefix-within-ca-resources-accepted`

**Description:**
This test checks that the validator accepts a ROA whose prefix is fully contained within the issuing CA's IP resources. The CA has 1.1.0.0/24; the ROA claims 1.1.0.0/24. Baseline sanity check for containment.

---

### 22 - `roa-prefix-outside-ca-resources-rejected`

**Description:**
This test checks that the validator rejects a ROA whose prefix is entirely outside the issuing CA's IP resources. The CA has 1.1.0.0/24; the ROA claims 10.0.0.0/24.

---

### 23 - `roa-prefix-broader-than-ca-resources-rejected`

**Description:**
This test checks that the validator rejects a ROA whose prefix is broader than the issuing CA's IP resources (the ROA encompasses the CA's range but exceeds it). The CA has 1.1.0.0/24; the ROA claims 1.1.0.0/16. Zero VRPs.

---

### 24 - `roa-prefix-narrower-than-ca-resources-accepted`

**Description:**
This test checks that the validator accepts a ROA whose prefix is a subset of the issuing CA's IP resources. The CA has 1.1.0.0/24; the ROA claims 1.1.0.0/25. The VRP must appear with the narrower prefix.

---

## Group 6 — Certificate Resource Boundaries

---

### 25 - `certificate-ipv4-slash-0-accepted`

**Description:**
This test checks that the validator accepts a CA certificate whose IP resources are 0.0.0.0/0 (all of IPv4). A subordinate ROA for 192.0.2.0/24 within that range must produce a VRP.

---

### 26 - `certificate-ipv4-slash-32-accepted`

**Description:**
This test checks that the validator accepts a CA certificate whose IP resources are a single /32 address (e.g., 192.0.2.1/32). A subordinate ROA for 192.0.2.1/32 must produce a VRP.

---

### 27 - `certificate-ipv6-slash-0-accepted`

**Description:**
This test checks that the validator accepts a CA certificate whose IP resources are ::/0 (all of IPv6). A subordinate ROA for 2001:db8::/32 within that range must produce a VRP.

---

### 28 - `certificate-ipv6-slash-128-accepted`

**Description:**
This test checks that the validator accepts a CA certificate whose IP resources are a single /128 address (e.g., 2001:db8::1/128). A subordinate ROA for 2001:db8::1/128 must produce a VRP.

---

*End of IP Address Syntax and Boundary Value Validation suite — 28 test cases*
