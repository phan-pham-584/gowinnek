// sync_debounce.sv
// Đồng bộ + debounce cho nút bấm (active low)
// Clock 27 MHz, debounce time ~10 ms

module sync_debounce #(
    parameter CLK_FREQ_HZ = 27_000_000,
    parameter DEBOUNCE_MS = 10           // 10 ms debounce
)(
    input  wire clk,
    input  wire rst_n,
    input  wire button_in,               // Nút bấm từ board (active low)
    output reg  button_out,              // Đã debounce, active low
    output reg  falling_edge,            // Xung 1 clock khi phát hiện cạnh xuống
    output reg  rising_edge              // Xung 1 clock khi phát hiện cạnh lên
);

    // Tính số ticks cho debounce
    localparam TICKS_PER_MS = CLK_FREQ_HZ / 1000;      // 27_000
    localparam DEBOUNCE_TICKS = DEBOUNCE_MS * TICKS_PER_MS;  // 10 * 27_000 = 270_000
    
    // 3 flip-flop để đồng bộ (tránh metastability)
    reg sync_ff1, sync_ff2, sync_ff3;
    
    // Bộ đếm debounce
    reg [31:0] counter;
    reg stable_state;
    
    // Đồng bộ button vào clock domain
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b1;
            sync_ff2 <= 1'b1;
            sync_ff3 <= 1'b1;
        end else begin
            sync_ff1 <= button_in;
            sync_ff2 <= sync_ff1;
            sync_ff3 <= sync_ff2;
        end
    end
    
    // Debounce FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
            stable_state <= 1'b1;   // Mặc định không bấm (high)
            button_out <= 1'b1;
        end else begin
            // Nếu tín hiệu đã ổn định (không thay đổi trong DEBOUNCE_TICKS)
            if (sync_ff3 == stable_state) begin
                if (counter < DEBOUNCE_TICKS) begin
                    counter <= counter + 1'b1;
                end else begin
                    button_out <= stable_state;
                end
            end else begin
                // Tín hiệu thay đổi, reset counter
                counter <= 32'd0;
                stable_state <= sync_ff3;
            end
        end
    end
    
    // Phát hiện cạnh (dùng button_out đã debounce)
    reg button_out_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_out_prev <= 1'b1;
            falling_edge <= 1'b0;
            rising_edge <= 1'b0;
        end else begin
            button_out_prev <= button_out;
            
            // Cạnh xuống: 1 -> 0
            falling_edge <= button_out_prev && ~button_out;
            
            // Cạnh lên: 0 -> 1
            rising_edge <= ~button_out_prev && button_out;
        end
    end

endmodule