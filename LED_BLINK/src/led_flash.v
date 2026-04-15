// led_flash.sv
// Dùng timer để nháy LED với chu kỳ config được (đơn vị ms)
// Clock 27 MHz

module led_flash #(
    parameter CLK_FREQ_HZ = 27_000_000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [31:0] period_ms,    // Chu kỳ nháy (ms), LED sáng 1/2 chu kỳ
    output reg  led
);

    // Timer ở chế độ ms
    localparam TICKS_PER_MS = CLK_FREQ_HZ / 1000;  // = 27_000
    
    reg [31:0] counter;
    reg [31:0] half_period_ticks;
    reg        toggle_flag;
    
    // Tính số ticks cho nửa chu kỳ
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            half_period_ticks <= 32'd0;
        end else begin
            half_period_ticks <= (period_ms / 2) * TICKS_PER_MS;
            if (half_period_ticks == 0)
                half_period_ticks <= TICKS_PER_MS;  // Ít nhất 1 ms
        end
    end
    
    // Bộ đếm và toggle LED
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
            led <= 1'b0;
            toggle_flag <= 1'b0;
        end else begin
            if (counter >= half_period_ticks) begin
                counter <= 32'd0;
                led <= ~led;
                toggle_flag <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                toggle_flag <= 1'b0;
            end
        end
    end

endmodule