// uart_tx.v
// UART transmitter: 9600 baud, 8N1, clock 27 MHz

module uart_tx (
    input  wire clk,
    input  wire rst_n,
    input  wire [7:0] data,        // Data byte to send
    input  wire send,              // 1 clock pulse to start sending
    output reg  tx,                // UART output to PC
    output reg  busy              // 1 when sending, 0 when idle
);

    localparam CLK_FREQ = 27000000;
    localparam BAUD_RATE = 9600;
    localparam BIT_TICKS = CLK_FREQ / BAUD_RATE;  // 2812.5 -> 2813
    
    reg [13:0] counter;
    reg [3:0] bit_index;      // 0=start, 1-8=data, 9=stop
    reg [7:0] tx_buffer;
    reg sending;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            bit_index <= 0;
            tx_buffer <= 0;
            tx <= 1;           // idle high
            sending <= 0;
            busy <= 0;
        end else begin
            // Defaults
            busy <= sending;
            
            if (!sending && send) begin
                // Start sending
                sending <= 1;
                tx_buffer <= data;
                bit_index <= 0;
                counter <= 0;
                tx <= 0;       // start bit
            end else if (sending) begin
                if (counter == BIT_TICKS - 1) begin
                    counter <= 0;
                    bit_index <= bit_index + 1;
                    
                    if (bit_index == 0) begin
                        // Start bit done, send data bit 0 (LSB first)
                        tx <= tx_buffer[0];
                    end else if (bit_index <= 8) begin
                        // Send data bits 1-7
                        tx <= tx_buffer[bit_index];
                    end else if (bit_index == 8) begin
                        // Last data bit done, send stop bit
                        tx <= 1;
                    end else if (bit_index == 9) begin
                        // Stop bit done, finish
                        sending <= 0;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                tx <= 1;       // idle high
            end
        end
    end

endmodule