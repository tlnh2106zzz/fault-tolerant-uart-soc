# Khai báo xung nhịp hệ thống 50 MHz (chu kỳ 20.000 ns) cho chân CLOCK_50
create_clock -name "CLOCK_50" -period 20.000ns [get_ports {CLOCK_50}]

# Tự động tính toán độ lệch xung nhịp (Clock Uncertainty)
derive_clock_uncertainty

# Bỏ qua kiểm tra timing cho các chân I/O bất đồng bộ (nút nhấn, LED, dây UART)
set_false_path -from [get_ports {KEY[*] UART_RXD}]
set_false_path -to [get_ports {LEDR[*] UART_TXD}]