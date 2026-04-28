// =============================================================================
//  Project   : Pomodoro Timer (Upgraded v3)
//  Module    : pomodoro
//  Target    : Digilent Basys 3 (Artix-7 XC7A35T)
//  Clock     : 100 MHz onboard oscillator
// -----------------------------------------------------------------------------
//  Description:
//    Further upgraded version of the Pomodoro timer for Basys 3.
//    New Features:
//    - Auto-transition between Work and Break sessions.
//    - Distraction and Pomodoro counters expanded to 6 bits (0-63).
//    - LED mapping adjusted to accommodate 6-bit counters.
//    - LED[15:12] for status (Work, Break, Running, Paused).
//    - LED[11:6] for Distraction count (binary, 6 bits, max 63).
//    - LED[5:0] for Completed Pomodoros count (binary, 6 bits, max 63).
// =============================================================================

module pomodoro (
    input  wire        clk,          // 100 MHz system clock
    input  wire        btnC,         // Play / Pause button (center)
    input  wire        btnL,         // Reset button (left)
    input  wire [3:0]  sw,           // sw[1]=demo, sw[2]=method, sw[3]=stats
    output reg  [6:0]  seg,          // 7-segment cathode segments {G,F,E,D,C,B,A}
    output reg  [3:0]  an,           // 7-segment anode select (active LOW)
    output wire        dp,           // Decimal point (colon proxy)
    output reg  [15:0] led           // 16 status LEDs
);

// =============================================================================
//  PARAMETERS
// =============================================================================

    localparam CLK_FREQ       = 100_000_000;
    localparam CLASSIC_WORK   = 25 * 60;
    localparam CLASSIC_BREAK  =  5 * 60;
    localparam LONG_BREAK     = 15 * 60;   // 15-minute long break
    localparam METHOD_WORK    = 52 * 60;
    localparam METHOD_BREAK   = 17 * 60;
    localparam DEBOUNCE_TICKS = 2_000_000;
    localparam REFRESH_TICKS  = 100_000;
    localparam ONE_SEC        = CLK_FREQ;
    localparam DEMO_SEC       = CLK_FREQ / 60;

// =============================================================================
//  STATE ENCODING
// =============================================================================

    localparam ST_IDLE    = 2'd0;
    localparam ST_RUNNING = 2'd1;
    localparam ST_PAUSED  = 2'd2;
    localparam ST_DONE    = 2'd3;

    localparam PHASE_WORK  = 1'b0;
    localparam PHASE_BREAK = 1'b1;

// =============================================================================
//  INTERNAL SIGNALS
// =============================================================================

    wire sw_demo   = sw[1];
    wire sw_method = sw[2];
    wire sw_stats  = sw[3];

    reg [13:0] work_dur;
    reg [13:0] break_dur;

    reg [1:0]  state;
    reg        phase;
    reg [13:0] timer_sec;

    reg [26:0] tick_ctr;
    reg        sec_tick;

    reg [5:0]  distractions;  // Expanded to 6 bits (0-63)
    reg [5:0]  pomodoros;     // Expanded to 6 bits (0-63)
    reg [2:0]  session_in_set;  // Tracks 1 to 4 within a set for long break
    reg        is_long_break;   // Flag to indicate current break is long

    reg [20:0] db_ctr_c;
    reg        btn_c_prev, btn_c_clean, btn_c_edge;

    reg [20:0] db_ctr_l;
    reg        btn_l_prev, btn_l_clean, btn_l_edge;

    reg [16:0] refresh_ctr;
    reg [1:0]  digit_sel;
    reg [3:0]  digit_val;

    reg [5:0]  mm_tens, mm_ones, ss_tens, ss_ones;
    reg [3:0]  dist_tens, dist_ones, pomo_tens, pomo_ones; // Still 4-bit for 7-seg display

    reg        blink_reg;
    reg [26:0] blink_ctr;
    reg        dp_reg;

// =============================================================================
//  WORK / BREAK DURATION SELECTOR
// =============================================================================

    always @(*) begin
        if (sw_method) begin
            work_dur  = METHOD_WORK[13:0];
            break_dur = METHOD_BREAK[13:0];
        end else begin
            work_dur  = CLASSIC_WORK[13:0];
            // Standard break or Long break
            if (is_long_break)
                break_dur = LONG_BREAK[13:0];
            else
                break_dur = CLASSIC_BREAK[13:0];
        end
    end

