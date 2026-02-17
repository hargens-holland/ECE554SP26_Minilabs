`timescale 1ns / 1ps

//=======================================================
//  Testbench for MAC (Multiply-Accumulate)
//=======================================================

module MAC_tb;

// Parameters
parameter DATA_WIDTH = 8;
parameter CLOCK_PERIOD = 20; // 50MHz clock

// DUT inputs
reg clk;
reg rst_n;
reg En;
reg Clr;
reg [DATA_WIDTH-1:0] Ain;
reg [DATA_WIDTH-1:0] Bin;

// DUT outputs
wire [DATA_WIDTH*3-1:0] Cout;

// Test variables
integer i;
integer errors;
reg [DATA_WIDTH*3-1:0] expected_result;
reg [DATA_WIDTH*3-1:0] accumulated;

//=======================================================
//  DUT Instantiation
//=======================================================

MAC #(
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .En(En),
    .Clr(Clr),
    .Ain(Ain),
    .Bin(Bin),
    .Cout(Cout)
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
    $dumpfile("MAC_tb.vcd");
    $dumpvars(0, MAC_tb);
    
    // Initialize variables
    rst_n = 1;
    En = 0;
    Clr = 0;
    Ain = 0;
    Bin = 0;
    errors = 0;
    accumulated = 0;
    
    $display("==============================================");
    $display("Starting MAC Testbench");
    $display("  DATA_WIDTH = %0d", DATA_WIDTH);
    $display("  OUTPUT_WIDTH = %0d", DATA_WIDTH*3);
    $display("==============================================");
    
    // Test 1: Reset test
    $display("\n[TEST 1] Reset Test");
    rst_n = 0;
    #(CLOCK_PERIOD * 2);
    rst_n = 1;
    #(CLOCK_PERIOD);
    
    if (Cout == 0) begin
        $display("  PASS: MAC output is zero after reset");
    end else begin
        $display("  FAIL: MAC output not zero after reset (Cout=%0d)", Cout);
        errors = errors + 1;
    end
    
    // Test 2: Single multiply-accumulate
    $display("\n[TEST 2] Single MAC Operation");
    @(negedge clk);
    En = 1;
    Ain = 5;
    Bin = 10;
    expected_result = 5 * 10;
    @(posedge clk);
    #1;
    
    if (Cout == expected_result) begin
        $display("  PASS: %0d * %0d = %0d (Cout=%0d)", Ain, Bin, expected_result, Cout);
    end else begin
        $display("  FAIL: Expected %0d, got %0d", expected_result, Cout);
        errors = errors + 1;
    end
    
    // Test 3: Accumulate multiple values
    $display("\n[TEST 3] Multiple MAC Operations");
    accumulated = Cout;
    
    for (i = 0; i < 5; i = i + 1) begin
        @(negedge clk);
        Ain = (i + 1) * 3;
        Bin = (i + 1) * 2;
        accumulated = accumulated + (Ain * Bin);
        @(posedge clk);
        #1;
        
        if (Cout == accumulated) begin
            $display("  PASS: Iteration %0d: %0d * %0d, accumulated=%0d", i, Ain, Bin, Cout);
        end else begin
            $display("  FAIL: Iteration %0d: Expected %0d, got %0d", i, accumulated, Cout);
            errors = errors + 1;
        end
    end
    
    // Test 4: Clear operation
    $display("\n[TEST 4] Clear Operation");
    @(negedge clk);
    Clr = 1;
    Ain = 0;
    Bin = 0;
    @(posedge clk);
    #1;
    @(negedge clk);
    Clr = 0;
    @(posedge clk);
    #1;
    
    if (Cout == 0) begin
        $display("  PASS: MAC cleared successfully (Cout=%0d)", Cout);
    end else begin
        $display("  FAIL: MAC not cleared (Cout=%0d)", Cout);
        errors = errors + 1;
    end
    
    // Test 5: Enable control
    $display("\n[TEST 5] Enable Control Test");
    
    // Accumulate with enable
    @(negedge clk);
    En = 1;
    Ain = 7;
    Bin = 8;
    expected_result = 7 * 8;
    @(posedge clk);
    #1;
    accumulated = Cout;
    
    if (Cout == expected_result) begin
        $display("  PASS: MAC with En=1: %0d * %0d = %0d", Ain, Bin, Cout);
    end else begin
        $display("  FAIL: Expected %0d, got %0d", expected_result, Cout);
        errors = errors + 1;
    end
    
    // Try to accumulate with enable disabled
    @(negedge clk);
    En = 0;
    Ain = 100;
    Bin = 100;
    @(posedge clk);
    #1;
    
    if (Cout == accumulated) begin
        $display("  PASS: MAC with En=0: output unchanged (Cout=%0d)", Cout);
    end else begin
        $display("  FAIL: MAC changed with En=0 (expected %0d, got %0d)", accumulated, Cout);
        errors = errors + 1;
    end
    
    // Test 6: Maximum value test
    $display("\n[TEST 6] Maximum Value Test");
    
    // Clear first
    @(negedge clk);
    Clr = 1;
    En = 0;
    @(posedge clk);
    #1;
    @(negedge clk);
    Clr = 0;
    
    // Multiply max values
    @(negedge clk);
    En = 1;
    Ain = (1 << DATA_WIDTH) - 1; // 255 for 8-bit
    Bin = (1 << DATA_WIDTH) - 1; // 255 for 8-bit
    expected_result = Ain * Bin;
    @(posedge clk);
    #1;
    
    if (Cout == expected_result) begin
        $display("  PASS: Max value: %0d * %0d = %0d", Ain, Bin, Cout);
    end else begin
        $display("  FAIL: Expected %0d, got %0d", expected_result, Cout);
        errors = errors + 1;
    end
    
    // Test 7: Zero multiplication
    $display("\n[TEST 7] Zero Multiplication Test");
    accumulated = Cout;
    
    @(negedge clk);
    En = 1;
    Ain = 0;
    Bin = 50;
    @(posedge clk);
    #1;
    
    if (Cout == accumulated) begin
        $display("  PASS: 0 * %0d: accumulated=%0d (no change)", Bin, Cout);
    end else begin
        $display("  Accumulated changed: %0d -> %0d", accumulated, Cout);
    end
    
    @(negedge clk);
    Ain = 50;
    Bin = 0;
    @(posedge clk);
    #1;
    
    if (Cout == accumulated) begin
        $display("  PASS: %0d * 0: accumulated=%0d (no change)", Ain, Cout);
    end else begin
        $display("  Accumulated changed: %0d -> %0d", accumulated, Cout);
    end
    
    // Test 8: Realistic sequence (like Minilab0)
    $display("\n[TEST 8] Realistic Sequence Test (Minilab0 pattern)");
    
    // Clear
    @(negedge clk);
    Clr = 1;
    En = 0;
    @(posedge clk);
    #1;
    @(negedge clk);
    Clr = 0;
    @(posedge clk);
    
    // Simulate FIFO output pattern
    accumulated = 0;
    for (i = 0; i < 8; i = i + 1) begin
        @(negedge clk);
        En = 1;
        Ain = (i + 1) * 5;  // 5, 10, 15, 20, 25, 30, 35, 40
        Bin = (i + 1) * 10; // 10, 20, 30, 40, 50, 60, 70, 80
        accumulated = accumulated + (Ain * Bin);
        @(posedge clk);
        #1;
        
        $display("  MAC[%0d]: %0d * %0d, accumulated=%0d (expected=%0d)", 
                 i, Ain, Bin, Cout, accumulated);
        
        if (Cout !== accumulated) begin
            $display("  FAIL: Mismatch at iteration %0d", i);
            errors = errors + 1;
        end
    end
    
    $display("  Final accumulated result: %0d (0x%h)", Cout, Cout);
    if (Cout == 14000) begin
        $display("  PASS: Correct result for Minilab0 pattern");
    end else begin
        $display("  FAIL: Expected 14000, got %0d", Cout);
        errors = errors + 1;
    end
    
    // Test 9: Reset during accumulation
    $display("\n[TEST 9] Reset During Accumulation");
    @(negedge clk);
    rst_n = 0;
    #(CLOCK_PERIOD * 2);
    rst_n = 1;
    #(CLOCK_PERIOD);
    
    if (Cout == 0) begin
        $display("  PASS: MAC reset during accumulation (Cout=%0d)", Cout);
    end else begin
        $display("  FAIL: MAC not reset (Cout=%0d)", Cout);
        errors = errors + 1;
    end
    
    #(CLOCK_PERIOD * 10);
    
    // Final results
    $display("\n==============================================");
    $display("MAC Testbench Complete");
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
//  Monitor output changes
//=======================================================

always @(posedge clk) begin
    if (Cout !== 0 && En) begin
        $display("    [Monitor] Time %0t: Cout = %0d (0x%h)", $time, Cout, Cout);
    end
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
