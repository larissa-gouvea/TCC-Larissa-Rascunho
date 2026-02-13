library IEEE;
library work;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity frontend_slave is
    port(
        -- AXI-Stream signals.
        ACLK: in std_logic;
        ARESETn: in std_logic;

            -- Write data signals.
            TID  : out std_logic;
            TVALID : out std_logic;
            TREADY : in std_logic;
            TDATA  : out std_logic_vector(31 downto 0);
            TLAST  : out std_logic;
            TSTRB : in std_logic_vector(3 downto 0); -- TDATA_WIDTH/8 (não está sendo utilizado ainda)
            TKEEP : in std_logic_vector(3 downto 0); -- TDATA_WIDTH/8 (não está sendo utilizado ainda)
        
            -- Extra signals.
            CORRUPT_PACKET: out std_logic;

        -- Backend signals (injection).

        -- Backend signals (reception).
        i_VALID_RECEIVE_PACKET: in std_logic;
        i_VALID_RECEIVE_DATA  : in std_logic;
        i_LAST_RECEIVE_DATA   : in std_logic;

        i_ID_RECEIVE     : in std_logic_vector(4 downto 0);
        i_OPC_RECEIVE    : in std_logic;
        i_DATA_RECEIVE   : in std_logic_vector(31 downto 0);

        i_CORRUPT_RECEIVE: in std_logic;

        o_READY_RECEIVE_PACKET: out std_logic;
        o_READY_RECEIVE_DATA  : out std_logic
    );
end frontend_slave;

architecture rtl of frontend_slave is
    signal w_VALID_SEND_DATA: std_logic;

begin
    -- Reception.
    o_READY_RECEIVE_PACKET <= '1' when (i_OPC_RECEIVE = '0' and TREADY = '1') else '0';
    o_READY_RECEIVE_DATA   <= TREADY;

    TID    <= i_ID_RECEIVE when (i_OPC_RECEIVE = '0' and i_VALID_RECEIVE_PACKET = '1') else (4 downto 0 => '0');

    TVALID <= '1' when (i_OPC_RECEIVE = '0' and i_VALID_RECEIVE_DATA = '1') else '0';
    TDATA  <= i_DATA_RECEIVE when (i_VALID_RECEIVE_DATA = '1') else (31 downto 0 => '0');
    TLAST  <= i_LAST_RECEIVE_DATA;

    CORRUPT_PACKET <= i_CORRUPT_RECEIVE;
end rtl;
