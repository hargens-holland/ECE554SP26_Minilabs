`timescale 1ns / 1ps

//=======================================================
//  Testbench for FIFO
//=======================================================

module FIFO_tb;

// Parameters
parameter DATA_WIDTH = 8;
parameter DEPTH = 8;
parameter CLOCK_PERIOD = 20; // 50MHz clock

// DUT inputs
reg clk;
reg rst_n;
reg rden;
reg wren;
reg [DATA_WIDTH-1:0] i_data;

// DUT outputs
wire [DATA_WIDTH-1:0] o_data;
wire full;
wire empty;

// Test variables
integer i;
reg [DATA_WIDTH-1:0] test_data [0:DEPTH-1];
reg [DATA_WIDTH-1:0] read_data [0:DEPTH-1];
integer write_count;
integer read_count;
integer errors;

//=======================================================
//  DUT Instantiation
//=======================================================

FIFO #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .rden(rden),
    .wren(wren),
    .i_data(i_data),
    .o_data(o_data),
    .full(full),
    .empty(empty)
);

//=======================================================
//  Clock Generation
//=======================================================

initial begin
    clk = 0;
    forever #(CLOCK_PERIOD/2) clk = ~clk;
end

//=======================================================
//  Test Stimulus
//=======================================================

initial begin
    // Initialize waveform dump
    $dumpfile("FIFO_tb.vcd");
    $dumpvars(0, FIFO_tb);
    
    // Initialize variables
    rst_n = 1;
    rden = 0;
    wren = 0;
    i_data = 0;
    write_count = 0;
    read_count = 0;
    errors = 0;
    
    // Generate test data
    for (i = 0; i < DEPTH; i = i + 1) begin
        test_data[i] = $random & ((1 << DATA_WIDTH) - 1);
    end
    
    $display("==============================================");
    $display("Starting FIFO Testbench");
    $display("  DATA_WIDTH = %0d", DATA_WIDTH);
    $display("  DEPTH = %0d", DEPTH);
    $display("==============================================");
    
    // Test 1: Reset test
    $display("\n[TEST 1] Reset Test");
    rst_n = 0;
    #(CLOCK_PERIOD * 2);
    rst_n = 1;
    #(CLOCK_PERIOD);
    
    if (empty && !full) begin
        $display("  PASS: FIFO is empty after reset");
    end else begin
        $display("  FAIL: FIFO not in correct state after reset (empty=%b, full=%b)", empty, full);
        errors = errors + 1;
    end
    
    // Test 2: Fill FIFO completely
    $display("\n[TEST 2] Fill FIFO Test");
    for (i = 0; i < DEPTH; i = i + 1) begin
        @(negedge clk);
        wren = 1;
        i_data = test_data[i];
        $display("  Writing data[%0d] = 0x%h", i, test_data[i]);
        @(posedge clk);
        #1;
        write_count = write_count + 1;
    end
    @(negedge clk);
    wren = 0;
    @(posedge clk);
    #1;
    
    if (full && !empty) begin
        $display("  PASS: FIFO is full after writing %0d entries", DEPTH);
    end else begin
        $display("  FAIL: FIFO not full after writing %0d entries (empty=%b, full=%b)", DEPTH, empty, full);
        errors = errors + 1;
    end
    
    // Test 3: Attempt to write when full
    $display("\n[TEST 3] Write When Full Test");
    @(negedge clk);
    wren = 1;
    i_data = 8'hFF;
    @(posedge clk);
    #1;
    @(negedge clk);
    wren = 0;
    
    if (full) begin
        $display("  PASS: FIFO remains full (overflow protection)");
    end else begin
        $display("  FAIL: FIFO not full after attempted overflow write");
        errors = errors + 1;
    end
    
    // Test 4: Read all data from FIFO
    $display("\n[TEST 4] Read FIFO Test");
    for (i = 0; i < DEPTH; i = i + 1) begin
        @(negedge clk);
        rden = 1;
        @(posedge clk);
        #1;
        read_data[i] = o_data;
        $display("  Reading data[%0d] = 0x%h (expected 0x%h)", i, o_data, test_data[i]);
        
        if (o_data !== test_data[i]) begin
            $display("  FAIL: Data mismatch!");
            errors = errors + 1;
        end
        read_count = read_count + 1;
    end
    @(negedge clk);
    rden = 0;
    @(posedge clk);
    #1;
    
    if (empty && !full) begin
        $display("  PASS: FIFO is empty after reading %0d entries", DEPTH);
    end else begin
        $display("  FAIL: FIFO not empty after reading all entries (empty=%b, full=%b)", empty, full);
        errors = errors + 1;
    end
    
    // Test 5: Attempt to read when empty
    $display("\n[TEST 5] Read When Empty Test");
    @(negedge clk);
    rden = 1;
    @(posedge clk);
    #1;
    @(negedge clk);
    rden = 0;
    
    if (empty) begin
        $display("  PASS: FIFO remains empty (underflow protection)");
    end else begin
        $display("  FAIL: FIFO not empty after attempted underflow read");
        errors = errors + 1;
    end
    
    // Test 6: Simultaneous read/write
    $display("\n[TEST 6] Simultaneous Read/Write Test");
    
    // First fill with some data
    for (i = 0; i < DEPTH/2; i = i + 1) begin
        @(negedge clk);
        wren = 1;
        i_data = i + 1;
        @(posedge clk);
        #1;
    end
    @(negedge clk);
    wren = 0;
    @(posedge clk);
    
    // Now read and write simultaneously
    for (i = 0; i < 4; i = i + 1) begin
        @(negedge clk);
        rden = 1;
        wren = 1;
        i_data = 8'hA0 + i;
        @(posedge clk);
        #1;
        $display("  Simultaneous R/W: read=0x%h, write=0x%h", o_data, i_data);
    end
    @(negedge clk);
    rden = 0;
    wren = 0;
    @(posedge clk);
    
    $display("  PASS: Simultaneous read/write completed");
    
    // Test 7: Multiple write/read cycles
    $display("\n[TEST 7] Multiple Cycles Test");
    for (i = 0; i < 3; i = i + 1) begin
        // Write cycle
        @(negedge clk);
        wren = 1;
        i_data = 8'hC0 + i;
        @(posedge clk);
        #1;
        
        // Read cycle
        @(negedge clk);
        wren = 0;
        rden = 1;
        @(posedge clk);
        #1;
        
        @(negedge clk);
        rden = 0;
        @(posedge clk);
        $display("  Cycle %0d: write=0x%h, read=0x%h", i, 8'hC0 + i, o_data);
    end
    
    // Test 8: Reset during operation
    $display("\n[TEST 8] Reset During Operation Test");
    
    // Fill partially
    for (i = 0; i < DEPTH/2; i = i + 1) begin
        @(negedge clk);
        wren = 1;
        i_data = 8'hD0 + i;
        @(posedge clk);
        #1;
    end
    
    // Reset
    @(negedge clk);
    wren = 0;
    rst_n = 0;
    #(CLOCK_PERIOD * 2);
    rst_n = 1;
    #(CLOCK_PERIOD);
    
    if (empty && !full) begin
        $display("  PASS: FIFO properly reset during operation");
    end else begin
        $display("  FAIL: FIFO not properly reset (empty=%b, full=%b)", empty, full);
        errors = errors + 1;
    end
    
    #(CLOCK_PERIOD * 10);
    
    // Final results
    $display("\n==============================================");
    $display("FIFO Testbench Complete");
    $display("  Total Writes: %0d", write_count);
    $display("  Total Reads: %0d", read_count);
    $display("  Errors: %0d", errors);
    if (errors == 0) begin
        $display("  STATUS: ALL TESTS PASSED!");
    end else begin
        $display("  STATUS: TESTS FAILED!");
    end
    $display("==============================================");
    
    $finish;
end

//=======================================================
//  Timeout watchdog
//=======================================================

initial begin
    #(CLOCK_PERIOD * 500);
    $display("\nERROR: Testbench timeout!");
    $finish;
end

endmodule
