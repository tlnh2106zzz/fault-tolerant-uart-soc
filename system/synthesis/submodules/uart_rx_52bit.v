`timescale 1ns / 1ps
module uart_rx_52bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_oversample_tick,
    input  wire        rx_pin,
    output reg  [51:0] rx_data_out,
    output reg         rx_done,
    output reg         framing_error   
);
    reg rx_sync1, rx_sync2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin rx_sync1 <= 1'b1; rx_sync2 <= 1'b1; end
        else        begin rx_sync1 <= rx_pin; rx_sync2 <= rx_sync1; end
    end

    reg [1:0] sample_window;
    reg [1:0] state;
    reg [3:0] sample_cnt;
    reg [5:0] bit_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 2'd0; sample_cnt <= 4'd0; bit_cnt <= 6'd0;
            rx_data_out <= 52'd0; rx_done <= 1'b0; framing_error <= 1'b0;
            sample_window <= 2'b11;
        end else begin
            rx_done <= 1'b0;
            if (rx_oversample_tick) begin
                if (sample_cnt == 4'd13 || sample_cnt == 4'd14)
                    sample_window <= {sample_window[0], rx_sync2};
                case (state)
                    2'd0: if (!rx_sync2) begin
                        if (sample_cnt == 4'd7) begin
                            sample_cnt <= 4'd0; bit_cnt <= 6'd51; state <= 2'd1;
                        end else sample_cnt <= sample_cnt + 4'd1;
                    end else sample_cnt <= 4'd0;
                    2'd1: if (sample_cnt == 4'd15) begin
                        rx_data_out[bit_cnt] <= (sample_window[1] & sample_window[0]) |
                                                (sample_window[0] & rx_sync2) |
                                                (sample_window[1] & rx_sync2);
                        sample_cnt <= 4'd0;
                        if (bit_cnt == 6'd0) state <= 2'd2;
                        else bit_cnt <= bit_cnt - 6'd1;
                    end else sample_cnt <= sample_cnt + 4'd1;
                    2'd2: if (sample_cnt == 4'd15) begin
                        rx_done <= 1'b1; framing_error <= ~rx_sync2;
                        state <= 2'd0; sample_cnt <= 4'd0;
                    end else sample_cnt <= sample_cnt + 4'd1;
                    default: state <= 2'd0;
                endcase
            end
        end
    end
endmodule