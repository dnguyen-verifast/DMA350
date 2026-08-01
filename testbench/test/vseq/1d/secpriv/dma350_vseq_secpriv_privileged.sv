//==============================================================================
// dma350_vseq_secpriv_privileged.sv
//   "Privileged - Privileged accesses"  : PRIVATTR=1 -> AxPROT[0]=1.
//==============================================================================
`ifndef DMA350_VSEQ_SECPRIV_PRIVILEGED_SV
`define DMA350_VSEQ_SECPRIV_PRIVILEGED_SV

class dma350_vseq_secpriv_privileged extends dma350_vseq_secpriv_base;
  `uvm_object_utils(dma350_vseq_secpriv_privileged)

  function new(string name = "dma350_vseq_secpriv_privileged");
    super.new(name);
    nonsec = 1'b0;               // secure + privileged
    priv   = 1'b1;               // Privileged
  endfunction

endclass : dma350_vseq_secpriv_privileged

`endif // DMA350_VSEQ_SECPRIV_PRIVILEGED_SV
