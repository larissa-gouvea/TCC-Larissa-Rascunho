library IEEE;
library work;

use IEEE.std_logic_1164.all;
use work.tcc_package.all;

entity frontend_master is
    port(
        -- AMBA AXI 5 signals.
        ACLK: in std_logic; -- DEPENDENCIA
        ARESETn: in std_logic;

            -- Write request signals.
            -- AWVALID: in std_logic; --DEPENDENCIA
            -- AWREADY: out std_logic;
            -- AWID   : in std_logic_vector(c_AXI_ID_WIDTH - 1 downto 0); --TID, DEPENDENCIA
            TID   : in std_logic_vector(c_AXI_ID_WIDTH - 1 downto 0); -- verificar tamanho do vetor
            -- AWADDR : in std_logic_vector(c_AXI_ADDR_WIDTH - 1 downto 0); -- TDEST, DEPENDENCIA
            TDEST : in std_logic_vector(c_AXI_ADDR_WIDTH - 1 downto 0); -- verificar tamanho do vetor
            -- AWLEN  : in std_logic_vector(7 downto 0); -- Fixei um valor pra ele, DEPENDENCIA 
            -- AWBURST: in std_logic_vector(1 downto 0); -- Fixei um valor pra ele, DEPENDENCIA

            -- Write data signals.
            TVALID : in std_logic; --TVALID DEPENDENCIA
            TREADY : out std_logic; -- TREADY
            TDATA  : in std_logic_vector(c_AXI_DATA_WIDTH - 1 downto 0); --TDATA DEPENDENCIA
            TLAST  : in std_logic; --TLAST DEPENDENCIA

            -- Write response signals. (ACHO QUE NEM VAI TER)
            BVALID : out std_logic;
            BREADY : in std_logic; --DEPENDENCIA
            BID    : out std_logic_vector(c_AXI_ID_WIDTH - 1 downto 0) := (others => '0');
            BRESP  : out std_logic_vector(c_AXI_RESP_WIDTH - 1 downto 0) := (others => '0');

            -- Read request signals.
            ARVALID: in std_logic; --DEPENDENCIA
            ARREADY: out std_logic; --DEPENDENCIA
            ARID   : in std_logic_vector(c_AXI_ID_WIDTH - 1 downto 0); --DEPENDENCIA
            ARADDR : in std_logic_vector(c_AXI_ADDR_WIDTH - 1 downto 0); --DEPENDENCIA
            ARLEN  : in std_logic_vector(7 downto 0); --DEPENDENCIA
            ARBURST: in std_logic_vector(1 downto 0); --DEPENDENCIA

            -- Read response/data signals.
            -- RVALID : out std_logic;
            -- RREADY : in std_logic;
            -- RDATA  : out std_logic_vector(c_AXI_DATA_WIDTH - 1 downto 0);
            -- RLAST  : out std_logic;
            -- RID    : out std_logic_vector(c_AXI_ID_WIDTH - 1 downto 0) := (others => '0');
            -- RRESP  : out std_logic_vector(c_AXI_RESP_WIDTH - 1 downto 0) := (others => '0');

            -- Extra signals.
            CORRUPT_PACKET: out std_logic;

        -- Backend signals (injection).
        i_READY_SEND_DATA  : in std_logic;
        i_READY_SEND_PACKET: in std_logic; --DEPENDENCIA

        o_START_SEND_PACKET: out std_logic;
        o_VALID_SEND_DATA  : out std_logic;
        o_LAST_SEND_DATA   : out std_logic;

        o_ADDR     : out std_logic_vector(c_AXI_ADDR_WIDTH - 1 downto 0);
        o_ID       : out std_logic_vector(c_AXI_ID_WIDTH - 1 downto 0);
        o_LENGTH   : out std_logic_vector(7 downto 0);
        o_BURST    : out std_logic_vector(1 downto 0);
        o_OPC_SEND : out std_logic;
        o_DATA_SEND: out std_logic_vector(c_AXI_DATA_WIDTH - 1 downto 0);

        -- Backend signals (reception).
        i_VALID_RECEIVE_DATA: in std_logic;
        i_LAST_RECEIVE_DATA : in std_logic;

        i_ID_RECEIVE    : in std_logic_vector(c_AXI_ID_WIDTH - 1 downto 0);
        i_STATUS_RECEIVE: in std_logic_vector(c_AXI_RESP_WIDTH - 1 downto 0);
        i_OPC_RECEIVE   : in std_logic; --DEPENDENCIA
        i_DATA_RECEIVE  : in std_logic_vector(c_AXI_DATA_WIDTH - 1 downto 0);

        i_CORRUPT_RECEIVE: in std_logic;

        o_READY_RECEIVE_PACKET: out std_logic;
        o_READY_RECEIVE_DATA  : out std_logic
    );
end frontend_master;

architecture rtl of frontend_master is
    --Sinal que eu coloquei
    signal last_packet_done : std_logic := '1';
    -- Injection.
    signal w_OPC_SEND: std_logic;

