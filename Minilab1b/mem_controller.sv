// Memory controller to fetch matrix and vector data via Avalon MM interface
module mem_controller (
    input logic clk,
    input logic rst_n,
    input logic start,             // Start fetching data
    
    // Avalon-MM master interface to memory
    output logic [31:0] address,
    output logic read,
    input logic [63:0] readdata,
    input logic readdatavalid,
    input logic waitrequest,
    
    // FIFO write interfaces
    output logic [7:0] fifo_a_wr_data [0:7],  // 8 FIFOs for A
    output logic fifo_a_wr_en [0:7],
    input logic fifo_a_full [0:7],
    
    output logic [7:0] fifo_b_wr_data,         // 1 FIFO for B (shared)
    output logic fifo_b_wr_en,
    input logic fifo_b_full,
    
    output logic done                          // All FIFOs filled
);

    typedef enum logic [2:0] {
        IDLE,
        FETCH_ROW,
        WAIT_VALID,
        WRITE_FIFO,
        FETCH_VECTOR,
        WAIT_VEC_VALID,
        WRITE_VEC_FIFO,
        DONE
    } state_t;
    
    state_t state, next_state;
    logic [2:0] row_count;
    logic [2:0] byte_index;
    logic [63:0] row_data;
    logic [63:0] vec_data;
    
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
                    next_state = FETCH_ROW;
            end
            
            FETCH_ROW: begin
                if (!waitrequest)
                    next_state = WAIT_VALID;
            end
            
            WAIT_VALID: begin
                if (readdatavalid)
                    next_state = WRITE_FIFO;
            end
            
            WRITE_FIFO: begin
                if (byte_index == 7) begin
                    if (row_count == 7)
                        next_state = FETCH_VECTOR;
                    else
                        next_state = FETCH_ROW;
                end
            end
            
            FETCH_VECTOR: begin
                if (!waitrequest)
                    next_state = WAIT_VEC_VALID;
            end
            
            WAIT_VEC_VALID: begin
                if (readdatavalid)
                    next_state = WRITE_VEC_FIFO;
            end
            
            WRITE_VEC_FIFO: begin
                if (byte_index == 7)
                    next_state = DONE;
            end
            
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Output logic and datapath
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_count <= 0;
            byte_index <= 0;
            row_data <= 0;
            vec_data <= 0;
            address <= 0;
            read <= 0;
            done <= 0;
            
            for (int i = 0; i < 8; i++) begin
                fifo_a_wr_data[i] <= 0;
                fifo_a_wr_en[i] <= 0;
            end
            fifo_b_wr_data <= 0;
            fifo_b_wr_en <= 0;
            
        end else begin
            // Default values
            read <= 0;
            done <= 0;
            for (int i = 0; i < 8; i++)
                fifo_a_wr_en[i] <= 0;
            fifo_b_wr_en <= 0;
            
            case (state)
                IDLE: begin
                    row_count <= 0;
                    byte_index <= 0;
                end
                
                FETCH_ROW: begin
                    address <= row_count;
                    read <= 1;
                end
                
                WAIT_VALID: begin
                    if (readdatavalid) begin
                        row_data <= readdata;
                        byte_index <= 0;
                    end
                end
                
                WRITE_FIFO: begin
                    // Write entire row to ONE FIFO
                    // Row 0 goes to FIFO[0], Row 1 goes to FIFO[1], etc.
                    if (!fifo_a_full[row_count]) begin
                        fifo_a_wr_data[row_count] <= row_data[(7-byte_index)*8 +: 8];
                        fifo_a_wr_en[row_count] <= 1;
                        
                        if (byte_index == 7) begin
                            row_count <= row_count + 1;
                            byte_index <= 0;
                        end else begin
                            byte_index <= byte_index + 1;
                        end
                    end
                end
                
                FETCH_VECTOR: begin
                    address <= 8;  // Vector is at address 8
                    read <= 1;
                end
                
                WAIT_VEC_VALID: begin
                    if (readdatavalid) begin
                        vec_data <= readdata;
                        byte_index <= 0;
                    end
                end
                
                WRITE_VEC_FIFO: begin
                    if (!fifo_b_full) begin
                        fifo_b_wr_data <= vec_data[(7-byte_index)*8 +: 8];
                        fifo_b_wr_en <= 1;
                        byte_index <= byte_index + 1;
                    end
                end
                
                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end
    
endmodule
