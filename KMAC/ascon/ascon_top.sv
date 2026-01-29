// combines all ascon core modules with UART instances
// implements uart controle logic
module ascon_top(
    input clk_25mhz, // physical clock
    input reset_n_phy,
    input msg_last_phy,
    input rx_phy,
    output tx_phy
);
    wire core_clk;
    wire core_tx_phy;
    wire core_rx_phy;
    wire core_reset_n_phy;
    wire core_msg_last_phy;

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
        end else begin  //on valid data receave msg byte per byte  
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

            if (msg_complete && !msg_processed) begin //check of full 64bit msg receaved and not yet processed
                if (core_msg_last_phy) begin
                    msg_start <= 1'b1; //start absorbing
                    msg_last <= 1'b1; //switch to SQUEEZE after absorbing
                end else begin
                    msg_start <= 1'b1; //start absorbing
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
    //only send Hash one time after msg_last pulled down by user
        send_in_progress <= 1;
        byte_counter <= 0;
        was_send <= 1;
    end

    if (send_in_progress && hash_ready) begin //send hash byte per byte
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

// physical pins assigned to IOPADS for the OpenRoad flow

(* keep *) sg13g2_IOPadIn u_pad_io_clk (.pad(clk_25mhz), .p2c(core_clk));
(* keep *) sg13g2_IOPadIn u_pad_rst_n (.pad(reset_n_phy), .p2c(core_reset_n_phy)); ;
(* keep *) sg13g2_IOPadIn u_pad_msg_last_phy (.pad(msg_last_phy), .p2c(core_msg_last_phy));
(* keep *) sg13g2_IOPadIn u_pad_rx_phy (.pad(rx_phy), .p2c(core_rx_phy));
(* keep *) sg13g2_IOPadOut4mA u_pad_tx_phy (.pad(tx_phy), .c2p(core_tx_phy));


(* keep *) sg13g2_IOPadIOVdd u_pad_vddpad_0 () ;
(* keep *) sg13g2_IOPadIOVdd u_pad_vddpad_1 () ;

(* keep *) sg13g2_IOPadVdd u_pad_vddcore_0 () ;
(* keep *) sg13g2_IOPadVdd u_pad_vddcore_1 () ;

(* keep *) sg13g2_IOPadIOVss u_pad_gndpad_0 () ;
(* keep *) sg13g2_IOPadIOVss u_pad_gndpad_1 () ;

(* keep *) sg13g2_IOPadVss u_pad_gndcore_0 () ;
(* keep *) sg13g2_IOPadVss u_pad_gndcore_1 () ;



endmodule