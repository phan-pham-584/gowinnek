// top_test_uart_rx.v
// Test UART RX: nhận byte từ PC, điều khiển 2 LED hiển thị 4 trạng thái
// PC gửi: 0x00 -> LED: tắt tắt (00)
//        0x01 -> LED: sáng tắt (01)
//        0x02 -> LED: tắt sáng (10)
//        0x03 -> LED: sáng sáng (11)
//        Các giá trị khác -> giữ nguyên trạng thái cũ

module top_module (
    input  wire clk_27m,
    input  wire uart_rx,           // UART RX from USB-UART
    output wire led_d3,            // LED D3 (bit0)
    output wire led_d4             // LED D4 (bit1)
);

    wire [7:0] rx_data;
    wire rx_valid;
    
    uart_rx u_uart_rx (
        .clk(clk_27m),
        .rst_n(1'b1),
        .rx(uart_rx),
        .data(rx_data),
        .data_valid(rx_valid)
    );
    
    // Lưu trạng thái hiện tại (2 bit)
    reg [1:0] led_state = 0;
    
    always @(posedge clk_27m) begin
        if (rx_valid) begin
            // Chỉ cập nhật khi nhận được 0x00, 0x01, 0x02, 0x03
            if (rx_data == 8'h00)
                led_state <= 2'b00;
            else if (rx_data == 8'h01)
                led_state <= 2'b01;
            else if (rx_data == 8'h02)
                led_state <= 2'b10;
            else if (rx_data == 8'h03)
                led_state <= 2'b11;
            // Các giá trị khác: giữ nguyên
        end
    end
    
    assign led_d3 = led_state[0];
    assign led_d4 = led_state[1];

endmodule