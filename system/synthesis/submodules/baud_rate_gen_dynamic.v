`timescale 1ns / 1ps
module baud_rate_gen_dynamic (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] baud_div,           
    output wire        tx_baud_tick,
    output wire        rx_oversample_tick
);
    reg [15:0] count_reg;
    reg [3:0]  rx_count;
    wire [15:0] limit = (baud_div == 16'd0) ? 16'd27 : baud_div;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) count_reg <= 16'd0;
        else if (count_reg >= limit - 1'b1) count_reg <= 16'd0;
        else count_reg <= count_reg + 16'd1;
    end
    assign rx_oversample_tick = (count_reg == (limit - 1'b1));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_count <= 4'd0;
        else if (rx_oversample_tick) rx_count <= rx_count + 4'd1;
    end
    assign tx_baud_tick = (rx_oversample_tick && (rx_count == 4'd15));
endmodule