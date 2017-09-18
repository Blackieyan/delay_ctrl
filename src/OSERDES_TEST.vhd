----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:52:04 08/05/2014 
-- Design Name: 
-- Module Name:    OSERDES_TEST - Behavioral 
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
-- error help: http://www.xilinx.com/support/answers/43559.html
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity DPS_QKD is
  generic(
    DATA_WIDTH    : integer                      := 32;  -- Data Width
    BURST_LEN     : integer                      := 1;  -- Burst Length
    RND_CHIP_NUM  : integer                      := 4;  -- No. of random chip wng-x           
    DPS_Base_Addr : std_logic_vector(7 downto 0) := X"A0";
    DPS_High_Addr : std_logic_vector(7 downto 0) := X"AF";
        CH_NUM     : integer := 40
    );
  port (
    laser_clk   : in std_logic;         --76MHz
    sys_clk     : in std_logic;         --80MHz
    sys_clk_200M : in std_logic;         --200MHz
    ext_clk_I   : in std_logic;         --don't use
    ext_clk_IB  : in std_logic;
    sys_rst_n   : in std_logic;

    trig_out:out std_logic_vector(CH_NUM-1 downto 0);

    ------------inside interface to cpldif module--------------------------
    cpldif_dps_addr    : in  std_logic_vector(7 downto 0);
    cpldif_dps_wr_en   : in  std_logic;  --register write enable
    cpldif_dps_wr_data : in  std_logic_vector(31 downto 0);
    cpldif_dps_rd_en   : in  std_logic;  --refister read enable
    dps_cpldif_rd_data : out std_logic_vector(31 downto 0)


    );
end DPS_QKD;

architecture Behavioral of DPS_QKD is

  component clock_manage
    port(
      sys_clk    : in  std_logic;
      ext_clk_I  : in  std_logic;
      ext_clk_IB : in  std_logic;
      sys_rst_in : in  std_logic;
      CLK_OUT1   : out std_logic;
      CLK_OUT2   : out std_logic;
      CLK_OUT3   : out std_logic;
      CLK_OUT4   : out std_logic;
      CLK_OUT5   : out std_logic
      );
  end component;

  component serial_control
    generic
      (
        BURST_LEN  : integer := 1;      -- Burst Length
        DATA_WIDTH : integer := 32;     -- Data Width
        CH_NUM     : integer := 40
        );
    port(
      sys_clk_200M   : in std_logic;    --reset in active low
      laser_clk      : in std_logic;
      cpld_clk       : in std_logic;
      sys_rst_n      : in std_logic;    --reset in active low
      fifo_clr       : in std_logic;    --reset in
      delay_load_num : in std_logic_vector(5 downto 0);  --load delay value enable
      delay_AM1      : in std_logic_vector(13 downto 0);
      trig           : in std_logic;
      trig_out       : out std_logic_vector(CH_NUM-1 downto 0);
      en             : in std_logic
      );
  end component;

 component dps_reg_resolve is
  generic (
    DPS_Base_Addr : std_logic_vector(7 downto 0);
    DPS_High_Addr : std_logic_vector(7 downto 0));
  port (
    sys_clk_80M        : in  std_logic;
    sys_rst_n          : in  std_logic;
    delay_load_num     : out std_logic_vector(5 downto 0);
    delay_AM1          : out std_logic_vector(13 downto 0);
    set_trig_cnt : buffer std_logic_vector(7 downto 0);
    cpldif_dps_addr    : in  std_logic_vector(7 downto 0);
    cpldif_dps_wr_en   : in  std_logic;
    cpldif_dps_rd_en   : in  std_logic;
    cpldif_dps_wr_data : in  std_logic_vector(31 downto 0);
    dps_cpldif_rd_data : out std_logic_vector(31 downto 0);
    en                 : out std_logic);
end component dps_reg_resolve;

  -- COMP_TAG_END ------ End COMPONENT Declaration ------------
signal trig : std_logic;
  signal en               : std_logic;

signal laser_clk_mult : std_logic;
signal laser_clk_out : std_logic;
signal delay_AM1 : std_logic_vector(13 downto 0);
signal delay_load_num : std_logic_vector(5 downto 0);

signal trig_cnt : std_logic_vector(19 downto 0);
signal set_trig_cnt : std_logic_vector(7 downto 0);
begin


  Inst_clock_manage : clock_manage port map(
    sys_clk    => laser_clk,              --80M
    ext_clk_I  => ext_clk_I,
    ext_clk_IB => ext_clk_IB,
    sys_rst_in => sys_rst_n,
--              sys_rst_n1 => sys_rst_n1,
--              sys_rst_n3 => sys_rst_n3,
--              sys_rst_h => open,
    CLK_OUT1   => laser_clk_mult,       --456M
    CLK_OUT2   => open,         --sys_clk_100M,
    CLK_OUT3   => laser_clk_out,        --76M
    CLK_OUT4   => open,
    CLK_OUT5   => open
    );

  serial_control_1 : entity work.serial_control
    generic map (
      BURST_LEN  => BURST_LEN,
      DATA_WIDTH => DATA_WIDTH,
      CH_NUM     => CH_NUM)
    port map (
      sys_clk_200M   => sys_clk_200M,
      laser_clk      => laser_clk_mult,
      cpld_clk       => sys_clk,
      sys_rst_n      => sys_rst_n,
      delay_load_num => delay_load_num,  --config addr
      delay_AM1      => delay_AM1,      --config data
      trig           => trig,
      en             => en,             --config enable
      trig_out       => trig_out
      );

dps_reg_resolve_1: entity work.dps_reg_resolve
  generic map (
    DPS_Base_Addr => DPS_Base_Addr,
    DPS_High_Addr => DPS_High_Addr)
  port map (
    sys_clk_80M        => sys_clk,
    sys_rst_n          => sys_rst_n,
    delay_load_num     => delay_load_num,
    delay_AM1          => delay_AM1,
    set_trig_cnt =>set_trig_cnt,
    cpldif_dps_addr    => cpldif_dps_addr,
    cpldif_dps_wr_en   => cpldif_dps_wr_en,
    cpldif_dps_rd_en   => cpldif_dps_rd_en,
    cpldif_dps_wr_data => cpldif_dps_wr_data,
    dps_cpldif_rd_data => dps_cpldif_rd_data,
    en                 => en);

  -- purpose: <[description]>
  trig_gen_ps: process (laser_clk_out) is
  begin  -- process trig_gen_ps
    if laser_clk_out'event and laser_clk_out = '1' then  -- rising clock edge
      if(trig_cnt < set_trig_cnt) then
        trig_cnt <= trig_cnt + '1';
        trig <= '0';
      else
        trig_cnt <= (others => '0');
        trig     <= '1';
      end if;
    end if;
  end process trig_gen_ps;
end Behavioral;

