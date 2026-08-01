//==============================================================================
// dma350_vseq_secpriv_nonsecure.sv
//   "Non-secure - Non-secure accesses"  : NONSECATTR=1 -> AxPROT[1]=1.
//==============================================================================
`ifndef DMA350_VSEQ_SECPRIV_NONSECURE_SV
`define DMA350_VSEQ_SECPRIV_NONSECURE_SV

class dma350_vseq_secpriv_nonsecure extends dma350_vseq_secpriv_base;
  `uvm_object_utils(dma350_vseq_secpriv_nonsecure)

  function new(string name = "dma350_vseq_secpriv_nonsecure");
    super.new(name);
    nonsec = 1'b1;               // Non-secure
    priv   = 1'b0;
  endfunction

endclass : dma350_vseq_secpriv_nonsecure

`endif // DMA350_VSEQ_SECPRIV_NONSECURE_SV
