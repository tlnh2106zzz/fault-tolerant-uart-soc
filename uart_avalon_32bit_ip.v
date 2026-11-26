`timescale 1ns / 1ps
module uart_avalon_32bit_ip (
    input  wire        clk,
    input  wire        reset_n,

    input  wire        avs_s0_chipselect,
    input  wire [2:0]  avs_s0_address,
    input  wire        avs_s0_read,
    input  wire        avs_s0_write,
    input  wire [31:0] avs_s0_writedata,
    output reg  [31:0] avs_s0_readdata,
    output wire        avs_s0_waitrequest,

    output wire        ins_irq0_irq,
    output wire        dma_tx_req,
    output wire        dma_rx_req,

    output wire        coe_uart_tx,
    input  wire        coe_uart_rx,
    output wire [1:0]  coe_error_led
);
    assign avs_s0_waitrequest = 1'b0; 

    reg [31:0] reg_tx_data;    
    reg [31:0] reg_rx_data;    
    reg [31:0] reg_control;    
    reg [15:0] reg_baud;       
    reg [15:0] sec_err_cnt;    
    reg [15:0] ded_err_cnt;    
    reg [31:0] reg_err_inj;    

    reg rx_ready_flag, sec_flag, ded_flag, frame_err_flag;
    reg tx_trigger;

    wire        tx_tick, rx_tick, pipe_tx_valid, tx_busy_w, tx_done_w;
    wire [51:0] interleaved_52_w, rx_raw_52_w, rx_injected_52_w;
    wire        rx_raw_done, frame_err_w, pipe_rx_valid;
    wire [31:0] decoded_32_w;
    wire [2:0]  sec_inc_w, ded_inc_w;

    baud_rate_gen_dynamic u_brg (clk, reset_n, reg_baud, tx_tick, rx_tick);
    tx_interleaved_pipeline u_tx_pipe (clk, reset_n, tx_trigger, reg_tx_data, pipe_tx_valid, interleaved_52_w);
    uart_tx_52bit u_tx (clk, reset_n, tx_tick, pipe_tx_valid, interleaved_52_w, coe_uart_tx, tx_busy_w, tx_done_w);

    wire serial_rx_in = reg_control[4] ? coe_uart_tx : coe_uart_rx;
    uart_rx_52bit u_rx (clk, reset_n, rx_tick, serial_rx_in, rx_raw_52_w, rx_raw_done, frame_err_w);

    wire [51:0] error_mask_52 = ({48'd0, reg_err_inj[11:8]} << reg_err_inj[5:0]);
    assign rx_injected_52_w   = rx_raw_52_w ^ error_mask_52;

    rx_deinterleaved_pipeline u_rx_pipe (clk, reset_n, rx_raw_done, rx_injected_52_w, pipe_rx_valid, decoded_32_w, sec_inc_w, ded_inc_w);

    wire bus_write_en = avs_s0_chipselect & avs_s0_write;
    wire bus_read_en  = avs_s0_chipselect & avs_s0_read;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            reg_tx_data <= 32'd0; reg_rx_data <= 32'd0; reg_control <= 32'd0;
            reg_baud <= 16'd27; sec_err_cnt <= 16'd0; ded_err_cnt <= 16'd0; reg_err_inj <= 32'd0;
            rx_ready_flag <= 1'b0; sec_flag <= 1'b0; ded_flag <= 1'b0; frame_err_flag <= 1'b0;
            tx_trigger <= 1'b0;
        end else begin
            tx_trigger <= 1'b0;

            if (pipe_rx_valid) begin
                reg_rx_data   <= decoded_32_w;
                rx_ready_flag <= 1'b1;
                if (sec_inc_w > 0) begin sec_flag <= 1'b1; sec_err_cnt <= sec_err_cnt + sec_inc_w; end
                if (ded_inc_w > 0) begin ded_flag <= 1'b1; ded_err_cnt <= ded_err_cnt + ded_inc_w; end
            end
            if (rx_raw_done && frame_err_w) frame_err_flag <= 1'b1;

            if (bus_read_en && (avs_s0_address == 3'd0)) rx_ready_flag <= 1'b0;

            if (bus_write_en) begin
                case (avs_s0_address)
                    3'd0: begin 
                        reg_tx_data <= avs_s0_writedata;
                        if (!tx_busy_w) tx_trigger <= 1'b1;
                    end
                    3'd1: begin 
                        if (avs_s0_writedata[1]) rx_ready_flag  <= 1'b0;
                        if (avs_s0_writedata[2]) sec_flag       <= 1'b0;
                        if (avs_s0_writedata[3]) ded_flag       <= 1'b0;
                        if (avs_s0_writedata[4]) frame_err_flag <= 1'b0;
                    end
                    3'd2: begin 
                        reg_control <= avs_s0_writedata;
                        if (avs_s0_writedata[0] && !tx_busy_w) tx_trigger <= 1'b1;
                    end
                    3'd3: reg_baud <= avs_s0_writedata[15:0]; 
                    3'd4: begin 
                        sec_err_cnt <= avs_s0_writedata[15:0];
                        ded_err_cnt <= avs_s0_writedata[31:16];
                    end
                    3'd5: reg_err_inj <= avs_s0_writedata;    
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        if (bus_read_en) begin
            case (avs_s0_address)
                3'd0: avs_s0_readdata = reg_rx_data;
                3'd1: avs_s0_readdata = {27'd0, frame_err_flag, ded_flag, sec_flag, rx_ready_flag, tx_busy_w};
                3'd2: avs_s0_readdata = reg_control;
                3'd3: avs_s0_readdata = {16'd0, reg_baud};
                3'd4: avs_s0_readdata = {ded_err_cnt, sec_err_cnt};
                3'd5: avs_s0_readdata = reg_err_inj;
                default: avs_s0_readdata = 32'd0;
            endcase
        end else begin
            avs_s0_readdata = 32'd0;
        end
    end

    assign ins_irq0_irq  = reg_control[1] & (rx_ready_flag | sec_flag | ded_flag | frame_err_flag);
    assign dma_tx_req    = reg_control[2] & (~tx_busy_w);
    assign dma_rx_req    = reg_control[3] & rx_ready_flag;
    assign coe_error_led = {ded_flag, sec_flag};
endmodule