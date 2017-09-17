----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:48:22 09/28/2014 
-- Design Name: 
-- Module Name:    OSERDES - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity serial_control is
  generic
    (
      constant IODELAY_GRP : string  := "IODELAY_MIG";  -- May be assigned unique name when
                                        -- multiple IP cores used in design
      BURST_LEN            : integer := 1;              -- Burst Length
      CH_NUM               : integer := 40;
      DATA_WIDTH           : integer := 32              -- Data Width
      );
  port(
    sys_clk_200M : in std_logic;        --reset in active low
    laser_clk : in std_logic;
    cpld_clk : in std_logic;
    sys_rst_n    : in std_logic;        --reset in active low
    trig : in std_logic;
trig_out : out std_logic_vector(CH_NUM-1 downto 0);
    delay_load_num    : in std_logic_vector(5 downto 0);  --load delay value enable
    delay_AM1 : in std_logic_vector(13 downto 0);
    en : in std_logic
    );
end serial_control;

architecture Behavioral of serial_control is

  component serial_unit
    port(
      sys_clk_500M : in  std_logic;
      sys_clk_250M : in  std_logic;
      sys_rst_h    : in  std_logic;
      parallel     : in  std_logic_vector(3 downto 0);
      serial_out   : out std_logic
      );
  end component;

  component delay_unit
    generic(
      IODELAY_GRP : string := "IODELAY_MIG"  -- May be assigned unique name 
                                             -- when mult IP cores in design
      );
    port(
--              sys_clk_500M : IN std_logic;
--              sys_clk_200M : IN std_logic;
      sys_clk_250M : in  std_logic;
      delay_load   : in  std_logic;
      delay_in     : in  std_logic;
      CNTVALUEIN   : in  std_logic_vector(4 downto 0);
      delay_out    : out std_logic;

--              delay_out_n : OUT std_logic;
      CNTVALUEOUT  : out std_logic_vector(4 downto 0)
      );
  end component;
  type array_delay_cnt is array (CH_NUM downto 0) of std_logic_vector(8 downto 0);
  signal delay_cnt : array_delay_cnt;
  signal sync_set_delay_cnt : array_delay_cnt;
  signal set_delay_cnt : array_delay_cnt;
  signal trig_d : std_logic;
  signal delay_load : std_logic_vector(CH_NUM-1 downto 0);
  signal send_en_sync : std_logic;
  signal rd_en        : std_logic;
  signal dout         : std_logic_vector(15 downto 0);
  signal prog_full    : std_logic;
  signal valid        : std_logic;
  signal valid1_d1    : std_logic;
  signal valid1_d2    : std_logic;
  signal empty        : std_logic;

  signal serial_out : std_logic_vector(0 downto 0);
  signal delay_out  : std_logic_vector(CH_NUM-1 downto 0);
  signal delay_in   : std_logic_vector(CH_NUM-1 downto 0);

  signal almost_full : std_logic;
  signal valid2      : std_logic;
  signal wr_en_2     : std_logic;
  signal rd_en2      : std_logic;
  signal dout2       : std_logic_vector(1 downto 0);

  signal iodelay_ctrl_rdy : std_logic;
  signal test_signal_delay_reg : std_logic;
  signal fifo_2_rdy_wr_clk     : std_logic;
  signal fifo_2_rdy_rd_clk     : std_logic;
  signal AM1_clk               : std_logic;
  signal AM2_clk               : std_logic;
  signal serial_AM1            : std_logic;
  signal serial_AM2            : std_logic;
  signal sys_rst_h             : std_logic;
  signal rst_n : std_logic;

  signal send_en_AM_d1    : std_logic;
  signal send_en_80M_d1   : std_logic;
  signal send_en_80M_d2   : std_logic;
  signal send_write_en    : std_logic;
  signal send_write_en_ds : std_logic_vector(7 downto 0);
--signal        send_write_en_d2                        :       std_logic;
--signal        send_write_en_d3                        :       std_logic;

  signal send_write_data : std_logic_vector(127 downto 0);
  signal send_syn_cnt    : std_logic_vector(23 downto 0);

--signal        send_cnt                :       std_logic_VECTOR(1 downto 0);

