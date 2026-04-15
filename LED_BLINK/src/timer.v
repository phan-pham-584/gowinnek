// timer.sv
// Timer đa năng: đếm đến MAX_TICKS, báo expired
// Hỗ trợ 2 chế độ: US_MODE = 1 (đếm us), US_MODE = 0 (đếm ms)
// Clock 27 MHz

module timer #(
    parameter CLK_FREQ_HZ = 27_000_000,
    parameter US_MODE = 1,           // 1 = us mode, 0 = ms mode
    parameter DEFAULT_TICKS = 1000   // Giá trị mặc định (số us hoặc ms)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire enable,              // 1 = cho phép đếm
    input  wire reset,               // 1 = reset counter về 0 (xung)
    input  wire [31:0] max_ticks,    // Số ticks cần đếm (us hoặc ms)
    output reg  expired             // 1 khi counter >= max_ticks
);

    // Tính số clock ticks cho 1 us hoặc 1 ms
    localparam TICKS_PER_UNIT = US_MODE ? (CLK_FREQ_HZ / 1_000_000) : (CLK_FREQ_HZ / 1_000);
    // Với 27 MHz: TICKS_PER_UNIT = 27 (us) hoặc 27_000 (ms)
    
    reg [31:0] counter;
    reg [31:0] ticks_target;
    
    // Cập nhật target khi max_ticks thay đổi
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ticks_target <= 32'd0;
        end else begin
            // Nhân với TICKS_PER_UNIT, cẩn thận tràn 32-bit
            ticks_target <= max_ticks * TICKS_PER_UNIT;
        end
    end
    
    // Bộ đếm chính
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
            expired <= 1'b0;
        end else begin
            if (reset) begin
                counter <= 32'd0;
                expired <= 1'b0;
            end else if (enable && (counter < ticks_target)) begin
                counter <= counter + 1'b1;
                expired <= 1'b0;
            end else if (enable && (counter >= ticks_target) && (ticks_target != 0)) begin
                expired <= 1'b1;   // Giữ expired = 1 cho đến khi reset
            end else if (!enable) begin
                expired <= 1'b0;
            end
        end
    end

endmodule