// ============================================================================
// Filelist for the DMA-350 status/control agent (compile order matters).
// Usage (example, questa/xcelium/vcs):
//   <sim> -sv -uvm -f dma350_sc.f
// Adjust +incdir paths to your tree. UVM must already be on the command line.
// ============================================================================

// include dirs so the package `include's resolve
+incdir+./config
+incdir+./seq_item
+incdir+./components
+incdir+./sequences

// 1) interface (compiled in $unit / with the top)
./interface/dma350_sc_if.sv

// 2) package (pulls in cfg, item, components, sequences via `include)
./pkg/dma350_sc_pkg.sv

// 3) example tb (optional – remove when integrating into your own top)
./tb/dma350_sc_example_env.sv
./tb/dma350_sc_tb_top.sv
