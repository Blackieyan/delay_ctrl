----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:57:22 09/27/2014 
-- Design Name: 
-- Module Name:    clock_manage - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity clock_manage is
port(
			sys_clk 	: in  STD_LOGIC;--80MHz p
--			sys_clk_n 	: in  STD_LOGIC;--80MHz n
			sys_rst_in 	: in  STD_LOGIC;--external reset  active low
			ext_clk_I	:	in	std_logic;
			ext_clk_IB	:	in	std_logic;
--			sys_rst_n1	: out    std_logic;--generated reset low active
--			sys_rst_n3	: out    std_logic;--generated reset low active
--			sys_rst_h	: out    std_logic;--generated reset heigh activ
			CLK_OUT1    : out    std_logic;--80MHz
			CLK_OUT2    : out    std_logic;--83.3MHz
			CLK_OUT3    : out    std_logic;--100MHz
			CLK_OUT4    : out    std_logic;--200MHz
			CLK_OUT5    : out    std_logic--500MHz
);
end clock_manage;

architecture Behavioral of clock_manage is

component DCM_SING_IN
port
 (-- Clock in ports
  CLK_IN1          : in     std_logic;
--  CLK_IN1_P          : in     std_logic;
--  CLK_IN1_N          : in     std_logic;
  
  -- Clock out ports
  CLK_OUT1          : out    std_logic;
  CLK_OUT2          : out    std_logic;
  CLK_OUT3          : out    std_logic;
--  CLK_OUT4          : out    std_logic;
--  CLK_OUT5          : out    std_logic;
  -- Status and control signals
  RESET             : in     std_logic;
  LOCKED            : out    std_logic
 );
end component;

--component DCM_OUT_200M
--port
-- (-- Clock in ports
--  CLK_IN1           : in     std_logic;
--  -- Clock out ports
--  CLK_OUT1          : out    std_logic;
--  -- Status and control signals
--  RESET             : in     std_logic;
--  LOCKED            : out    std_logic
-- );
--end component;

signal CLK_IN1_P		:   std_logic;--100MHz internal
signal CLK_IN1_N		:   std_logic;--100MHz internal
--signal sys_rst_h		:   std_logic;--100MHz internal
signal clk1    		:   std_logic;--100MHz internal
signal clk2    		:   std_logic;--100MHz internal
signal clk3    		:   std_logic;--100MHz internal
signal clk4    		:   std_logic;--100MHz internal
signal clk5    		:   std_logic;--100MHz internal
signal sys_rst_master    	:   std_logic;--internal
signal sys_rst_buf    		:   std_logic;--internal
signal sys_rst_high_cnt		: 	 std_logic_vector(15 downto 0) := (others => '0');
signal sys_rst_cnt			: 	 std_logic_vector(3 downto 0);
signal LOCKED_0 				: std_logic;

begin

--  IBUFDS_DIFF_OUT_inst : IBUFGDS_DIFF_OUT
--	generic map (
--		DIFF_TERM => FALSE, -- Differential Termination
--		IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for refernced I/O standards
--		IOSTANDARD => "DEFAULT") -- Specify the input I/O standard
--	port map (
--		O => CLK_IN1_P, -- Buffer diff_p output
--		OB => CLK_IN1_N, -- Buffer diff_n output
--		I => ext_clk_I, -- Diff_p buffer input (connect directly to top-level port)
--		IB => ext_clk_IB -- Diff_n buffer input (connect directly to top-level port)
--	);

  DCM_inst : DCM_SING_IN
  port map
   (-- Clock in ports
    CLK_IN1	        => sys_clk,
--    CLK_IN1_P      	=> ext_clk_I,
--    CLK_IN1_N        => ext_clk_IB,
    -- Clock out ports
    CLK_OUT1           => clk1   ,--456M
    CLK_OUT2           => clk2  ,--76M
    CLK_OUT3           => clk3,--76M
--    CLK_OUT4           => clk4,--250M
--    CLK_OUT5           => clk5,--500M
    -- Status and control signals
    RESET              => '0',
    LOCKED             => open
	 );
	 
	CLK_OUT1	<= clk1;
	CLK_OUT2	<= clk2;
	CLK_OUT3	<= clk3;
	CLK_OUT4	<= '0';
	CLK_OUT5	<= '0';
	
--	sys_rst_h	<= sys_rst_in;
--	process (clk1)
--	begin  
--   if (clk1'event and clk1 = '1') then
--		if(sys_rst_in = '0') then
--			if(sys_rst_high_cnt = x"FFFF") then
--				sys_rst_high_cnt		<= sys_rst_high_cnt;
--			else
--				sys_rst_high_cnt		<= sys_rst_high_cnt + 1;
--			end if;
--		else
--			sys_rst_high_cnt		<= (others => '0');
--		end if;
--   end if;
--	end process;
--	
--	process (sys_rst_high_cnt(15),LOCKED_0)
--	begin  
--   if (LOCKED_0 = '0') then
--		sys_rst_master		<= '1';
--   else
--		if (sys_rst_high_cnt(15) = '1') then
--			sys_rst_master		<= '1';
--		else
--			sys_rst_master		<= '0';
--		end if;
--   end if;
--	end process;
--	
--	process (clk1,sys_rst_master)
--	begin  
--   if sys_rst_master = '1' then
--		sys_rst_cnt		<= (others => '0');
--   elsif (clk1'event and clk1 = '1') then
--		if(sys_rst_cnt = x"F") then
--			sys_rst_cnt		<= sys_rst_cnt;
--		else
--			sys_rst_cnt		<= sys_rst_cnt + 1;
--		end if;
--   end if;
--	end process;
--	
--	process (clk1)
--	begin  
--   if (clk1'event and clk1 = '1') then
--		if(sys_rst_cnt < x"F") then
--			sys_rst_n			<= '0';
--		else
--			sys_rst_n			<= '1';
--		end if;
--   end if;
--	end process;
--	sys_rst_n1	<= sys_rst_n;
--	process (clk3)
--	begin  
--   if (clk3'event and clk3 = '1') then
--		sys_rst_n3		<= sys_rst_n;
--   end if;
--	end process;

end Behavioral;

