module FIFO
#(
  parameter DEPTH=8,
  parameter DATA_WIDTH=8
)
(
  input  clk,
  input  rst_n,
  input  rden,
  input  wren,
  input  [DATA_WIDTH-1:0] i_data,
  output [DATA_WIDTH-1:0] o_data,
  output full,
  output empty
);

  // Calculate pointer width
  localparam PTR_WIDTH = $clog2(DEPTH);
  
  // Memory array
  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  
  // Read and write pointers
  logic [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
  
  // Counter to track number of elements
  logic [PTR_WIDTH:0] count;
  
  // Output register
  logic [DATA_WIDTH-1:0] o_data_reg;
  
  // Full and empty flags
  assign full = (count == DEPTH);
  assign empty = (count == 0);
  assign o_data = o_data_reg;
  
  // Write operation
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
    end else if (wren && !full) begin
      mem[wr_ptr] <= i_data;
      wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1'b1;
    end
  end
  
  // Read operation
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= '0;
      o_data_reg <= '0;
    end else if (rden && !empty) begin
      o_data_reg <= mem[rd_ptr];
      rd_ptr <= (rd_ptr == DEPTH-1) ? '0 : rd_ptr + 1'b1;
    end
  end
  
  // Counter management
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count <= '0;
    end else begin
      case ({wren && !full, rden && !empty})
        2'b10: count <= count + 1'b1;  // Write only
        2'b01: count <= count - 1'b1;  // Read only
        default: count <= count;        // Both or neither
      endcase
    end
  end

endmodule