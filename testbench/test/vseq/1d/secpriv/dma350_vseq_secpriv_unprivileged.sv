//==============================================================================
// dma350_vseq_secpriv_unprivileged.sv
//   "Unprivileged - Unprivileged accesses"  : PRIVATTR=0 -> AxPROT[0]=0.
//==============================================================================
`ifndef DMA350_VSEQ_SECPRIV_UNPRIVILEGED_SV
`define DMA350_VSEQ_SECPRIV_UNPRIVILEGED_SV

class dma350_vseq_secpriv_unprivileged extends dma350_vseq_secpriv_base;
  `uvm_object_utils(dma350_vseq_secpriv_unprivileged)

  function new(string name = "dma350_vseq_secpriv_unprivileged");
    super.new(name);
    nonsec = 1'b1;               // non-secure + unprivileged
    priv   = 1'b0;               // Unprivileged
  endfunction

endclass : dma350_vseq_secpriv_unprivileged

`endif // DMA350_VSEQ_SECPRIV_UNPRIVILEGED_SV
