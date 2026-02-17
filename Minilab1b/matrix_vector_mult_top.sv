// Top-level module for matrix-vector multiplication
module matrix_vector_mult_top (
    input logic clk,
    input logic rst_n,
    input logic start,              // Start the computation
    output logic [23:0] result [0:7], // Output results (c00-c07)
    output logic done               // Computation complete
);

    // Memory interface signals
    logic [31:0] mem_address;
    logic mem_read;
    logic [63:0] mem_readdata;
    logic mem_readdatavalid;
    logic mem_waitrequest;
    
    // FIFO signals for A
    logic [7:0] fifo_a_wr_data [0:7];
    logic fifo_a_wr_en [0:7];
    logic fifo_a_full [0:7];
    logic [7:0] fifo_a_rd_data [0:7];
    logic fifo_a_rd_en [0:7];
    logic fifo_a_empty [0:7];
    
    // FIFO signals for B
    logic [7:0] fifo_b_wr_data;
    logic fifo_b_wr_en;
    logic fifo_b_full;
    logic [7:0] fifo_b_rd_data;
    logic fifo_b_rd_en;
    logic fifo_b_empty;
    logic [7:0] fifo_b_rd_data_delayed;  // Delay B to align with A FIFO output
    
    // Control signals
    logic mem_ctrl_done;
    logic mac_en;
    logic mac_clr;
    logic all_fifos_full;
    logic [3:0] compute_count;
    logic mac_en_chain [0:7];  // Enable chain from MAC array
    logic fifo_a_empty_delayed [0:7];  // Delayed empty signals for MAC gating
    
    // Delay B by 1 cycle to align with A FIFO read latency
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_b_rd_data_delayed <= 8'b0;
            for (int i = 0; i < 8; i++)
                fifo_a_empty_delayed[i] <= 1'b1;
        end else begin
            fifo_b_rd_data_delayed <= fifo_b_rd_data;
            for (int i = 0; i < 8; i++)
                fifo_a_empty_delayed[i] <= fifo_a_empty[i];
        end
    end
    
    // State machine for top-level control
    typedef enum logic [2:0] {
        IDLE,
        LOADING,
        WAIT_FULL,
        PRELOAD,
        COMPUTING,
        FINISH
    } state_t;
    
    state_t state, next_state;
    
    // Check if all FIFOs are full
    always_comb begin
        all_fifos_full = 1;
        for (int i = 0; i < 8; i++) begin
            if (!fifo_a_full[i])
                all_fifos_full = 0;
        end
        if (!fifo_b_full)
            all_fifos_full = 0;
    end
    
    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start)
                    next_state = LOADING;
            end
            
            LOADING: begin
                if (mem_ctrl_done)
                    next_state = WAIT_FULL;
            end
            
            WAIT_FULL: begin
                if (all_fifos_full)
                    next_state = PRELOAD;
            end
            
            PRELOAD: begin
                next_state = COMPUTING;
            end
            
            COMPUTING: begin
                if (compute_count == 15)  // 8 reads + 7 drain cycles
                    next_state = FINISH;
            end
            
            FINISH: begin
                // Stay in FINISH - don't go back to IDLE
                next_state = FINISH;
            end
        endcase
    end
    
    // Output and control logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compute_count <= 0;
            mac_en <= 0;
            mac_clr <= 0;
            done <= 0;
            for (int i = 0; i < 8; i++)
                fifo_a_rd_en[i] <= 0;
            fifo_b_rd_en <= 0;
        end else begin
            // Defaults
            mac_en <= 0;
            mac_clr <= 0;
            // Don't reset done here - let it stay high once set
            
            case (state)
                IDLE: begin
                    compute_count <= 0;
                    mac_clr <= 1;  // Clear accumulators
                    for (int i = 0; i < 8; i++)
                        fifo_a_rd_en[i] <= 0;
                    fifo_b_rd_en <= 0;
                end
                
                LOADING: begin
                    // Wait for memory controller
                end
                
                WAIT_FULL: begin
                    // Wait for FIFOs to fill
                end
                
                PRELOAD: begin
                    // Don't read from FIFO_A yet - MACs will read when enabled
                    // Only pre-read FIFO_B
                    for (int i = 0; i < 8; i++)
                        fifo_a_rd_en[i] <= 0;
                    fifo_b_rd_en <= 1;
                    compute_count <= 0;  // Will increment in COMPUTING
                end
                
                COMPUTING: begin
                    if (compute_count < 8) begin
                        // Read from FIFOs for 8 cycles
                        for (int i = 0; i < 8; i++)
                            fifo_a_rd_en[i] <= 1;
                        fifo_b_rd_en <= 1;
                        mac_en <= 1;
                        compute_count <= compute_count + 1;
                    end else if (compute_count < 15) begin
                        // Stop reading but keep MAC enabled for pipeline to drain
                        for (int i = 0; i < 8; i++)
                            fifo_a_rd_en[i] <= 0;
                        fifo_b_rd_en <= 0;
                        mac_en <= 1;  // Keep enabled!
                        compute_count <= compute_count + 1;
                    end else begin
                        // All done
                        for (int i = 0; i < 8; i++)
                            fifo_a_rd_en[i] <= 0;
                        fifo_b_rd_en <= 0;
                        mac_en <= 0;
                    end
                end
                
                FINISH: begin
                    done <= 1;
                end
            endcase
        end
    end
    
    // Memory wrapper instance
    mem_wrapper memory (
        .clk(clk),
        .reset_n(rst_n),
        .address(mem_address),
        .read(mem_read),
        .readdata(mem_readdata),
        .readdatavalid(mem_readdatavalid),
        .waitrequest(mem_waitrequest)
    );
    
    // Memory controller instance
    mem_controller mem_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start(state == LOADING),
        .address(mem_address),
        .read(mem_read),
        .readdata(mem_readdata),
        .readdatavalid(mem_readdatavalid),
        .waitrequest(mem_waitrequest),
        .fifo_a_wr_data(fifo_a_wr_data),
        .fifo_a_wr_en(fifo_a_wr_en),
        .fifo_a_full(fifo_a_full),
        .fifo_b_wr_data(fifo_b_wr_data),
        .fifo_b_wr_en(fifo_b_wr_en),
        .fifo_b_full(fifo_b_full),
        .done(mem_ctrl_done)
    );
    
    // FIFO instances for A (8 FIFOs, one for each MAC)
    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : fifo_a_gen
            fifo #(.DATA_WIDTH(8), .DEPTH(8)) fifo_a_inst (
                .clk(clk),
                .rst_n(rst_n),
                .wr_en(fifo_a_wr_en[i]),
                .wr_data(fifo_a_wr_data[i]),
                .full(fifo_a_full[i]),
                .rd_en(mac_en_chain[i]),  // Read when MAC is enabled!
                .rd_data(fifo_a_rd_data[i]),
                .empty(fifo_a_empty[i])
            );
        end
    endgenerate
    
    // FIFO instance for B (shared across all MACs)
    fifo #(.DATA_WIDTH(8), .DEPTH(8)) fifo_b_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_b_wr_en),
        .wr_data(fifo_b_wr_data),
        .full(fifo_b_full),
        .rd_en(fifo_b_rd_en),
        .rd_data(fifo_b_rd_data),
        .empty(fifo_b_empty)
    );
    
    // MAC array instance
    mac_array mac_arr (
        .clk(clk),
        .rst_n(rst_n),
        .clr(mac_clr),
        .en(mac_en),
        .a_in(fifo_a_rd_data),
        .b_in(fifo_b_rd_data_delayed),  // Use delayed B
        .fifo_empty(fifo_a_empty_delayed),  // Use delayed empty flags
        .c_out(result),
        .en_out(mac_en_chain)  // Get enable chain for FIFO control
    );
    
endmodule