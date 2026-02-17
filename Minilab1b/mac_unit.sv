// MAC Unit - Multiply-Accumulate with enable and B propagation
module mac_unit (
    input logic clk,
    input logic rst_n,
    input logic clr,              // Clear accumulator
    input logic en_in,            // Enable input (propagates to next MAC)
    input logic [7:0] a_in,       // A input (8-bit)
    input logic [7:0] b_in,       // B input (8-bit, propagates to next MAC)
    output logic en_out,          // Enable output (delayed by 1 cycle)
    output logic [7:0] b_out,     // B output (delayed by 1 cycle)
    output logic [23:0] c_out     // Accumulated result (24-bit)
);

    logic [23:0] accumulator;
    logic [15:0] product;
    
    // Calculate product
    assign product = a_in * b_in;
    
    // Accumulator logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= 24'b0;
        end else if (clr) begin
            accumulator <= 24'b0;
        end else if (en_in) begin
            accumulator <= accumulator + product;
        end
    end
    
    // Propagate enable and B with 1 cycle delay
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_out <= 1'b0;
            b_out <= 8'b0;
        end else begin
            en_out <= en_in;
            b_out <= b_in;
        end
    end
    
    assign c_out = accumulator;
    
endmodule
