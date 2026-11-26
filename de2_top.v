module de2_top (
    input  wire        CLOCK_50,
    input  wire [0:0]  KEY,
    output wire [1:0]  LEDR,
    output wire        UART_TXD,
    input  wire        UART_RXD
);

    wire dma_tx_req_w;
    wire dma_rx_req_w;

    system u_soc_system (
        .clk_clk                                            (CLOCK_50),
        .reset_reset_n                                      (KEY[0]),
        .uart_avalon_32_bit_ip_0_conduit_end_0_coe_uart_tx  (UART_TXD),
        .uart_avalon_32_bit_ip_0_conduit_end_0_coe_uart_rx  (UART_RXD),
        .uart_avalon_32_bit_ip_0_conduit_end_0_coe_error_led(LEDR[1:0]),
        .uart_avalon_32_bit_ip_0_conduit_end_0_dma_tx_req   (dma_tx_req_w),
        .uart_avalon_32_bit_ip_0_conduit_end_0_dma_rx_req   (dma_rx_req_w)
    );

endmodule