# Rapport – Test Suite: ASN Boundary Values in ROAs and ASPAs
## 32-bit Unsigned ASN Encoding & Rendering at Range Boundaries

> **Scope:** This suite tests how the validator handles Autonomous System Numbers at the boundaries of the 32-bit unsigned integer range (0 to 4,294,967,295) in the two RPKI object types that carry ASNs: ROAs (single `asID`) and ASPAs (one `customerASID` plus a list of provider ASNs). Each test verifies two independent properties: (1) that the validator correctly validates and accepts an object carrying a boundary ASN, and (2) that the validator renders that ASN correctly in its output — as an unsigned 32-bit decimal in the range 0..4294967295 — with no signed-integer corruption.

> **Test identifiers:** Each test is tagged `<object>-<field>-<boundary>`, e.g. `roa-asid-int32-max-plus-one` or `aspa-customer-provider-uint32-max`. The object is `roa` or `aspa`; for ASPA the field tag indicates that both the customer and provider ASNs carry the boundary value in the same test.

---

## Key Concepts

| Concept | Impact on the RP under test |
|---|---|
| ASNs are unsigned 32-bit integers (0..4294967295) | Any signed interpretation corrupts values above INT32_MAX |
| INT32_MAX (2147483647) is the critical fault line | Values at and above this boundary expose signed/unsigned defects |
| ROA carries exactly one ASN (`asID`) | The boundary is tested in a single field per ROA |
| ASPA carries a customer ASN and a provider ASN list | The boundary is tested in two structurally distinct positions |
| AS0 has special RPKI meaning (RFC 6483) | The zero boundary is not just a numeric edge but a semantic one |

---

## Test Cases

---

### Group A — ROA `asID` Boundary Values

Each test builds a ROA whose single `asID` field carries one boundary value, paired with a fixed prefix. The validator must validate the ROA and emit a VRP whose ASN renders exactly as the unsigned decimal value.

---

#### a-1 — `roa-asid-as-zero`

**Description:**
A ROA with `asID` = 0. Per RFC 6483, an AS0 ROA is a valid object that declares the associated prefix must not be originated by any AS. This test verifies the validator accepts the AS0 ROA as structurally valid and applies AS0 semantics correctly rather than treating 0 as an invalid or absent ASN. The expected output follows the validator's AS0 handling (an AS0 VRP or the equivalent "disavow" record), not a normal origin VRP.

---

#### a-2 — `roa-asid-as-one`

**Description:**
A ROA with `asID` = 1. Verifies the smallest normal positive ASN validates and renders as `AS1`.

---

#### a-3 — `roa-asid-16bit-max`

**Description:**
A ROA with `asID` = 65535. Verifies the largest 16-bit ASN validates and renders as `AS65535`, confirming no truncation at the 16-bit boundary.

---

#### a-4 — `roa-asid-16bit-max-plus-one`

**Description:**
A ROA with `asID` = 65536. Verifies the first ASN that requires more than 16 bits validates and renders as `AS65536`, confirming the validator does not truncate to a 16-bit field.

---

#### a-5 — `roa-asid-int32-max`

**Description:**
A ROA with `asID` = 2147483647 (INT32_MAX). Verifies the largest value that still fits in a signed 32-bit integer validates and renders as `AS2147483647`. This is the last value before the signed/unsigned fault line.

---

#### a-6 — `roa-asid-int32-max-plus-one`

**Description:**
A ROA with `asID` = 2147483648 (INT32_MAX + 1). The validator must validate the ROA and render `AS2147483648`, never `AS-2147483648`.

---

#### a-7 — `roa-asid-large`

**Description:**
A ROA with `asID` = 4200000000, a large value well above INT32_MAX mirroring the reported AS4202202062 case. Verifies that the validator renders `AS4200000000`, never the signed-wrapped negative equivalent.

---

#### a-8 — `roa-asid-uint32-max-minus-one`

**Description:**
A ROA with `asID` = 4294967294 (uint32 max − 1). This mirrors the reported `-2` case. The validator must render `AS4294967294`, never `AS-2`.

---

#### a-9 — `roa-asid-uint32-max`

**Description:**
A ROA with `asID` = 4294967295 (0xFFFFFFFF, the absolute maximum). Verifies the top of the uint32 range validates and renders as `AS4294967295`, confirming no overflow, wraparound, or off-by-one at the field's upper bound.

---

#### a-10 — `roa-asid-uint32-max-plus-one`

**Description:**
A ROA with `asID` = 4294967296 (uint32 max + 1). Unlike the previous nine boundaries, this value is **outside** the representable range of a 32-bit unsigned ASN — it is the first value that no longer fits in the field. This test is therefore an out-of-range rejection test, not a valid boundary: the validator must not accept a ROA whose `asID` exceeds 4294967295, and must not emit any VRP for it.

---

### Group B — ASPA `customerASID` Boundary Values

Each test builds an ASPA whose `customerASID` carries one boundary value, paired with a fixed, valid provider ASN that is deliberately different from the customer value (draft-8210bis forbids the customerASID from appearing in the provider list). The validator must validate the ASPA and render the customer ASN exactly as its unsigned decimal value.

---

#### b-1 — `aspa-customer-as-zero`

**Description:**
An ASPA with `customerASID` = 0. Per draft-8210bis, AS0 is not a valid customer ASN. This test verifies that the validator rejects the ASPA and emits no ASPA record. (As with the ROA AS0 case, this is the one customer test whose expected result is rejection; it covers the zero boundary completely.)

