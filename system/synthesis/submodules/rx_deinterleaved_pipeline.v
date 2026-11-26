`timescale 1ns / 1ps
module rx_deinterleaved_pipeline (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rx_done_in,
    input  wire [51:0] rx_bits_52,
    output reg         valid_out,
    output reg  [31:0] data_out_32,
    output reg  [2:0]  sec_cnt_inc, 
    output reg  [2:0]  ded_cnt_inc  
);
    wire [12:0] cw_in [0:3];
    genvar c;
    generate
        for (c = 0; c < 13; c = c + 1) begin : gen_deinterleave
            assign cw_in[0][c] = rx_bits_52[c*4 + 0];
            assign cw_in[1][c] = rx_bits_52[c*4 + 1];
            assign cw_in[2][c] = rx_bits_52[c*4 + 2];
            assign cw_in[3][c] = rx_bits_52[c*4 + 3];
        end
    endgenerate

    wire [3:0] s_w [0:3];
    wire       p_w [0:3];
    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin : gen_syndrome
            assign s_w[k][0] = cw_in[k][11] ^ cw_in[k][9] ^ cw_in[k][7] ^ cw_in[k][5] ^ cw_in[k][3] ^ cw_in[k][1];
            assign s_w[k][1] = cw_in[k][10] ^ cw_in[k][9] ^ cw_in[k][6] ^ cw_in[k][5] ^ cw_in[k][2] ^ cw_in[k][1];
            assign s_w[k][2] = cw_in[k][8]  ^ cw_in[k][7] ^ cw_in[k][6] ^ cw_in[k][5] ^ cw_in[k][0];
            assign s_w[k][3] = cw_in[k][4]  ^ cw_in[k][3] ^ cw_in[k][2] ^ cw_in[k][1] ^ cw_in[k][0];
            assign p_w[k]    = ^cw_in[k];
        end
    endgenerate

    reg [11:0] s1_c [0:3];
    reg [3:0]  s1_s [0:3];
    reg        s1_p [0:3];
    reg        s1_valid;
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 1'b0;
            for (j = 0; j < 4; j = j + 1) begin
                s1_c[j] <= 12'd0; s1_s[j] <= 4'd0; s1_p[j] <= 1'b0;
            end
        end else begin
            s1_valid <= rx_done_in;
            if (rx_done_in) begin
                for (j = 0; j < 4; j = j + 1) begin
                    s1_c[j] <= cw_in[j][11:0];
                    s1_s[j] <= s_w[j];
                    s1_p[j] <= p_w[j];
                end
            end
        end
    end

    reg [11:0] s2_c_corr [0:3];
    reg [3:0]  s2_sec_flag, s2_ded_flag;
    reg        s2_valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_valid <= 1'b0; s2_sec_flag <= 4'd0; s2_ded_flag <= 4'd0;
            for (j = 0; j < 4; j = j + 1) s2_c_corr[j] <= 12'd0;
        end else begin
            s2_valid <= s1_valid;
            if (s1_valid) begin
                for (j = 0; j < 4; j = j + 1) begin
                    if (s1_p[j] == 1'b0 && s1_s[j] == 4'd0) begin
                        s2_c_corr[j]   <= s1_c[j];
                        s2_sec_flag[j] <= 1'b0; s2_ded_flag[j] <= 1'b0;
                    end else if (s1_p[j] == 1'b1) begin
                        s2_sec_flag[j] <= 1'b1; s2_ded_flag[j] <= 1'b0;
                        if (s1_s[j] >= 4'd1 && s1_s[j] <= 4'd12)
                            s2_c_corr[j] <= s1_c[j] ^ (12'd1 << (4'd12 - s1_s[j]));
                        else
                            s2_c_corr[j] <= s1_c[j];
                    end else begin
                        s2_c_corr[j]   <= s1_c[j];
                        s2_sec_flag[j] <= 1'b0; s2_ded_flag[j] <= 1'b1;
                    end
                end
            end
        end
    end

    wire [7:0] byte_out [0:3];
    generate
        for (k = 0; k < 4; k = k + 1) begin : gen_extract
            assign byte_out[k] = {s2_c_corr[k][9], s2_c_corr[k][7:5], s2_c_corr[k][3:0]};
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0; data_out_32 <= 32'd0;
            sec_cnt_inc <= 3'd0; ded_cnt_inc <= 3'd0;
        end else begin
            valid_out <= s2_valid;
            if (s2_valid) begin
                data_out_32 <= {byte_out[3], byte_out[2], byte_out[1], byte_out[0]};
                sec_cnt_inc <= s2_sec_flag[0] + s2_sec_flag[1] + s2_sec_flag[2] + s2_sec_flag[3];
                ded_cnt_inc <= s2_ded_flag[0] + s2_ded_flag[1] + s2_ded_flag[2] + s2_ded_flag[3];
            end else begin
                sec_cnt_inc <= 3'd0; ded_cnt_inc <= 3'd0;
            end
        end
    end
endmodule