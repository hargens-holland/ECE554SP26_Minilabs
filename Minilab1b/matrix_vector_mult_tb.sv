// Testbench for matrix-vector multiplication
`timescale 1ns/1ps

module matrix_vector_mult_tb;

    logic clk;
    logic rst_n;
    logic start;
    logic [23:0] result [0:7];
    logic done;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock
    end
    
    // DUT instantiation
    matrix_vector_mult_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .result(result),
        .done(done)
    );
    
    // Expected results (pre-calculated)
    // Matrix A (from .mif file):
    // Row 0: 01 02 03 04 05 06 07 08
    // Row 1: 11 12 13 14 15 16 17 18
    // Row 2: 21 22 23 24 25 26 27 28
    // Row 3: 31 32 33 34 35 36 37 38
    // Row 4: 41 42 43 44 45 46 47 48
    // Row 5: 51 52 53 54 55 56 57 58
    // Row 6: 61 62 63 64 65 66 67 68
    // Row 7: 71 72 73 74 75 76 77 78
    // Vector B: 81 82 83 84 85 86 87 88
    
    logic [23:0] expected_results [0:7];
    
    initial begin
        // Calculate expected results
        // c[i] = sum(A[i][j] * B[j]) for j=0 to 7
        expected_results[0] = 24'h0001 * 24'h0081 + 24'h0002 * 24'h0082 + 24'h0003 * 24'h0083 + 
                             24'h0004 * 24'h0084 + 24'h0005 * 24'h0085 + 24'h0006 * 24'h0086 + 
                             24'h0007 * 24'h0087 + 24'h0008 * 24'h0088;
        
        expected_results[1] = 24'h0011 * 24'h0081 + 24'h0012 * 24'h0082 + 24'h0013 * 24'h0083 + 
                             24'h0014 * 24'h0084 + 24'h0015 * 24'h0085 + 24'h0016 * 24'h0086 + 
                             24'h0017 * 24'h0087 + 24'h0018 * 24'h0088;
        
        expected_results[2] = 24'h0021 * 24'h0081 + 24'h0022 * 24'h0082 + 24'h0023 * 24'h0083 + 
                             24'h0024 * 24'h0084 + 24'h0025 * 24'h0085 + 24'h0026 * 24'h0086 + 
                             24'h0027 * 24'h0087 + 24'h0028 * 24'h0088;
        
        expected_results[3] = 24'h0031 * 24'h0081 + 24'h0032 * 24'h0082 + 24'h0033 * 24'h0083 + 
                             24'h0034 * 24'h0084 + 24'h0035 * 24'h0085 + 24'h0036 * 24'h0086 + 
                             24'h0037 * 24'h0087 + 24'h0038 * 24'h0088;
        
        expected_results[4] = 24'h0041 * 24'h0081 + 24'h0042 * 24'h0082 + 24'h0043 * 24'h0083 + 
                             24'h0044 * 24'h0084 + 24'h0045 * 24'h0085 + 24'h0046 * 24'h0086 + 
                             24'h0047 * 24'h0087 + 24'h0048 * 24'h0088;
        
        expected_results[5] = 24'h0051 * 24'h0081 + 24'h0052 * 24'h0082 + 24'h0053 * 24'h0083 + 
                             24'h0054 * 24'h0084 + 24'h0055 * 24'h0085 + 24'h0056 * 24'h0086 + 
                             24'h0057 * 24'h0087 + 24'h0058 * 24'h0088;
        
        expected_results[6] = 24'h0061 * 24'h0081 + 24'h0062 * 24'h0082 + 24'h0063 * 24'h0083 + 
                             24'h0064 * 24'h0084 + 24'h0065 * 24'h0085 + 24'h0066 * 24'h0086 + 
                             24'h0067 * 24'h0087 + 24'h0068 * 24'h0088;
        
        expected_results[7] = 24'h0071 * 24'h0081 + 24'h0072 * 24'h0082 + 24'h0073 * 24'h0083 + 
                             24'h0074 * 24'h0084 + 24'h0075 * 24'h0085 + 24'h0076 * 24'h0086 + 
                             24'h0077 * 24'h0087 + 24'h0078 * 24'h0088;
        
        $display("============================================");
        $display("Matrix-Vector Multiplication Testbench");
        $display("============================================");
        $display("Expected Results:");
        for (int i = 0; i < 8; i++) begin
            $display("  c[%0d] = 0x%06h (%0d)", i, expected_results[i], expected_results[i]);
        end
        $display("============================================\n");
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        start = 0;
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        $display("[%0t] Reset released", $time);
        
        // Wait a bit
        repeat(5) @(posedge clk);
        
        // Start computation
        $display("[%0t] Starting computation", $time);
        start = 1;
        @(posedge clk);
        start = 0;
        
        // Monitor state transitions
        fork
            begin
                wait(dut.state == dut.LOADING);
                $display("[%0t] State: LOADING", $time);
            end
            begin
                wait(dut.state == dut.WAIT_FULL);
                $display("[%0t] State: WAIT_FULL", $time);
            end
            begin
                wait(dut.state == dut.COMPUTING);
                $display("[%0t] State: COMPUTING", $time);
            end
            begin
                wait(dut.state == dut.FINISH);
                $display("[%0t] State: FINISH", $time);
            end
        join_none
        
        // Wait for done signal
        wait(done);
        $display("\n[%0t] Computation complete!", $time);
        
        // Wait a few cycles for results to settle
        repeat(10) @(posedge clk);
        
        // Check results
        $display("\n============================================");
        $display("Results Verification:");
        $display("============================================");
        
        begin
            int pass_count;
            int fail_count;
            int i;
            
            pass_count = 0;
            fail_count = 0;
            
            for (i = 0; i < 8; i++) begin
                if (result[i] == expected_results[i]) begin
                    $display("[PASS] c[%0d]: Got 0x%06h, Expected 0x%06h", 
                            i, result[i], expected_results[i]);
                    pass_count++;
                end else begin
                    $display("[FAIL] c[%0d]: Got 0x%06h, Expected 0x%06h (Diff: %0d)", 
                            i, result[i], expected_results[i], 
                            $signed(result[i]) - $signed(expected_results[i]));
                    fail_count++;
                end
                end
            
            $display("============================================");
            $display("Test Summary: %0d PASS, %0d FAIL", pass_count, fail_count);
            $display("============================================\n");
            
            if (fail_count == 0) begin
                $display("*** ALL TESTS PASSED ***\n");
            end else begin
                $display("*** SOME TESTS FAILED ***\n");
            end
        end
        
        // Additional cycles
        repeat(20) @(posedge clk);
        
        $finish;
    end
    
    // Monitor interface signals during computation
    initial begin
        wait(rst_n);
        
        forever begin
            @(posedge clk);
            
            // Monitor memory controller activity
            if (dut.mem_read) begin
                $display("[%0t] Memory Read: addr=0x%h", $time, dut.mem_address);
            end
            
            if (dut.mem_readdatavalid) begin
                $display("[%0t] Memory Data Valid: data=0x%h", $time, dut.mem_readdata);
            end
            
            // Monitor FIFO writes
            for (int i = 0; i < 8; i++) begin
                if (dut.fifo_a_wr_en[i]) begin
                    $display("[%0t] FIFO_A[%0d] Write: data=0x%02h", 
                            $time, i, dut.fifo_a_wr_data[i]);
                end
            end
            
            if (dut.fifo_b_wr_en) begin
                $display("[%0t] FIFO_B Write: data=0x%02h", $time, dut.fifo_b_wr_data);
            end
            
            // Monitor MAC enable and computation
            if (dut.mac_en) begin
                $display("[%0t] MAC Enabled (count=%0d)", $time, dut.compute_count);
                for (int i = 0; i < 8; i++) begin
                    $display("  MAC[%0d]: A=0x%02h, result=0x%06h", 
                            i, dut.fifo_a_rd_data[i], result[i]);
                end
                $display("  B=0x%02h", dut.fifo_b_rd_data);
            end
        end
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        $display("\n[ERROR] Simulation timeout!");
        $finish;
    end
    
    // Dump waveform
    initial begin
        $dumpfile("matrix_vector_mult.vcd");
        $dumpvars(0, matrix_vector_mult_tb);
    end

endmodule
