// uart_rx.v
// UART receiver: 9600 baud, 8N1, clock 27 MHz

module uart_rx (
    input  wire clk,
    input  wire rst_n,
    input  wire rx,                 // UART input from PC
    output reg  [7:0] data,        // Received data byte
    output reg  data_valid         // 1 clock pulse when data is ready
);

    localparam CLK_FREQ = 27000000;
    localparam BAUD_RATE = 9600;
    localparam BIT_TICKS = CLK_FREQ / BAUD_RATE;  // 2812.5 -> 2813
    localparam BIT_TICKS_HALF = BIT_TICKS / 2;    // 1406
    
    reg [13:0] counter;        // bit tick counter
    reg [3:0] bit_index;       // 0=start, 1-8=data, 9=stop
    reg [7:0] rx_buffer;       // shift register
    reg rx_sync1, rx_sync2;    // double sync for metastability
    reg rx_prev;
    reg receiving;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            bit_index <= 0;
            rx_buffer <= 0;
            data <= 0;
            data_valid <= 0;
            rx_sync1 <= 1;
            rx_sync2 <= 1;
            rx_prev <= 1;
            receiving <= 0;
        end else begin
            // Double synchronizer
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
            
            // Defaults
            data_valid <= 0;
            
            if (!receiving) begin
                // Detect start bit (falling edge)
                if (rx_sync2 == 0 && rx_prev == 1) begin
                    receiving <= 1;
                    counter <= 1;
                    bit_index <= 0;
                end
            end else begin
                // Sampling at middle of each bit
                if (counter == BIT_TICKS_HALF) begin
                    // Sample the bit
                    if (bit_index == 0) begin
                        // Start bit - should be 0
                        if (rx_sync2 != 0) begin
                            receiving <= 0;  // false start
                        end
                    end else if (bit_index <= 8) begin
                        // Data bits (LSB first)
                        rx_buffer[bit_index - 1] <= rx_sync2;
                    end else if (bit_index == 9) begin
                        // Stop bit - should be 1
                        if (rx_sync2 == 1) begin
                            data <= rx_buffer;
                            data_valid <= 1;
                        end
                        receiving <= 0;
                    end
                    counter <= counter + 1;
                end else if (counter == BIT_TICKS - 1) begin
                    counter <= 0;
                    bit_index <= bit_index + 1;
                end else begin
                    counter <= counter + 1;
                end
            end
            
            rx_prev <= rx_sync2;
        end
    end

endmodule