// =============================================================================
//  DEBOUNCE: btnC (Play/Pause)
// =============================================================================

    always @(posedge clk) begin
        btn_c_edge <= 1'b0;
        if (btnC == btn_c_prev) begin
            if (db_ctr_c == DEBOUNCE_TICKS[20:0]) begin
                if (btnC != btn_c_clean) begin
                    btn_c_clean <= btnC;
                    if (btnC == 1'b1)
                        btn_c_edge <= 1'b1;
                end
            end else begin
                db_ctr_c <= db_ctr_c + 1'b1;
            end
        end else begin
            db_ctr_c  <= 21'd0;
            btn_c_prev <= btnC;
        end
    end

// =============================================================================
//  DEBOUNCE: btnL (Reset)
// =============================================================================

    always @(posedge clk) begin
        btn_l_edge <= 1'b0;
        if (btnL == btn_l_prev) begin
            if (db_ctr_l == DEBOUNCE_TICKS[20:0]) begin
                if (btnL != btn_l_clean) begin
                    btn_l_clean <= btnL;
                    if (btnL == 1'b1)
                        btn_l_edge <= 1'b1;
                end
            end else begin
                db_ctr_l <= db_ctr_l + 1'b1;
            end
        end else begin
            db_ctr_l  <= 21'd0;
            btn_l_prev <= btnL;
        end
    end

// =============================================================================
//  SECOND TICK GENERATOR
// =============================================================================

    wire [26:0] sec_limit = sw_demo ? DEMO_SEC[26:0] : ONE_SEC[26:0];

    always @(posedge clk) begin
        sec_tick <= 1'b0;
        if (state == ST_RUNNING) begin
            if (tick_ctr >= sec_limit - 1) begin
                tick_ctr <= 27'd0;
                sec_tick <= 1'b1;
            end else begin
                tick_ctr <= tick_ctr + 1'b1;
            end
        end else begin
            tick_ctr <= 27'd0;
        end
    end

// =============================================================================
//  BLINK GENERATOR
// =============================================================================

    always @(posedge clk) begin
        if (blink_ctr >= ONE_SEC[26:0] - 1) begin
            blink_ctr <= 27'd0;
            blink_reg <= ~blink_reg;
        end else begin
            blink_ctr <= blink_ctr + 1'b1;
        end
    end

// =============================================================================
//  MAIN FSM + TIMER LOGIC
// =============================================================================

    always @(posedge clk) begin
        if (btn_l_edge) begin
            state           <= ST_IDLE;
            phase           <= PHASE_WORK;
            timer_sec       <= work_dur;
            distractions    <= 6'd0;
            pomodoros       <= 6'd0;
            session_in_set  <= 3'd0;
            is_long_break   <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    timer_sec <= work_dur;
                    if (btn_c_edge)
                        state <= ST_RUNNING;
                end

                ST_RUNNING: begin
                    if (btn_c_edge) begin
                        state <= ST_PAUSED;
                        if (phase == PHASE_WORK && distractions < 6'd63)
                            distractions <= distractions + 1'b1;
                    end else if (sec_tick) begin
                        if (timer_sec == 14'd0) begin
                            state <= ST_DONE;
                        end else begin
                            timer_sec <= timer_sec - 14'd1;
                        end
                    end
                end

                ST_PAUSED: begin
                    if (btn_c_edge)
                        state <= ST_RUNNING;
                end

                ST_DONE: begin
                    if (phase == PHASE_WORK) begin
                        // Work session completed
                        if (pomodoros < 6'd63)
                            pomodoros <= pomodoros + 1'b1;
                        
                        // Increment set counter
                        if (session_in_set == 3'd3) begin
                            session_in_set <= 3'd0; // Reset set counter after 4th session
                            is_long_break  <= 1'b1; // Trigger long break
                        end else begin
                            session_in_set <= session_in_set + 1'b1;
                            is_long_break  <= 1'b0;
                        end
                        
                        phase     <= PHASE_BREAK;
                        // timer_sec will be updated by always@(*) based on is_long_break
                        state     <= ST_RUNNING; // Auto-start break
                    end else begin
                        // Break session completed
                        phase           <= PHASE_WORK;
                        is_long_break   <= 1'b0;
                        state           <= ST_RUNNING; // Auto-start work
                    end
                end

                default: state <= ST_IDLE;
            endcase
            
            // Sync timer_sec when entering RUNNING from DONE to show correct duration
            if (state == ST_DONE) begin
                if (phase == PHASE_WORK) begin
                    if (session_in_set == 3'd3) // We just finished the 4th session
                        timer_sec <= LONG_BREAK[13:0];
                    else
                        timer_sec <= break_dur[13:0];
                end else begin
                    timer_sec <= work_dur;
                end
            end
        end
    end

// =============================================================================
//  MM:SS DECOMPOSITION
// =============================================================================

    wire [7:0] mins = timer_sec / 8'd60;
    wire [7:0] secs = timer_sec % 8'd60;

    always @(*) begin
        mm_tens = mins / 6'd10;
        mm_ones = mins % 6'd10;
        ss_tens = secs / 6'd10;
        ss_ones = secs % 6'd10;

        // For 6-bit counters (up to 63), tens can go up to 6
        dist_tens = distractions / 6'd10;
        dist_ones = distractions % 6'd10;
        pomo_tens = pomodoros    / 6'd10;
        pomo_ones = pomodoros    % 6'd10;
    end

// =============================================================================
//  7-SEGMENT DISPLAY MULTIPLEXER
// =============================================================================

    always @(posedge clk) begin
        if (refresh_ctr >= REFRESH_TICKS[16:0] - 1) begin
            refresh_ctr <= 17'd0;
            digit_sel   <= digit_sel + 1'b1;
        end else begin
            refresh_ctr <= refresh_ctr + 1'b1;
        end
    end

    always @(*) begin
        an      = 4'b1111;
        dp_reg  = 1'b1;
        digit_val = 4'd0;

        case (digit_sel)
            2'd3: begin // Leftmost (AN3)
                an = 4'b0111;
                digit_val = sw_stats ? dist_tens : mm_tens[3:0];
            end
            2'd2: begin // (AN2)
                an = 4'b1011;
                digit_val = sw_stats ? dist_ones : mm_ones[3:0];
                if (!sw_stats && state == ST_RUNNING)
                    dp_reg = ~blink_reg;
            end
            2'd1: begin // (AN1)
                an = 4'b1101;
                digit_val = sw_stats ? pomo_tens : ss_tens[3:0];
            end
            2'd0: begin // Rightmost (AN0)
                an = 4'b1110;
                digit_val = sw_stats ? pomo_ones : ss_ones[3:0];
            end
        endcase
    end

    assign dp = dp_reg;

// =============================================================================
//  7-SEGMENT DECODER (Common Anode, 0=ON)
// =============================================================================

    always @(*) begin
        case (digit_val)
            4'd0: seg = 7'b100_0000;
            4'd1: seg = 7'b111_1001;
            4'd2: seg = 7'b010_0100;
            4'd3: seg = 7'b011_0000;
            4'd4: seg = 7'b001_1001;
            4'd5: seg = 7'b001_0010;
            4'd6: seg = 7'b000_0010;
            4'd7: seg = 7'b111_1000;
            4'd8: seg = 7'b000_0000;
            4'd9: seg = 7'b001_0000;
            default: seg = 7'b111_1111;
        endcase
    end

// =============================================================================
//  LED STATUS PANEL
// =============================================================================

    always @(*) begin
        led = 16'b0;
        // Status LEDs (LD15-LD12)
        led[15] = (phase == PHASE_WORK);          // LD15: Work
        led[14] = (phase == PHASE_BREAK);         // LD14: Break
        led[13] = (state == ST_RUNNING) & blink_reg; // LD13: Running blink
        led[12] = (state == ST_PAUSED);              // LD12: Paused solid

        // Distraction count (LD11-LD6)
        led[11:6] = distractions[5:0];
        
        // Completed Pomodoros count (LD5-LD0)
        led[5:0] = pomodoros[5:0];
    end

endmodule