begin
    ---------------------------------------------------------------------------------------------
    -- Injection.

    -- Registering transaction information.
    registering: process(all)
    begin
        if (rising_edge(ACLK)) then
            if (i_READY_SEND_PACKET = '1') then -- Esse sinal só é 1 no estado IDLE
                if (TVALID = '1') then -- aparentemente quando incia o pacote, se o valid é 1 significa que os dados estão validos antigo AWVALID
                    -- Registering write signals.
                    w_OPC_SEND <= '0';

                    o_ADDR      <= TDEST; -- antigo AWADDR
                    o_ID        <= TID; -- antigo AWID
                    o_LENGTH    <= x"0F"; -- Valor fixo ou contador (AXIS não tem LENGTH) [1], antigo AWLEN
                    o_BURST     <= "01";  -- Fixo em Incremental [6], antigo AWBURST
                elsif (ARVALID = '1') then
                    -- Registering read signals.
                    w_OPC_SEND <= '1';

                    o_ADDR      <= ARADDR;
                    o_ID        <= ARID; 
                    o_LENGTH    <= ARLEN;
                    o_BURST     <= ARBURST;
                end if;
            end if;
        end if;
    end process registering;

    o_OPC_SEND <= w_OPC_SEND;

 -- eu vou adicionar if é codigo meu -----------------

                
    process(ACLK)
    begin
        if rising_edge(ACLK) then
            if ARESETn = '0' then
                last_packet_done <= '1';
            else
                -- Pacote terminou
                if TVALID = '1' and i_READY_SEND_DATA = '1' and TLAST = '1' then  -- i_READY_SEND_DATA = '1' no estado payload, 
                    last_packet_done <= '1'; 
                -- Novo pacote começou
                elsif TVALID = '1' and i_READY_SEND_DATA = '1' and last_packet_done = '1' then --- no meu seria ACHO TVALID = '1' and i_READY_SEND_DATA = '1' and last_packet_done = '1' then
                    last_packet_done <= '0';
                end if;
            end if;
        end if;
    end process;

-- START apenas no início de uma nova transação
o_START_SEND_PACKET <= '1' when last_packet_done = '1' and TVALID = '1' and i_READY_SEND_PACKET = '1' else '0'; -- no estado IDLE isso ocorre
----ate aqui é meu codigo ---------------------------------------

    -- Ready information to front-end.
    -- Control information.
    --esse o_START_SEND_PACKET eu fiz um novo codigo pra ele por isso ele ta em comentario
    --o_START_SEND_PACKET <= '1' when (AWVALID = '1' or ARVALID = '1')    else '0'; -- eu tenho que achar qaundo inicia, que seria quando o ulitimo pacote tinha o tlast=1 e o valid e ready sao 1
    o_VALID_SEND_DATA   <= '1' when (w_OPC_SEND = '0' and TVALID = '1') else '0'; --'1' when (w_OPC_SEND = '0' and TVALID = '1') else '0';
    o_LAST_SEND_DATA    <= '1' when (w_OPC_SEND = '0' and TLAST = '1')  else '0'; -- '1' when (w_OPC_SEND = '0' and TLAST = '1')  else '0';
    o_DATA_SEND         <= TDATA when (w_OPC_SEND = '0' and TVALID = '1') else (others => '0'); --TDATA when (w_OPC_SEND = '0' and TVALID = '1') else (others => '0');


    -- AWREADY <= i_READY_SEND_PACKET; -- coloquei como comentario pq acho que vou ter que apagar n vou usar, i_READY_SEND_PACKET significa que tá no idle
    -- ARREADY <= i_READY_SEND_PACKET; -- coloquei como comentario pq acho que vou ter que apagar n vou usar
    TREADY  <= i_READY_SEND_DATA;  -- é só pra isso que esse ready send data serve mesmo(considerando que o front do AMBA AXI ta assim mesmo), tá no estado de payload antigo WREADY

    ---------------------------------------------------------------------------------------------
    -- Reception.

    --o_READY_RECEIVE_PACKET <= '1' when (i_OPC_RECEIVE = '0' and BREADY = '1') or
                                       (i_OPC_RECEIVE = '1' and RREADY = '1') else '0';

    --o_READY_RECEIVE_DATA   <= RREADY;

    -- Write reception.
    --BVALID <= '1' when (i_OPC_RECEIVE = '0' and i_VALID_RECEIVE_DATA = '1') else '0';
    --BID    <= i_ID_RECEIVE when (i_OPC_RECEIVE = '0' and i_VALID_RECEIVE_DATA = '1') else (c_AXI_ID_WIDTH - 1 downto 0 => '0');
    --BRESP  <= i_STATUS_RECEIVE when (i_OPC_RECEIVE = '0' and i_VALID_RECEIVE_DATA = '1') else (c_AXI_RESP_WIDTH - 1 downto 0 => '0');

    -- Read reception.
    --RVALID <= '1' when (i_OPC_RECEIVE = '1' and i_VALID_RECEIVE_DATA = '1') else '0';
    --RDATA  <= i_DATA_RECEIVE when (i_OPC_RECEIVE = '1' and i_VALID_RECEIVE_DATA = '1') else (c_AXI_DATA_WIDTH - 1 downto 0 => '0');
    --RLAST  <= i_LAST_RECEIVE_DATA;
    --RID    <= i_ID_RECEIVE when (i_OPC_RECEIVE = '1' and i_VALID_RECEIVE_DATA = '1') else (c_AXI_ID_WIDTH - 1 downto 0 => '0');
    --RRESP  <= i_STATUS_RECEIVE when (i_OPC_RECEIVE = '1' and i_VALID_RECEIVE_DATA = '1') else (c_AXI_RESP_WIDTH - 1 downto 0 => '0');

    CORRUPT_PACKET <= i_CORRUPT_RECEIVE;
end rtl;













