`timescale 1ns / 1ps
module hamming_encoder_13_8 (
    input  wire [7:0]  data_in,      
    output wire [12:0] codeword_out  
);
    wire p1, p2, p4, p8, p_total;
    wire [11:0] h_code;

    assign p1 = data_in[7] ^ data_in[6] ^ data_in[4] ^ data_in[3] ^ data_in[1];
    assign p2 = data_in[7] ^ data_in[5] ^ data_in[4] ^ data_in[2] ^ data_in[1];
    assign p4 = data_in[6] ^ data_in[5] ^ data_in[4] ^ data_in[0];
    assign p8 = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0];

    assign h_code       = {p1, p2, data_in[7], p4, data_in[6:4], p8, data_in[3:0]};
    assign p_total      = ^h_code;
    assign codeword_out = {p_total, h_code};
endmodule