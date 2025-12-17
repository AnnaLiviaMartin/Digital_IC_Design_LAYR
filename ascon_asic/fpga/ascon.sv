module ascon(
    input clk_25mhz,
    input [6:0] btn,
    inout [0:4] gp, //GPIO pins for UART
    output wifi_gpio0
);
    wire core_clk;
    wire core_tx_phy;
    wire core_rx_phy;
    wire core_reset_n_phy;
    wire core_msg_last_phy;

    assign wifi_gpio0 = 1'b1;
    assign core_clk = clk_25mhz;

    assign core_tx_phy = gp[0];
    assign core_rx_phy = gp[2];
    assign core_reset_n_phy = gp[3];
    assign core_msg_last_phy = gp[1];


    // UART TX instance
    reg [7:0] tx_byte;
    reg tx_dv = 1'b0;
    wire tx_active;
    wire tx_done;
    uart_tx uart_tx_inst ( 
        .i_Clock(core_clk),
        .i_Tx_DV(tx_dv),
        .i_Tx_Byte(tx_byte),
        .o_Tx_Active(tx_active),
        .o_Tx_Serial(core_tx_phy),
        .o_Tx_Done(tx_done)
    );
    // UART RX instance 
    wire rx_dv;
    wire [7:0] rx_byte;

    uart_rx uart_rx_inst (
        .i_Clock(core_clk),
        .i_Rx_Serial(core_rx_phy),
        .o_Rx_DV(rx_dv),
        .o_Rx_Byte(rx_byte)
    );
    
    // ASCON_TOP instance
    wire hash_ready;
    reg [0:63] msg_in;
    reg msg_start = 1'b0;
    reg msg_last = 1'b0;
    logic [0:255] hash_out;
    reg rst_n = 1'b0;

    ascon_statmachine_top ascon_top_inst (
        .clk(core_clk),
        .rst_n(core_reset_n_phy),
        .msg_in(msg_in),
        .msg_start(msg_start),
        .msg_last(msg_last),
        .hash_out(hash_out),
        .hash_ready(hash_ready)
    );
    
    reg [2:0] rx_byte_counter = 0;
    reg msg_complete = 0;
    reg msg_processed = 0;

    always @(posedge core_clk) begin
        if(~core_reset_n_phy) begin //reset internal state
            msg_in <= 64'h0000000000000000;
            msg_start <= 1'b0;
            msg_last <= 1'b0;
            rx_byte_counter <= 0;
            msg_complete <= 0;
            msg_processed <= 0;
        end else begin    
            if (rx_dv) begin
                case (rx_byte_counter)
                    3'd0: msg_in[56:63] <= rx_byte;
                    3'd1: msg_in[48:55] <= rx_byte;
                    3'd2: msg_in[40:47] <= rx_byte;
                    3'd3: msg_in[32:39] <= rx_byte;
                    3'd4: msg_in[24:31] <= rx_byte;
                    3'd5: msg_in[16:23] <= rx_byte;
                    3'd6: msg_in[8:15] <= rx_byte;
                    3'd7: msg_in[0:7] <= rx_byte;
                endcase
                rx_byte_counter <= rx_byte_counter + 1;
                msg_start <= 1'b0;
                msg_last <= 1'b0;
                msg_processed <= 0;

                if (rx_byte_counter == 3'd7) begin
                    msg_complete <= 1;
                    rx_byte_counter <= 0;
                end
            end

            if (msg_complete && !msg_processed) begin
                if (core_msg_last_phy) begin
                    msg_start <= 1'b1;
                    msg_last <= 1'b1;
                end else begin
                    msg_start <= 1'b1;
                    msg_last <= 1'b0;
                end
                msg_processed <= 1;
                msg_complete <= 0;
            end
        end
    end

reg [6:0] byte_counter = 0;
reg send_in_progress = 0;
reg was_send = 0;

always @(posedge core_clk) begin
    if (hash_ready && !send_in_progress && !was_send && ~core_msg_last_phy) begin
        send_in_progress <= 1;
        byte_counter <= 0;
        was_send <= 1;
    end

    if (send_in_progress && hash_ready) begin
        if (!tx_active && !tx_dv) begin
            if (byte_counter < 32) begin
                tx_byte <= hash_out[255 - byte_counter*8 -: 8];
                tx_dv <= 1'b1;
                byte_counter <= byte_counter + 1;
            end else begin
                was_send <= 1;
                send_in_progress <= 0;
            end
        end else begin
            tx_dv <= 1'b0;
        end
    end else if (!hash_ready) begin
        was_send <= 0;
        send_in_progress <= 0;
        byte_counter <= 0;
        tx_dv <= 1'b0;
    end
end


    // input clk_25mhz, // physical clock
    // input reset_n_phy,
    // input msg_last_phy,
    // input rx_phy,
    // output tx_phy


endmodule