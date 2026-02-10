library IEEE;
library work;

use IEEE.std_logic_1164.all;

entity frontend_master is
    port(
        -- AMBA AXI 5 signals.
        ACLK: in std_logic;
        ARESETn: in std_logic;

            -- Write request signals.
            TID   : in std_logic_vector(4 downto 0); -- verificar tamanho do vetor
            TDEST : in std_logic_vector(63 downto 0); -- verificar tamanho do vetor

            -- Write data signals.
            TVALID : in std_logic; --TVALID DEPENDENCIA
            TREADY : out std_logic; -- TREADY
            TDATA  : in std_logic_vector(31 downto 0); --TDATA DEPENDENCIA
            TLAST  : in std_logic; --TLAST DEPENDENCIA

            -- Extra signals.
            CORRUPT_PACKET: out std_logic;

        -- Backend signals (injection).
        i_READY_SEND_DATA  : in std_logic;
        i_READY_SEND_PACKET: in std_logic; 

        o_START_SEND_PACKET: out std_logic;
        o_VALID_SEND_DATA  : out std_logic;
        o_LAST_SEND_DATA   : out std_logic;

        o_ADDR     : out std_logic_vector(63 downto 0);
        o_ID       : out std_logic_vector(4 downto 0);
        o_LENGTH   : out std_logic_vector(7 downto 0);
        o_BURST    : out std_logic_vector(1 downto 0);
        o_OPC_SEND : out std_logic;
        o_DATA_SEND: out std_logic_vector(31 downto 0);

        i_CORRUPT_RECEIVE: in std_logic

    );
end frontend_master;

architecture rtl of frontend_master is

    -- Injection.
    signal w_OPC_SEND: std_logic;

begin
    ---------------------------------------------------------------------------------------------
    -- Injection.

    -- Registering transaction information.
    registering: process(ACLK)
    begin
        if (rising_edge(ACLK)) then
            if (i_READY_SEND_PACKET = '1') then -- Esse sinal só é 1 no estado IDLE
                if (TVALID = '1') then 
                    -- Registering write signals.
                    w_OPC_SEND <= '0';

                    o_ADDR      <= TDEST; -- antigo AWADDR
                    o_ID        <= TID; -- antigo AWID
                    o_LENGTH    <= x"0F"; -- Valor fixo ou contador (AXIS não tem LENGTH) [1], antigo AWLEN
                    o_BURST     <= "01";  -- Fixo em Incremental [6], antigo AWBURST
                end if;
            end if;
        end if;
    end process registering;

    o_OPC_SEND <= w_OPC_SEND;

    -- Ready information to front-end.
    -- Control information.
    o_START_SEND_PACKET <= '1' when TVALID = '1' and i_READY_SEND_PACKET = '1' else '0'; -- no estado IDLE isso ocorre
    o_VALID_SEND_DATA   <= '1' when (w_OPC_SEND = '0' and TVALID = '1') else '0'; --'1' when (w_OPC_SEND = '0' and TVALID = '1') else '0';
    o_LAST_SEND_DATA    <= '1' when (w_OPC_SEND = '0' and TLAST = '1')  else '0'; -- '1' when (w_OPC_SEND = '0' and TLAST = '1')  else '0';
    o_DATA_SEND         <= TDATA when (w_OPC_SEND = '0' and TVALID = '1') else (others => '0'); --TDATA when (w_OPC_SEND = '0' and TVALID = '1') else (others => '0');

    TREADY  <= i_READY_SEND_DATA; 

    CORRUPT_PACKET <= i_CORRUPT_RECEIVE;
end rtl;















