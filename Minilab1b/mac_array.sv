// MAC Array - Instantiates 8 MAC units with staggered enable and B propagation
module mac_array (
    input logic clk,
    input logic rst_n,
    input logic clr,              // Clear all accumulators
    input logic en,               // Enable signal (starts propagation)
    input logic [7:0] a_in [0:7], // A inputs for all 8 MACs
    input logic [7:0] b_in,       // B input (propagates through array)
    input logic fifo_empty [0:7], // FIFO empty flags (don't accumulate if empty)
    output logic [23:0] c_out [0:7], // Results from all 8 MACs
    output logic en_out [0:7]     // Export enable signals for FIFO control
);

    // Internal signals for enable and B propagation
    logic en_chain [0:8];
    logic [7:0] b_chain [0:8];
    
    // Connect input to first element of chains
    assign en_chain[0] = en;
    assign b_chain[0] = b_in;
    
    // Export enable signals
    genvar j;
    generate
        for (j = 0; j < 8; j++) begin : en_export
            assign en_out[j] = en_chain[j];
        end
    endgenerate
    
    // Instantiate 8 MAC units
    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : mac_gen
            mac_unit mac_inst (
                .clk(clk),
                .rst_n(rst_n),
                .clr(clr),
                .en_in(en_chain[i] && !fifo_empty[i]),  // Only enable if FIFO has data
                .a_in(a_in[i]),
                .b_in(b_chain[i]),
                .en_out(en_chain[i+1]),
                .b_out(b_chain[i+1]),
                .c_out(c_out[i])
            );
        end
    endgenerate
    
endmodule