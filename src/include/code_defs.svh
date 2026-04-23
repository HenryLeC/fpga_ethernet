package code_defs;

    // RS Code - Table 46-3
    typedef enum logic [7:0]
    { RS_IDLE = 8'h07
    , RS_LPI = 8'h06
    , RS_SEQ = 8'h9C
    , RS_START = 8'hFB
    , RS_TERM = 8'hFD
    , RS_ERR = 8'hFE
    } rs_code_t;

    // CC Code - Table 49-1
    typedef enum logic [6:0] 
    { CC_IDLE = 7'h00
    , CC_LPI = 7'h06
    , CC_ERROR = 7'h1E
    } r_control_code_t;

    // Block Type - Figure 49-7
    typedef enum logic [7:0]
    { BT_IDLE = 8'h1E
    , BT_O4 = 8'h2D
    , BT_S4 = 8'h33
    , BT_O0S4 = 8'h66
    , BT_O0O4 = 8'h55
    , BT_S0 = 8'h78
    , BT_O0 = 8'h4B
    , BT_T0 = 8'h87
    , BT_T1 = 8'h99
    , BT_T2 = 8'hAA
    , BT_T3 = 8'hB4
    , BT_T4 = 8'hCC
    , BT_T5 = 8'hD2
    , BT_T6 = 8'hE1
    , BT_T7 = 8'hFF
    } bt_code_t;
endpackage