//------------------------------------------------------------------------------
// boot_seq_item.sv
//
// Transaction describing one boot configuration applied to the DMAC before
// reset deassertion. Because the boot signals are static, a single item
// programs the values that the driver then holds stable across the reset edge
// and through the boot-fetch window.
//------------------------------------------------------------------------------
`ifndef BOOT_SEQ_ITEM_SV
`define BOOT_SEQ_ITEM_SV

class boot_seq_item extends uvm_sequence_item;

  // ADDR_WIDTH used for constraint/printing. Set from the config (or default).
  int unsigned addr_width = 32;

  // Table A-11 values --------------------------------------------------------
  rand bit                    boot_en;        // enable automatic booting
  rand bit [63:2]             boot_addr;       // word-aligned boot descriptor addr
  rand boot_memattr_hi_e      memattr_hi;     // boot_memattr[7:4]
  rand bit [3:0]              memattr_lo;     // boot_memattr[3:0]
  rand boot_shareattr_e       shareattr;      // boot_shareattr[1:0]

  // Optional security context (TRM 4.9.1: ch0 boots Secure when SECEXT=1).
  // When set, the address is constrained to the [secure_base, secure_limit)
  // window so the boot descriptor lands in Secure memory.
  bit                         secext_present  = 0;
  bit [63:0]                  secure_base     = '0;
  bit [63:0]                  secure_limit    = '1;

  `uvm_object_utils_begin(boot_seq_item)
    `uvm_field_int (boot_en,    UVM_DEFAULT)
    `uvm_field_int (boot_addr,  UVM_DEFAULT | UVM_HEX)
    `uvm_field_enum(boot_memattr_hi_e, memattr_hi, UVM_DEFAULT)
    `uvm_field_int (memattr_lo, UVM_DEFAULT | UVM_HEX)
    `uvm_field_enum(boot_shareattr_e,  shareattr,  UVM_DEFAULT)
    `uvm_field_int (secext_present, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "boot_seq_item");
    super.new(name);
  endfunction

  // Compose boot_memattr[7:0] from the hi/lo nibbles.
  function bit [7:0] memattr();
    return {memattr_hi, memattr_lo};
  endfunction

  // --------------------------------------------------------------------------
  // Constraints
  // --------------------------------------------------------------------------

  // Address must fit the configured ADDR_WIDTH. boot_addr models bits [63:2];
  // bits at and above addr_width must be zero.
  constraint c_addr_width {
    addr_width inside {32, 64};
    if (addr_width < 64)
      { boot_addr[63:addr_width] == '0};
  }

  // Shareability 2'b01 is reserved/illegal - never generate it by default.
  constraint c_share_legal {
    shareattr != BOOT_SHARE_RESERVED;
  }

  // Device-type memory: only the four legal *LO encodings are allowed.
  constraint c_device_lo {
    if (memattr_hi == BOOT_MEMHI_DEVICE)
      memattr_lo inside {4'b0000, 4'b0100, 4'b1000, 4'b1100};
    else
      memattr_lo != 4'b0000; // 0000 is "Reserved" for Normal memory
  }

  // When Security Extension is present and boot is enabled, the boot descriptor
  // must reside in Secure memory (channel 0 boots Secure).
  constraint c_secure_addr {
    if (secext_present && boot_en) {
      ({boot_addr, 2'b00}) >= secure_base;
      ({boot_addr, 2'b00}) <  secure_limit;
    }
  }

  function string convert2string();
    return $sformatf(
      "boot_en=%0b addr=0x%0h memattr=0x%02h (hi=%s lo=0x%01h) shareattr=%s",
      boot_en, {boot_addr, 2'b00}, memattr(), memattr_hi.name(), memattr_lo,
      shareattr.name());
  endfunction

endclass : boot_seq_item

`endif // BOOT_SEQ_ITEM_SV