---

#### b-2 — `aspa-customer-as-one`

**Description:**
An ASPA with `customerASID` = 1 and a fixed valid provider (e.g. AS65001). Verifies the smallest normal customer ASN validates and renders as `AS1`.

---

#### b-3 — `aspa-customer-16bit-max`

**Description:**
An ASPA with `customerASID` = 65535 and a fixed valid provider. Verifies the 16-bit maximum renders as `AS65535`.

---

#### b-4 — `aspa-customer-16bit-max-plus-one`

**Description:**
An ASPA with `customerASID` = 65536 and a fixed valid provider. Verifies the first 32-bit customer value renders as `AS65536`, with no 16-bit truncation.

---

#### b-5 — `aspa-customer-int32-max`

**Description:**
An ASPA with `customerASID` = 2147483647 (INT32_MAX) and a fixed valid provider. Verifies the signed-range edge renders as `AS2147483647`.

---

#### b-6 — `aspa-customer-int32-max-plus-one`

**Description:**
An ASPA with `customerASID` = 2147483648 (INT32_MAX + 1) and a fixed valid provider. The critical customer test: verifies that the validator renders `AS2147483648` in the customer position, never the signed-negative equivalent.

---

#### b-7 — `aspa-customer-large`

**Description:**
An ASPA with `customerASID` = 4200000000 and a fixed valid provider. Verifies a large above-INT32_MAX customer value renders as `AS4200000000`.

---

#### b-8 — `aspa-customer-uint32-max-minus-one`

**Description:**
An ASPA with `customerASID` = 4294967294 and a fixed valid provider. Verifies the `-2` defect case renders as `AS4294967294` in the customer position.

---

#### b-9 — `aspa-customer-uint32-max`

**Description:**
An ASPA with `customerASID` = 4294967295 (0xFFFFFFFF) and a fixed valid provider. Verifies the absolute uint32 maximum renders as `AS4294967295` in the customer position, with no overflow or off-by-one.

---

#### B-10 — `aspa-customer-uint32-max-plus-one`

**Description:**
An ASPA with `customerASID` = 4294967296 (uint32 max + 1) and a fixed valid provider. Unlike the previous customer boundaries, this value is **outside** the representable range of a 32-bit unsigned ASN — it is the first value that no longer fits in the field. This is an out-of-range rejection test, not a valid boundary: the validator must not accept an ASPA whose `customerASID` exceeds 4294967295, and must emit no ASPA record.

---

### Group C — ASPA Provider ASN Boundary Values

Each test builds an ASPA with a fixed, valid `customerASID` (deliberately different from the boundary value under test) and a provider list containing one entry carrying the boundary value. The validator must validate the ASPA and render the provider ASN exactly as its unsigned decimal value.

---

#### c-1 — `aspa-provider-as-zero`

**Description:**
An ASPA with a fixed valid customer and a provider list containing AS0. Per draft 8210bis, AS0 is a valid provider ASN. This test verifies the validator accepts the ASPA and emits the ASPA record.

---

#### c-2 — `aspa-provider-as-one`

**Description:**
An ASPA with a fixed valid customer (e.g. AS65001) and a provider list containing AS1. Verifies the smallest normal provider ASN validates and renders as `AS1`.

---

#### c-3 — `aspa-provider-16bit-max`

**Description:**
An ASPA with a fixed valid customer and a provider = 65535. Verifies the 16-bit maximum renders as `AS65535` in the provider position.

---

#### c-4 — `aspa-provider-16bit-max-plus-one`

**Description:**
An ASPA with a fixed valid customer and a provider = 65536. Verifies the first 32-bit provider value renders as `AS65536`, with no 16-bit truncation.

---

#### c-5 — `aspa-provider-int32-max`

**Description:**
An ASPA with a fixed valid customer and a provider = 2147483647 (INT32_MAX). Verifies the signed-range edge renders as `AS2147483647` in the provider position.

---

#### c-6 — `aspa-provider-int32-max-plus-one`

**Description:**
An ASPA with a fixed valid customer and a provider = 2147483648 (INT32_MAX + 1). The critical provider test: verifies the validator renders `AS2147483648` in the provider position, never the signed-negative equivalent.

---

#### c-7 — `aspa-provider-large`

**Description:**
An ASPA with a fixed valid customer and a provider = 4200000000. Verifies a large above-INT32_MAX provider value renders as `AS4200000000`.

---

#### c-8 — `aspa-provider-uint32-max-minus-one`

**Description:**
An ASPA with a fixed valid customer and a provider = 4294967294. Verifies the `-2` defect case renders as `AS4294967294` in the provider position.

---

#### c-9 — `aspa-provider-uint32-max`

**Description:**
An ASPA with a fixed valid customer and a provider = 4294967295 (0xFFFFFFFF). Verifies the absolute uint32 maximum renders as `AS4294967295` in the provider position, with no overflow or off-by-one.

---

#### c-10 — `aspa-provider-uint32-max-plus-one`

**Description:**
An ASPA with a fixed valid customer and a provider list containing 4294967296 (uint32 max + 1). Unlike the previous provider boundaries, this value is **outside** the representable range of a 32-bit unsigned ASN — it is the first value that no longer fits in the field. This is an out-of-range rejection test, not a valid boundary: the validator must not accept an ASPA whose provider ASN exceeds 4294967295, and must emit no ASPA record.

---

*End of ASN Boundary Values test suite — 30 test cases across 3 groups*