// clk_divider.v
// Generates 1us and 1ms clock enables from system clock
module clk_divider #(
    parameter SYS_CLK_HZ = 50_000_000  // 50 MHz system clock
)(
    input  wire clk,
    input  wire rst_n,
    output reg  clk_1us_en,    // 1us pulse enable
    output reg  clk_1ms_en     // 1ms pulse enable
);
    // 1us = 50 cycles at 50MHz
    localparam US_COUNT_MAX = SYS_CLK_HZ / 1_000_000 - 1;  // 49
    // 1ms = 50,000 cycles at 50MHz
    localparam MS_COUNT_MAX = SYS_CLK_HZ / 1_000 - 1;      // 49,999
    
    reg [15:0] us_counter;
    reg [15:0] ms_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            us_counter <= 0;
            ms_counter <= 0;
            clk_1us_en <= 0;
            clk_1ms_en <= 0;
        end else begin
            // 1us counter
            if (us_counter == US_COUNT_MAX) begin
                us_counter <= 0;
                clk_1us_en <= 1;
            end else begin
                us_counter <= us_counter + 1;
                clk_1us_en <= 0;
            end
            
            // 1ms counter
            if (ms_counter == MS_COUNT_MAX) begin
                ms_counter <= 0;
                clk_1ms_en <= 1;
            end else begin
                ms_counter <= ms_counter + 1;
                clk_1ms_en <= 0;
            end
        end
    end
endmodule