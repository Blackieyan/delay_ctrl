----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:28:20 10/27/2014 
-- Design Name: 
-- Module Name:    dps_reg_resolve - Behavioral 
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
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dps_reg_resolve is
  generic(
    DPS_Base_Addr : std_logic_vector(7 downto 0) := X"A0";
    DPS_High_Addr : std_logic_vector(7 downto 0) := X"AF"
    );
  port(
    -- fix by herry make sys_clk_80M to sys_clk_160M
    sys_clk_80M : in std_logic;         --system clock,80MHz
    sys_rst_n   : in std_logic;         --system reset,low active

    delay_load_num          : buffer std_logic_vector(5 downto 0);

    delay_AM1           : out std_logic_vector(13 downto 0);

    cpldif_dps_addr    : in  std_logic_vector(7 downto 0);
    cpldif_dps_wr_en   : in  std_logic;
    cpldif_dps_rd_en   : in  std_logic;
    cpldif_dps_wr_data : in  std_logic_vector(31 downto 0);
    dps_cpldif_rd_data : out std_logic_vector(31 downto 0);
    en : out std_logic
    );
end dps_reg_resolve;

architecture Behavioral of dps_reg_resolve is
signal apd_fpga_hit : std_logic_vector(15 downto 0);
signal apd_fpga_hit_1d : std_logic_vector(15 downto 0);
signal apd_fpga_hit_2d : std_logic_vector(15 downto 0);
signal hit_cnt_en     :       std_logic_vector(15 downto 0);

  signal rd_data_reg         : std_logic_vector(31 downto 0);
  signal addr_sel            : std_logic_vector(7 downto 0);
  signal dps_round_cnt_reg   : std_logic_vector(15 downto 0);
  signal DPS_syn_dly_cnt_reg : std_logic_vector(11 downto 0);
  signal DPS_chopper_cnt_reg : std_logic_vector(3 downto 0);
  signal delay_am1_reg       : std_logic_vector(13 downto 0);

  signal DPS_send_PM_dly_cnt_reg : std_logic_vector(7 downto 0);
  signal DPS_send_AM_dly_cnt_reg : std_logic_vector(7 downto 0);
  signal GPS_period_cnt_reg      : std_logic_vector(31 downto 0);
  signal rnd_ctrl_reg            : std_logic_vector(31 downto 0);

  signal set_send_disable_cnt_reg    : std_logic_vector(31 downto 0);  --for Alice
  signal set_send_enable_cnt_reg     : std_logic_vector(31 downto 0);  --for Alice
  signal set_chopper_enable_cnt_reg  : std_logic_vector(31 downto 0);  --for Bob
  signal set_chopper_disable_cnt_reg : std_logic_vector(31 downto 0);  --for Bob

  signal lut_wr_reg : std_logic_vector(31 downto 0);  --for Bob
signal cpldif_dps_wr_en_d : std_logic;
signal delay_am2_reg                  : std_logic_vector(4 downto 0);
signal delay_pm_reg                   : std_logic_vector(4 downto 0);
signal exp_run_start          : std_logic;
signal exp_run_stop                   : std_logic;

signal cpldif_dps_wr_en_d1    : std_logic;


begin


-- ****** register manager ***
  lock_addr : process(sys_clk_80M, sys_rst_n)
  begin
    if(sys_rst_n = '0') then
      addr_sel <= X"FF";
    elsif rising_edge(sys_clk_80M) then
      if(cpldif_dps_addr >= DPS_Base_Addr and cpldif_dps_addr <= DPS_High_Addr) then
        addr_sel <= cpldif_dps_addr - DPS_Base_Addr;
      else
        addr_sel <= X"FF";
      end if;
    end if;
  end process;
  
