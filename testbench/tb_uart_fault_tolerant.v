`timescale 1ns / 1ps

module tb_uart_fault_tolerant;

    reg         clk;
    reg         reset_n;

    reg         avs_s0_chipselect;
    reg  [2:0]  avs_s0_address;
    reg         avs_s0_read;
    reg         avs_s0_write;
    reg  [31:0] avs_s0_writedata;
    wire [31:0] avs_s0_readdata;
    wire        avs_s0_waitrequest;

    wire        ins_irq0_irq;
    wire        dma_tx_req;
    wire        dma_rx_req;

    wire        coe_uart_tx;
    reg         coe_uart_rx;
    wire [1:0]  coe_error_led;

    reg  [31:0] read_val;
    reg         ext_loopback_en; // Điều khiển nối dây ngoài hoặc giả lập nhiễu đường dây

    // Nối dây TX -> RX bên ngoài khi bật ext_loopback_en
    always @(*) begin
        if (ext_loopback_en)
            coe_uart_rx = coe_uart_tx;
        else
            coe_uart_rx = 1'b1;
    end

    uart_avalon_32bit_ip u_dut (
        .clk                (clk),
        .reset_n            (reset_n),
        .avs_s0_chipselect  (avs_s0_chipselect),
        .avs_s0_address     (avs_s0_address),
        .avs_s0_read        (avs_s0_read),
        .avs_s0_write       (avs_s0_write),
        .avs_s0_writedata   (avs_s0_writedata),
        .avs_s0_readdata    (avs_s0_readdata),
        .avs_s0_waitrequest (avs_s0_waitrequest),
        .ins_irq0_irq       (ins_irq0_irq),
        .dma_tx_req         (dma_tx_req),
        .dma_rx_req         (dma_rx_req),
        .coe_uart_tx        (coe_uart_tx),
        .coe_uart_rx        (coe_uart_rx),
        .coe_error_led      (coe_error_led)
    );

    // Xung nhịp hệ thống 50 MHz (Chu kỳ 20 ns)
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // Task Ghi chuẩn Avalon-MM (Zero-Waitstate)
    task avalon_write(input [2:0] addr, input [31:0] data);
        begin
            @(posedge clk); #1;
            avs_s0_chipselect = 1'b1;
            avs_s0_address    = addr;
            avs_s0_write      = 1'b1;
            avs_s0_read       = 1'b0;
            avs_s0_writedata  = data;
            @(posedge clk); #1;
            avs_s0_chipselect = 1'b0;
            avs_s0_write      = 1'b0;
            avs_s0_writedata  = 32'd0;
        end
    endtask

    // Task Đọc chuẩn Avalon-MM
    task avalon_read(input [2:0] addr, output [31:0] data_out);
        begin
            @(posedge clk); #1;
            avs_s0_chipselect = 1'b1;
            avs_s0_address    = addr;
            avs_s0_read       = 1'b1;
            avs_s0_write      = 1'b0;
            #1;
            data_out = avs_s0_readdata;
            @(posedge clk); #1;
            avs_s0_chipselect = 1'b0;
            avs_s0_read       = 1'b0;
        end
    endtask

    initial begin
        reset_n           = 1'b0;
        ext_loopback_en   = 1'b1;
        avs_s0_chipselect = 1'b0;
        avs_s0_address    = 3'd0;
        avs_s0_read       = 1'b0;
        avs_s0_write      = 1'b0;
        avs_s0_writedata  = 32'd0;
        read_val          = 32'd0;

        #100; reset_n = 1'b1; #40;

        // Cài đặt BAUD_REG = 2 (mô phỏng nhanh) & bật IRQ + DMA_TX + DMA_RX
        avalon_write(3'd3, 32'd2);
        avalon_write(3'd2, 32'h0000_000E);

        // =========================================================================
        // CASE 1: TRUYỀN DỮ LIỆU SẠCH (0x12345678)
        // =========================================================================
        $display("\n[CASE 1] Truyen du lieu sach 0x12345678");
        avalon_write(3'd5, 32'h0000_0000);
        avalon_write(3'd0, 32'h1234_5678);
        wait(ins_irq0_irq == 1'b1); #100;
        avalon_read(3'd0, read_val);
        $display(" -> Thu duoc: 0x%08h | LED_ERR: %b", read_val, coe_error_led);
        #300;

        // =========================================================================
        // CASE 2: LỖI ĐƠN 1-BIT NGẪU NHIÊN (Bit 20) -> 0xAABBCCDD
        // =========================================================================
        $display("\n[CASE 2] Tiem loi don 1-bit tai vi tri 20");
        avalon_write(3'd5, 32'h0000_0114); // Mask = 4'b0001 tại bit 20 (0x14)
        avalon_write(3'd0, 32'hAABB_CCDD);
        wait(ins_irq0_irq == 1'b1); #100;
        avalon_read(3'd0, read_val);
        $display(" -> Thu duoc: 0x%08h | LED_ERR: %b (SEC=1)", read_val, coe_error_led);
        avalon_write(3'd1, 32'h0000_0004); // W1C xóa cờ SEC
        #300;

        // =========================================================================
        // CASE 3: NHIỄU CHÙM 4-BIT THẲNG CỘT (Bit 8..11) -> 0xDEADBEEF
        // =========================================================================
        $display("\n[CASE 3] Tiem loi chum 4-bit thang cot (Bit 8..11)");
        avalon_write(3'd5, 32'h0000_0F08); // Mask = 4'b1111 tại bit 8
        avalon_write(3'd0, 32'hDEAD_BEEF);
        wait(ins_irq0_irq == 1'b1); #100;
        avalon_read(3'd0, read_val);
        $display(" -> Thu duoc: 0x%08h | LED_ERR: %b (Sua sach 4 bit)", read_val, coe_error_led);
        avalon_write(3'd1, 32'h0000_0004); // W1C xóa cờ SEC
        #300;

        // =========================================================================
        // CASE 4: NHIỄU CHÙM 4-BIT LỆCH BIÊN CỘT (Bit 10..13) -> 0xCAFEBABE
        // =========================================================================
        $display("\n[CASE 4] Tiem loi chum 4-bit lech bien cot (Bit 10..13)");
        avalon_write(3'd5, 32'h0000_0F0A); // Mask = 4'b1111 tại bit 10 (0x0A)
        avalon_write(3'd0, 32'hCAFE_BABE);
        wait(ins_irq0_irq == 1'b1); #100;
        avalon_read(3'd0, read_val);
        avalon_read(3'd4, read_val);
        $display(" -> ERR_CNT_REG: SEC_CNT=%0d (Ky vong: 1+4+4 = 9)", read_val[15:0]);
        avalon_write(3'd1, 32'h0000_0004);
        #300;

        // =========================================================================
        // CASE 5: LỖI KÉP TRONG CÙNG 1 HÀNG (DED - Lật bit 0 và bit 4) -> 0x55AA55AA
        // Dùng force tác động trực tiếp lên rx_injected_52_w để giả lập 2 bit lỗi cùng Hàng 0
        // =========================================================================
        $display("\n[CASE 5] Gia lap loi kep 2-bit trong cung Hang 0 (DED Detection)");
        avalon_write(3'd5, 32'h0000_0000);
        force u_dut.rx_injected_52_w = u_dut.rx_raw_52_w ^ 52'h0000_0000_00011; // Lật bit 0 và bit 4
        avalon_write(3'd0, 32'h55AA_55AA);
        wait(ins_irq0_irq == 1'b1); #100;
        avalon_read(3'd1, read_val);
        $display(" -> STATUS_REG: DED_FLAG=%b | LED_ERR=%b", read_val[3], coe_error_led);
        release u_dut.rx_injected_52_w;
        avalon_write(3'd1, 32'h0000_0008); // W1C xóa cờ DED
        #300;

        // =========================================================================
        // CASE 6: LỖI KHUNG TRUYỀN (FRAMING ERROR - Stop bit bị kéo xuống 0)
        // =========================================================================
        $display("\n[CASE 6] Gia lap loi khung truyen (Framing Error)");
        avalon_write(3'd0, 32'h1122_3344);
        // Chờ tới gần cuối khung (khoảng 53 chu kỳ bit = 53 * 32 * 20ns = 33,920 ns) để kéo RX về 0 ngay lúc Stop bit
        #33800;
        ext_loopback_en = 1'b0;
        coe_uart_rx     = 1'b0; // Ép Stop bit = 0
        wait(ins_irq0_irq == 1'b1); #100;
        avalon_read(3'd1, read_val);
        $display(" -> STATUS_REG: FRAME_ERR=%b (Ky vong: 1)", read_val[4]);
        ext_loopback_en = 1'b1;
        avalon_write(3'd1, 32'h0000_0010); // W1C xóa cờ FRAME_ERR
        #300;

        // =========================================================================
        // CASE 7: KIỂM THỬ INTERNAL LOOPBACK & BẮT TAY DMA (CONTROL_REG[4] = 1)
        // =========================================================================
        $display("\n[CASE 7] Kiem thu che do Internal Loopback & DMA Handshake");
        ext_loopback_en = 1'b0; // Ngắt dây ngoài hoàn toàn
        avalon_write(3'd2, 32'h0000_001E); // Bật bit[4] LOOPBACK_EN + DMA + IRQ
        avalon_write(3'd0, 32'h89AB_CDEF);
        wait(ins_irq0_irq == 1'b1); #100;
        avalon_read(3'd0, read_val);
        $display(" -> Internal Loopback thu duoc: 0x%08h (Ky vong: 0x89ABCDEF)", read_val);

        #500;
        $display("\n=== HOAN THANH TOAN BO 7 CASE MO PHONG ===");
        $stop;
    end

endmodule
