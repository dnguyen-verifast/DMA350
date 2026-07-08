//==============================================================================
// lpi_qchannel_master_seq.sv
// Q-Channel MASTER = DEVICE responder BASE sequence.
// Forever supplies an accept/deny decision for each quiescence request.
// Scenario sequences override next_deny() to set the accept/deny policy.
//   - deny_script (0=accept, 1=deny) takes precedence while it lasts.
//   - default policy: ~20% deny (randomized).
//==============================================================================
class lpi_qchannel_master_seq extends uvm_sequence #(lpi_qchannel_item);
  `uvm_object_utils(lpi_qchannel_master_seq)

  bit deny_script[$];

  function new(string name="lpi_qchannel_master_seq"); super.new(name); endfunction

  // Override in scenario sequences. Return 1 to deny the idx-th request.
  virtual function bit next_deny(int idx);
    if (idx < deny_script.size()) return deny_script[idx];
    return ($urandom_range(0,9) < 2);
  endfunction

  task body();
    int i = 0;
    forever begin
      bit d = next_deny(i);
      lpi_qchannel_item it = lpi_qchannel_item::type_id::create("it");
      start_item(it);
      if (!it.randomize() with { deny == d; }) `uvm_error(get_type_name(),"rand failed")
      finish_item(it);
      i++;
    end
  endtask
endclass
