----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:55:15 08/24/2013 
-- Design Name: 
-- Module Name:    CRG - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity CRG is
	generic(
		CRG_Base_Addr : std_logic_vector(7 downto 0) := X"90"
	);
	port(
--		clk_in : in std_logic;
		clk_40M_I : in std_logic;
		clk_40M_IB : in std_logic;
		reset_in_n  : in std_logic;
		---global out-
		sys_clk_80M : out	std_logic;
		sys_clk_dcm : out	std_logic;
		sys_clk_60M : out	std_logic;
		sys_clk_200M : out	std_logic;
		sys_clk_160M : out std_logic;
		sys_clk_160M_inv : out std_logic;
		
--		sys_clk_80M : out	std_logic;
--		sys_clk_200M : out	std_logic;
--		sys_clk_500M : out	std_logic;
--		sys_clk_100M : out std_logic;
--		sys_clk_250M : out std_logic;
		sys_rst_n	:	out	std_logic;--system reset,low active
		-----
		
		---cpldif interface--
		cpldif_crg_addr	:	in	std_logic_vector(7 downto 0);
		cpldif_crg_wr_en	:	in	std_logic;--register write enable
		cpldif_crg_wr_data	:	in	std_logic_vector(31 downto 0);
		cpldif_crg_rd_en	:	in	std_logic;--refister read enable
		crg_cpldif_rd_data	:	out	std_logic_vector(31 downto 0)
	);
end CRG;

architecture Behavioral of CRG is

signal crg_ctrl_reg : std_logic_vector(31 downto 0);
signal soft_rst_n	:	std_logic;
signal sys_clk	:	std_logic;
signal clk_40M_p	:	std_logic;
signal clk_40M_n	:	std_logic;

signal syn_rst_1d_n	:	std_logic;
signal syn_rst_2d_n	:	std_logic;
signal syn_rst_3d_n	:	std_logic;
signal syn_rst_4d_n	:	std_logic;
signal rd_data_reg	:	std_logic_vector(31 downto 0);

component CLK_DCM
port
 (-- Clock in ports
  CLK_IN1        : in     std_logic;
--  CLK_IN1_N        : in     std_logic;
  -- Clock out ports
  CLK_OUT1          : out    std_logic;
  CLK_OUT2          : out    std_logic;
  CLK_OUT3          : out    std_logic;
  CLK_OUT4          : out    std_logic;
--  CLK_OUT5          : out    std_logic;
--  CLK_OUT6          : out    std_logic;
  -- Status and control signals
  RESET             : in     std_logic
 );
end component;

begin

--***** synchronous release of reset **
rst_release : process(sys_clk,soft_rst_n,reset_in_n)
begin
	if(soft_rst_n = '0' or reset_in_n = '0') then
		syn_rst_1d_n	<=	'0';
		syn_rst_2d_n	<=	'0';
		syn_rst_3d_n	<=	'0';
		syn_rst_4d_n	<=	'0';
	elsif rising_edge(sys_clk) then
		syn_rst_1d_n	<=	'1';
		syn_rst_2d_n	<=	syn_rst_1d_n;
		syn_rst_3d_n	<=	syn_rst_2d_n;
		syn_rst_4d_n	<=	syn_rst_3d_n;
	end if;
end process;

--BUFG_inst : BUFG
--port map (
--O => sys_rst_n, -- 1-bit output: Clock buffer output
--I => syn_rst_2d_n -- 1-bit input: Clock buffer input
--);
sys_rst_n <= syn_rst_4d_n;

-- End of BUFG_inst instantiation
--**** end **********

IBUFDS_DIFF_OUT_inst : IBUFGDS_DIFF_OUT
generic map (
DIFF_TERM => FALSE, -- Differential Termination
IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
IOSTANDARD => "DEFAULT") -- Specify the input I/O standard
port map (
O => clk_40M_p, -- Buffer diff_p output
OB => clk_40M_n, -- Buffer diff_n output
I => clk_40M_I, -- Diff_p buffer input (connect directly to top-level port)
IB => clk_40M_IB -- Diff_n buffer input (connect directly to top-level port)
);

--sys_clk_100M <= clk_40M_p;
inst_dcm : CLK_DCM
  port map
   (-- Clock in ports
    CLK_IN1 => clk_40M_p,--clk_in
--    CLK_IN1_N => clk_40M_IB,--clk_in
    -- Clock out ports
    CLK_OUT1 => sys_clk,
    CLK_OUT2 => sys_clk_160M,
    CLK_OUT3 => sys_clk_160M_inv,
    CLK_OUT4 => sys_clk_200M,
--    CLK_OUT5 => sys_clk_10M,
--    CLK_OUT6 => sys_clk_dcm,
	 
    -- Status and control signals
    RESET  => '0');
-- INST_TAG_END ------ End INSTANTIATION Template ------------	
sys_clk_80M <= sys_clk;
sys_clk_60m <= '0';
--sys_clk_10M <= '0';
---**********   register manage  *******
---write register
reg_wr : process(sys_clk)
begin
	if rising_edge(sys_clk) then
		if(syn_rst_2d_n = '0') then
			crg_ctrl_reg	<=	(others => '1');
		elsif(soft_rst_n = '0') then--rwsc
				crg_ctrl_reg(0) <=	'1';
		elsif(cpldif_crg_addr = CRG_Base_Addr) then
			if(cpldif_crg_wr_en = '1') then
				crg_ctrl_reg	<=	cpldif_crg_wr_data;			
			else
				crg_ctrl_reg	<=	crg_ctrl_reg;
			end if;
		else
			crg_ctrl_reg	<=	crg_ctrl_reg;
		end if;
	end if;
end process;
---read register
reg_rd : process(sys_clk)
begin
	if rising_edge(sys_clk) then
		if(cpldif_crg_rd_en = '1') then
			if(cpldif_crg_addr = CRG_Base_Addr) then
				rd_data_reg	<=	crg_ctrl_reg;
			else
				rd_data_reg	<=	rd_data_reg;
			end if;
		else
			rd_data_reg	<=	rd_data_reg;
		end if;
	end if;
end process;

crg_cpldif_rd_data	<= 	rd_data_reg;
---******* end *********

--cpldif_burst_len	<=	crg_ctrl_reg(10 downto 0);
soft_rst_n	<=	crg_ctrl_reg(0);

end Behavioral;

