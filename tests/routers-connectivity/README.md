# Rapport – Test Suite: Routers Connectivity
## RTR End-to-End Connectivity and Data Propagation

> **Scope:** This suite contains different tests, one per routing platform. Each test
> verifies that the validator's RTR component can establish a session with the
> target router, complete the initial data transfer, and that the router correctly
> populates its RPKI resource tables with the data received from the validator.
> These are end-to-end interoperability tests, not protocol conformance tests.
> No specific RFC or draft section is the normative basis for pass/fail; the
> acceptance criterion is that the router's RPKI table matches the dataset served
> by the validator after the first successful exchange.

---

## Test Cases

---

### 01 - `connection-and-data-transfer-to-bird`

**Platform:** BIRD 3.2.1

**Description:**
This test checks that after the RPKI validator and a BIRD 3.2.1 instance are
started and allowed to interconnect, BIRD successfully establishes an RTR session
with the validator, completes the initial Reset Query and Cache Response exchange,
receives all active payload PDUs from the validator, and populates its RPKI
resource tables such that the VRPs and ASPA records visible via BIRD's operational
commands match the dataset served by the validator.

**Related sections:** No specific RFC section — platform interoperability test.

---

### 02 - `connection-and-data-transfer-to-cisco`

**Platform:** Cisco CSR1000v

**Description:**
This test checks that after the RPKI validator and a Cisco CSR1000v instance are
started and allowed to interconnect, the CSR1000v successfully establishes an RTR
session with the validator, completes the initial Reset Query and Cache Response
exchange, receives all active payload PDUs from the validator, and populates its
RPKI resource tables such that the VRPs visible via Cisco's operational commands
match the dataset served by the validator.

**Related sections:** No specific RFC section — platform interoperability test.

---

### 03 - `connection-and-data-transfer-to-frr`

**Platform:** FRR 10.6.0

**Description:**
This test checks that after the RPKI validator and an FRR 10.6.0 instance are
started and allowed to interconnect, FRR successfully establishes an RTR session
with the validator, completes the initial Reset Query and Cache Response exchange,
receives all active payload PDUs from the validator, and populates its RPKI
resource tables such that the VRPs and ASPA records visible via FRR's operational
commands match the dataset served by the validator.

**Related sections:** No specific RFC section — platform interoperability test.

---

*End of router connectivity test suite — 3 test cases*
