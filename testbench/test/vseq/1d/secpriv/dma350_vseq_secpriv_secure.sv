//==============================================================================
// dma350_vseq_secpriv_secure.sv
//   "Secure - Secure accesses"  : NONSECATTR=0 -> AxPROT[1]=0 (secure).
//==============================================================================
`ifndef DMA350_VSEQ_SECPRIV_SECURE_SV
`define DMA350_VSEQ_SECPRIV_SECURE_SV

class dma350_vseq_secpriv_secure extends dma350_vseq_secpriv_base;
  `uvm_object_utils(dma350_vseq_secpriv_secure)

  function new(string name = "dma350_vseq_secpriv_secure");
    super.new(name);
    nonsec = 1'b0;               // Secure
    priv   = 1'b0;
  endfunction

endclass : dma350_vseq_secpriv_secure

`endif // DMA350_VSEQ_SECPRIV_SECURE_SV
