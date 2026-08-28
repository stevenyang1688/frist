FB_MonthlyCopy - README

Purpose
- Copies per-room DINT values from D[500..797] to R[] targets on each month 26 at 00:00:00 (single-shot).
- Uses year parity and month to select the R base address. Matches the mapping rules provided by the user.

Mapping and formulas
- Source (each room = DINT = 2 words):
  srcFirst = 500 + (floor - 2) * 50 + (roomIndex - 1) * 2
  where roomIndex = room number's last two digits (e.g., 201 -> 1)
  Valid source range: D[500] .. D[797]

- Target (per month, per parity):
  baseAddr = (isEvenYear ? 5000 : 1000) + (month - 1) * 300
  dstFirst = baseAddr + (floor - 2) * 50 + (roomIndex * 2 - 1)

- Floor/room counts used in code:
  - Floor 2: 10 rooms (201..210)
  - Floors 3..7: 24 rooms each (e.g., 301..324)
  Total rooms covered: 130 rooms (2楼10 + 5楼*24 = 130)

Trigger and edge-detection
- Trigger condition: D[3]=26 AND D[4]=0 AND D[5]=0 AND D[6]=0
- Rising-edge detection: uses internal bit M100 as previous-state store.
  - M100 is an internal bit. Mark as Retain in the PLC variable settings if you want it retained across power cycles.

Variable attributes (clarified)
- D[...] (e.g., D[500..797])
  - Type: Data registers (16-bit words). In usage each room is a DINT (32-bit) stored as two adjacent D words (low first, then high).
  - Scope: Internal PLC registers (not physical inputs/outputs).

- R[...] (e.g., R[1001], R[5001], ...)
  - Type: Internal holding registers (16-bit words).
  - Scope: Internal PLC registers; can be exposed as Modbus Holding Registers in your Modbus configuration.

- M100
  - Type: Internal bit (flag). Used for edge detection. Set Retain if required.

Deployment & Test Steps
1. Add FB_MonthlyCopy.ST to your AUTOSHOP project (Function Blocks / Structured Text area).
2. Ensure the time registers D[1..6] are populated by RTC or other source.
3. Ensure D[500..797] contain expected test data for selected rooms.
4. Set M100 = FALSE for initial test (unless Retain desired).
5. Manually set D[1..6] to simulate trigger: e.g., Year=2026, Month=8, Day=26, Hour=0, Min=0, Sec=0 and do a forced single scan/run of the FB.
6. Verify R[] target addresses for few rooms (2楼 201..203) to confirm proper low/high word order and address mapping.
7. Confirm Modbus master reads R[] in same word-order and reconstructs DINT accordingly.

Notes and differences vs Siemens
- This code uses D[]/R[]/M bits naming conventions (WeCl/Autoshop). Siemens uses DB/MW/QX naming — do not translate names blindly.
- Writes are low-word then high-word. Ensure the Modbus master reads in the same ordering.

If you want:
- I can convert this FB to Ladder (LD) or to a project export snippet.
- I can mark M100 as Retain in the project file if you confirm Retain is desired.

Commit information
- Files added: FB_MonthlyCopy.ST, README_AUTOSHOP_MONTHLY_COPY.md

