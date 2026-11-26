onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {=== 1. AVALON-MM BUS, IRQ & DMA ===}
add wave -noupdate -color White /tb_uart_fault_tolerant/clk
add wave -noupdate -color Orange /tb_uart_fault_tolerant/reset_n
add wave -noupdate -radix unsigned /tb_uart_fault_tolerant/avs_s0_address
add wave -noupdate -color Cyan /tb_uart_fault_tolerant/avs_s0_write
add wave -noupdate -color Cyan -radix hexadecimal /tb_uart_fault_tolerant/avs_s0_writedata
add wave -noupdate -color Yellow /tb_uart_fault_tolerant/avs_s0_read
add wave -noupdate -color Yellow -radix hexadecimal /tb_uart_fault_tolerant/avs_s0_readdata
add wave -noupdate -color Magenta /tb_uart_fault_tolerant/ins_irq0_irq
add wave -noupdate /tb_uart_fault_tolerant/dma_tx_req
add wave -noupdate /tb_uart_fault_tolerant/dma_rx_req
add wave -noupdate -divider {=== 2. TX PIPELINE & MATRIX INTERLEAVING (4x13) ===}
add wave -noupdate -radix hexadecimal /tb_uart_fault_tolerant/u_dut/u_tx_pipe/s1_data
add wave -noupdate -radix hexadecimal /tb_uart_fault_tolerant/u_dut/u_tx_pipe/s2_cw0
add wave -noupdate -radix hexadecimal /tb_uart_fault_tolerant/u_dut/u_tx_pipe/s2_cw1
add wave -noupdate -radix hexadecimal /tb_uart_fault_tolerant/u_dut/u_tx_pipe/s2_cw2
add wave -noupdate -radix hexadecimal /tb_uart_fault_tolerant/u_dut/u_tx_pipe/s2_cw3
add wave -noupdate -color Gold -radix hexadecimal /tb_uart_fault_tolerant/u_dut/u_tx_pipe/interleaved_out_52
add wave -noupdate -color SpringGreen /tb_uart_fault_tolerant/coe_uart_tx
add wave -noupdate -color SpringGreen /tb_uart_fault_tolerant/coe_uart_rx
add wave -noupdate -divider {=== 3. ERROR INJECTION & HAMMING CORRECTION ===}
add wave -noupdate -radix hexadecimal /tb_uart_fault_tolerant/u_dut/rx_raw_52_w
add wave -noupdate -color Coral -radix hexadecimal /tb_uart_fault_tolerant/u_dut/rx_injected_52_w
add wave -noupdate -color Yellow -radix binary /tb_uart_fault_tolerant/u_dut/u_rx_pipe/s2_sec_flag
add wave -noupdate -color Red -radix binary /tb_uart_fault_tolerant/u_dut/u_rx_pipe/s2_ded_flag
add wave -noupdate -color Cyan -radix hexadecimal /tb_uart_fault_tolerant/u_dut/u_rx_pipe/data_out_32
add wave -noupdate -color Yellow -radix unsigned /tb_uart_fault_tolerant/u_dut/sec_err_cnt
add wave -noupdate -color Red -radix unsigned /tb_uart_fault_tolerant/u_dut/ded_err_cnt
add wave -noupdate -radix binary /tb_uart_fault_tolerant/coe_error_led
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 285
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {222065550 ps}
