// wdi_edge_detector.v
module wdi_edge_detector (
    input  wire clk,
    input  wire rst_n,
    input  wire wdi_in,          // Raw or debounced WDI
    input  wire enable,          // Enable edge detection
    output reg  falling_edge
);
    reg wdi_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdi_prev <= 1'b1;
            falling_edge <= 1'b0;
        end else begin
            wdi_prev <= wdi_in;
            
            if (enable && (wdi_prev == 1'b1 && wdi_in == 1'b0))
                falling_edge <= 1'b1;
            else
                falling_edge <= 1'b0;
        end
    end
endmodule