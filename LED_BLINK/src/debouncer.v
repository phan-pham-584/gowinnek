// debouncer.v
module debouncer #(
    parameter DEBOUNCE_CYCLES = 1_000_000  // 20ms at 50MHz
)(
    input  wire clk,
    input  wire rst_n,
    input  wire noisy_in,
    output reg  debounced_out
);
    reg [$clog2(DEBOUNCE_CYCLES)-1:0] counter;
    reg stable_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            stable_state <= 1'b1;
            debounced_out <= 1'b1;
        end else begin
            if (noisy_in == stable_state) begin
                counter <= 0;
            end else begin
                if (counter == DEBOUNCE_CYCLES - 1) begin
                    stable_state <= noisy_in;
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end
            debounced_out <= stable_state;
        end
    end
endmodule