process(sys_clk_80M,sys_rst_n)
begin
	if(sys_rst_n = '0') then
          delay_AM1_reg			<=	(others => '0');--default pm is 0110
          delay_load_num <=(others => '0');
	elsif rising_edge(sys_clk_80M) then
		if(addr_sel = x"02"  and cpldif_dps_wr_en = '1') then--DPS_round_cnt REG
                  delay_AM1_reg(4 downto 0)	<= cpldif_dps_wr_data(4 downto 0);
                  delay_AM1_reg(13 downto 5)	<= cpldif_dps_wr_data(16 downto 8);
                    delay_load_num	       	<= cpldif_dps_wr_data(29 downto 24);
		end if;
	end if;
end process;
delay_AM1	<= delay_AM1_reg;

process (sys_clk_80M, sys_rst_n) is
begin  -- process
  if sys_rst_n = '0' then               -- asynchronous reset (active low)
    cpldif_dps_wr_en_d<='0';
  elsif sys_clk_80M'event and sys_clk_80M = '1' then  -- rising clock edge
    cpldif_dps_wr_en_d<=cpldif_dps_wr_en;
  end if;
end process;

process (sys_clk_80M, sys_rst_n) is
begin  -- process
  if sys_rst_n = '0' then               -- asynchronous reset (active low)
    en<='0';
  elsif sys_clk_80M'event and sys_clk_80M = '1' then  -- rising clock edge
    if cpldif_dps_wr_en_d='0' and cpldif_dps_wr_en ='1' then
      en<='1';
    else
      en<='0';
    end if;
  end if;
end process;

-- process(sys_clk_80M,sys_rst_n)
-- begin
-- 	if(sys_rst_n = '0') then
-- 		delay_load_num				<= (others => '0');
-- 	elsif rising_edge(sys_clk_80M) then
--           if(addr_sel = x"03"  and cpldif_dps_wr_en = '1') then--DPS_round_cnt REG
--             delay_load_num			<= cpldif_dps_wr_data(5 downto 0); --
--             -- max 64 channels
--           else
--             delay_load_num			<=  (others => '0');
--           end if;
-- 	end if;
-- end process;



  read_ram : process(sys_clk_80M, sys_rst_n)
  begin
    if(sys_rst_n = '0') then
      rd_data_reg <= (others => '0');
    else
      if rising_edge(sys_clk_80M) then
        if(cpldif_dps_rd_en = '1') then
          case addr_sel is
            when X"00"  => rd_data_reg <= x"12345678";
            -- when X"01"  => rd_data_reg <= DPS_syn_dly_cnt_reg & DPS_chopper_cnt_reg & DPS_round_cnt_reg;  --read count of channel 0
            when X"02"  => rd_data_reg <= "00"&delay_load_num&"0000000"&delay_AM1_reg(13 downto 5)&"000"&delay_AM1_reg(4 downto 0);
--             when X"03"  => rd_data_reg <= GPS_period_cnt_reg;
--             when X"04"  => rd_data_reg <= X"DaDa" & DPS_send_AM_dly_cnt_reg & DPS_send_PM_dly_cnt_reg;  --read count of channel 1
--             when X"05"  => rd_data_reg <= set_send_enable_cnt_reg;  --read count of channel 1
--             when X"06"  => rd_data_reg <= set_send_disable_cnt_reg;  --read count of channel 1
--             when X"07"  => rd_data_reg <= set_chopper_enable_cnt_reg;  --read count of channel 1
--             when X"08"  => rd_data_reg <= set_chopper_disable_cnt_reg;  --read count of channel 1
--             when X"09"  => rd_data_reg <= lut_wr_reg;  --read count of channel 1
-- --                              when others     =>      rd_data_reg     <=      x"5A" & "000" & delay_AM1_out & "000" & delay_AM2_out & "000" & delay_PM_out;
            when others => rd_data_reg <= (others => '0');
          end case;
        end if;
      end if;
    end if;
  end process;
--**** end ********


  dps_cpldif_rd_data <= rd_data_reg;



end Behavioral;

