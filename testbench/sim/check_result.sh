#!/bin/sh
#=============================================================================
# check_result.sh -- ket luan PASS/FAIL cho 1 test tu log UVM.
#
# Dung:
#   ./check_result.sh <logfile> [ten_test]
#
# Tieu chi PASS (phai thoa CA 3):
#   1. File log ton tai
#   2. Log co "UVM Report Summary"  -> sim chay den cuoi (khong crash/treo)
#   3. UVM_ERROR == 0  VA  UVM_FATAL == 0
#
# Vi sao phai check (2): neu sim crash hay bi timeout, log co the KHONG co dong
# "UVM_ERROR : n" nao -> dem duoc 0 loi va bao PASS gia. Bat buoc phai thay
# Report Summary moi tin con so.
#
# Lay so tu muc "Report counts by severity" cua UVM:
#     UVM_ERROR :    0
# Cac dong bao loi le ("UVM_ERROR /path/file.sv(12) @ ...") KHONG khop regex
# '^UVM_ERROR *:' nen khong bi dem nham.
#
# Exit code: 0 = PASS, 1 = FAIL  (de Makefile/CI dung duoc)
#=============================================================================

log="$1"
name="$2"

if [ -z "$log" ]; then
    echo "usage: $0 <logfile> [ten_test]" >&2
    exit 2
fi
# Khong truyen ten -> lay tu ten file log
if [ -z "$name" ]; then
    name=$(basename "$log" .log)
fi

# ---- (1) log co ton tai khong ----
if [ ! -f "$log" ]; then
    printf '  %-6s %-42s %s\n' "FAIL" "$name" "khong tim thay log ($log)"
    exit 1
fi

# ---- (2) sim co chay den cuoi khong ----
if ! grep -q "UVM Report Summary" "$log"; then
    printf '  %-6s %-42s %s\n' "FAIL" "$name" "sim khong ket thuc (thieu UVM Report Summary)"
    exit 1
fi

# ---- (3) dem UVM_ERROR / UVM_FATAL tu bang tong ket ----
# '(# )?' de phong truong hop log co tien to '# ' cua transcript Questa.
nerr=$(grep -E '^(# )?UVM_ERROR *:' "$log" | tail -1 | grep -oE '[0-9]+' | tail -1)
nfat=$(grep -E '^(# )?UVM_FATAL *:' "$log" | tail -1 | grep -oE '[0-9]+' | tail -1)
[ -z "$nerr" ] && nerr=0
[ -z "$nfat" ] && nfat=0

if [ "$nerr" -eq 0 ] && [ "$nfat" -eq 0 ]; then
    printf '  %-6s %-42s %s\n' "PASS" "$name" "UVM_ERROR=0 UVM_FATAL=0"
    exit 0
else
    printf '  %-6s %-42s %s\n' "FAIL" "$name" "UVM_ERROR=$nerr UVM_FATAL=$nfat"
    exit 1
fi