--signal        serial_in               :       std_logic_VECTOR(1 downto 0);
  type serial_in_regType is array(0 to 0) of std_logic_vector(3 downto 0);
  signal serial_in_reg : serial_in_regType;

  attribute IODELAY_GROUP                    : string;
  attribute IODELAY_GROUP of IDELAYCTRL_inst : label is IODELAY_GRP;
begin
------------------------------------------------------------
------apply IDELAYCTRL, data sheet require This design element 
------must be instantiated when using the IODELAYE1 in virtex 6
------but when using two IODELAYE1, this will be an error occur
------------------------------------------------------------
  IDELAYCTRL_inst : IDELAYCTRL
    port map (
      RDY    => iodelay_ctrl_rdy,
-- 1-bit output indicates validity of the REFCLK
      REFCLK => sys_clk_200M,           -- 1-bit reference clock input
      RST    => sys_rst_h
-- 1-bit reset input
      );

  
  delay_gen : for i in 0 to CH_NUM-1 generate
    Inst_delay_unit : delay_unit
      generic map(
        IODELAY_GRP => IODELAY_GRP
        )
      port map(
--              sys_clk_200M => sys_clk_200M,
        sys_clk_250M => sys_clk_200M,
        delay_load   => delay_load(i),
        delay_in     => delay_in(i),
        delay_out    => trig_out(i),
        CNTVALUEIN   => delay_AM1(4 downto 0),
        CNTVALUEOUT  => open
        );

    decoder_ps : process (cpld_clk, rst_n) is
    begin  -- process decoder_ps
      if rst_n = '0' then                 -- asynchronous reset (active low)
        delay_load(i) <= '0';
      elsif cpld_clk'event and cpld_clk = '1' then  -- rising clock edge
        if delay_load_num = i and en='1' then
          delay_load(i) <= '1';
        else
          delay_load(i) <= '0';
        end if;
      end if;
    end process decoder_ps;

    delay_cnt_ps : process (laser_clk, rst_n) is
    begin  -- process delay_cnt_ps
      if rst_n = '0' then                 -- asynchronous reset (active low)
        delay_cnt(i) <= (others => '0');
      elsif laser_clk'event and laser_clk = '1' then  -- rising clock edge
        if trig = '1' and trig_d = '0' then
          delay_cnt(i) <= (others => '0');
        elsif delay_cnt(i) <= sync_set_delay_cnt(i) then
          delay_cnt(i) <= delay_cnt(i)+1;
        end if;
      end if;
      end process delay_cnt_ps;

      delay_in_ps : process (laser_clk, rst_n) is
    begin  -- process delay_cnt_ps
      if rst_n = '0' then                 -- asynchronous reset (active low)
        delay_in(i) <=  '0';
      elsif laser_clk'event and laser_clk = '1' then  -- rising clock edge
        if delay_cnt(i) = sync_set_delay_cnt(i) then
          delay_in(i) <= '1';
        else
          delay_in(i) <= '0';
        end if;
      end if;
    end process delay_in_ps;
    
      sync_set_delay_cnt_ps: process (laser_clk) is
        begin  -- process sync_set_delay_cnt_ps
          if laser_clk'event and laser_clk = '1' then  -- rising clock edge
            sync_set_delay_cnt(i)<=set_delay_cnt(i);
          end if;
        end process sync_set_delay_cnt_ps;        

        set_delay_cnt_ps: process (cpld_clk, rst_n) is
        begin  -- process set_delay_cnt_ps
          if rst_n = '0' then           -- asynchronous reset (active low)
            set_delay_cnt(i)<=(others => '0');
          elsif cpld_clk'event and cpld_clk = '1' then  -- rising clock edge
            if en='1' then
              if delay_load_num=i then
                set_delay_cnt(i)<=delay_AM1(13 downto 5);
              end if;
            end if;
          end if;
        end process set_delay_cnt_ps;
      end generate;
-------------------------------------------------------------------------------
trig_d_ps: process (laser_clk, rst_n) is
begin  -- process trig_d_ps
  if laser_clk'event and laser_clk = '1' then  -- rising clock edge
    trig_d<=trig;
  end if;
end process trig_d_ps;
      
sys_rst_h <= not sys_rst_n;
rst_n<=sys_rst_n;

      end Behavioral;

