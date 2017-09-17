----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:18:27 08/05/2013 
-- Design Name: 
-- Module Name:    cpld_if - Behavioral 
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
Library UNISIM;
use UNISIM.vcomponents.all;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cpld_if is
	generic(
		DAC_Base_Addr : std_logic_vector(7 downto 0)  := X"40";
		DAC_High_Addr : std_logic_vector(7 downto 0)  := X"43";
		CNT_Base_Addr : std_logic_vector(7 downto 0)  := X"50";
		CNT_High_Addr : std_logic_vector(7 downto 0)  := X"71";
		CPLD_Base_Addr : std_logic_vector(7 downto 0) := X"80";
		CRG_Base_Addr : std_logic_vector(7 downto 0)  := X"90";
		TDC_Base_Addr : std_logic_vector(7 downto 0)  := X"10";
		TDC_High_Addr : std_logic_vector(7 downto 0)  := X"14";
		TIME_Base_Addr : std_logic_vector(7 downto 0) := X"20";
		TIME_High_Addr : std_logic_vector(7 downto 0) := X"23";
		Qtel_Base_Addr : std_logic_vector(7 downto 0) := X"7B";
		Qtel_High_Addr : std_logic_vector(7 downto 0) := X"7D";
		SERIAL_base_addr	:	std_logic_vector(7 downto 0) := X"A0";------------
		SERIAL_high_addr	:	std_logic_vector(7 downto 0) := X"AF"-------------
	);
	port(
		sys_clk_80M	:	in	std_logic;--system clock,80MHz
		sys_rst_n	:	in	std_logic;--system reset,high active;
		----cpld interface------
		cpld_fpga_clk		:	in	std_logic;--33MHz clock from cpld
		cpld_fpga_data		:	inout	std_logic_vector(31 downto 0);
		cpld_fpga_addr		:	in	std_logic_vector(7 downto 0);
		cpld_fpga_sglrd		:	in	std_logic;--single read enable,high active
		cpld_fpga_sglwr		:	in	std_logic;--single write enable,high active
		cpld_fpga_brtrd_req	:	in	std_logic;--burst read request,high active
		fpga_cpld_burst_act	:	out	std_logic;
		fpga_cpld_burst_en	:	out	std_logic;--burst enable,indicate fifo has stored a burst length
		-----register interface----
		dac_cpldif_rd_data 	 	: 	in	std_logic_vector(31 downto 0);
		count_cpldif_rd_data 	: 	in	std_logic_vector(31 downto 0);
		crg_cpldif_rd_data 	 	: 	in	std_logic_vector(31 downto 0);
		sysmon_cpldif_rd_data 	: 	in	std_logic_vector(31 downto 0);
		tdc_cpldif_rd_data 	 	: 	in	std_logic_vector(31 downto 0);
		time_cpldif_rd_data 		: 	in	std_logic_vector(31 downto 0);
		qtel_cpldif_rd_data 		:  in	std_logic_vector(31 downto 0);
		dps_cpldif_rd_data 		:  in	std_logic_vector(31 downto 0);
		cpldif_addr				:	out	std_logic_vector(7 downto 0);
		cpldif_rd_en			:	out	std_logic;
		cpldif_wr_en			:	out	std_logic;
		cpldif_wr_data			:	out	std_logic_vector(31 downto 0);
		-------fifo interface-------
		tdc_cpldif_fifo_wr_en		:	in	std_logic;
		tdc_cpldif_fifo_clr			:	in	std_logic;
		tdc_cpldif_fifo_wr_data		:	in	std_logic_vector(31 downto 0);
		cpldif_tdc_fifo_almost_full	:	out	std_logic;
		cpldif_tdc_fifo_prog_full	:	out	std_logic;
		cpldif_tdc_fifo_full		:	out	std_logic
	);
end cpld_if;

architecture Behavioral of cpld_if is

COMPONENT TDC_CPLD_FIFO
	PORT(
		din : IN std_logic_vector(31 downto 0);
		rd_clk : IN std_logic;
		rd_en : IN std_logic;
		rst : IN std_logic;
		wr_clk : IN std_logic;
		wr_en : IN std_logic;          
		dout : OUT std_logic_vector(31 downto 0);
		empty : OUT std_logic;
		full : OUT std_logic;
		almost_full : OUT STD_LOGIC;
		prog_full : OUT std_logic;
		valid : OUT std_logic;
		rd_data_count : OUT std_logic_vector(11 downto 0)
		);
	END COMPONENT;
	

signal cpld_fpga_dio_i	:	std_logic_vector(31 downto 0);
signal cpld_fpga_dio_o	:	std_logic_vector(31 downto 0);
signal cpld_fpga_dio_t	:	std_logic;
-----synchronized signal-------
signal cpld_fpga_addr_1d	:	std_logic_vector(7 downto 0);
signal cpld_fpga_addr_2d	:	std_logic_vector(7 downto 0);
signal cpld_fpga_sglrd_1d	:	std_logic;
signal cpld_fpga_sglrd_2d	:	std_logic;
signal cpld_fpga_sglrd_3d	:	std_logic;
signal cpld_fpga_sglwr_1d	:	std_logic;
signal cpld_fpga_sglwr_2d	:	std_logic;
signal cpld_fpga_sglwr_3d	:	std_logic;
--signal cpld_fpga_brtrd_req_1d	:	std_logic;
signal cpld_fpga_sglrd_req		:	std_logic;--read enbale,one clock width
signal cpld_fpga_sglwr_req		:	std_logic;--write enbale,one clock width
signal cpld_fpga_brtrd_req_1d	:	std_logic;
signal cpld_fpga_data_i_1d		:	std_logic_vector(31 downto 0);
signal cpld_fpga_data_i_2d		:	std_logic_vector(31 downto 0);
----------------
signal fifo_data_valid	:	std_logic;
signal cpld_fpga_clk_bufg	:	std_logic;

signal fifo_rd_data	:	std_logic_vector(31 downto 0);
signal sglrd_cnt	:	std_logic_vector(2 downto 0);
signal dio_t_sglrd	:	std_logic;
signal dio_t_burst	:	std_logic;
constant sglrd_length	:	std_logic_vector(2 downto 0) := "111";
signal fifo_rst	:	std_logic;
signal fifo_rd_data_count : std_logic_vector(11 downto 0);
---cpldif register
signal cpld_burst_length : std_logic_vector(11 downto 0);

begin


   BUFG_inst : BUFG
   port map (
      O =>cpld_fpga_clk_bufg, -- 1-bit output: Clock buffer output
      I => cpld_fpga_clk  -- 1-bit input: Clock buffer input
   );

IO_gen : for i in 0 to 31 generate
IOBUF_inst : IOBUF
generic map (
DRIVE => 12,
IBUF_DELAY_VALUE => "0", -- Specify the amount of added input delay for buffer, "0"-"16" (Spartan-3E/3A only)
IFD_DELAY_VALUE => "AUTO", -- Specify the amount of added delay for input register, "AUTO", "0"-"8" (Spartan-3E/3A only)
IOSTANDARD => "DEFAULT",
SLEW => "SLOW")
port map (
O => cpld_fpga_dio_i(i), -- Buffer output
IO => cpld_fpga_data(i), -- Buffer inout port (connect directly to top-level port)
I => cpld_fpga_dio_o(i), -- Buffer input
T => cpld_fpga_dio_t -- 3-state enable input
);
end generate;

--************sync process**********
----address synchronization----
sync_addr_pro : process(sys_clk_80M)
begin
	if rising_edge(sys_clk_80M) then
		cpld_fpga_addr_1d	<=	cpld_fpga_addr;
--		cpld_fpga_addr_2d	<=	cpld_fpga_addr_1d;
	end if;
end process;
----single read synchronization---
sync_rd_pro : process(sys_clk_80M,sys_rst_n)
begin
	if(sys_rst_n = '0') then
		cpld_fpga_sglrd_1d	<=	'0';
		cpld_fpga_sglrd_2d	<=	'0';
		cpld_fpga_sglrd_3d	<=	'0';
	elsif rising_edge(sys_clk_80M) then
		cpld_fpga_sglrd_1d	<=	cpld_fpga_sglrd;
		cpld_fpga_sglrd_2d	<=	cpld_fpga_sglrd_1d;
		cpld_fpga_sglrd_3d	<=	cpld_fpga_sglrd_2d;
	end if;
end process;
----single write synchronization---
sync_wr_pro : process(sys_clk_80M,sys_rst_n)
begin
	if(sys_rst_n = '0') then
		cpld_fpga_sglwr_1d	<=	'0';
		cpld_fpga_sglwr_2d	<=	'0';
		cpld_fpga_sglwr_3d	<=	'0';
	elsif rising_edge(sys_clk_80M) then
		cpld_fpga_sglwr_1d	<=	cpld_fpga_sglwr;
		cpld_fpga_sglwr_2d	<=	cpld_fpga_sglwr_1d;
		cpld_fpga_sglwr_3d	<=	cpld_fpga_sglwr_2d;
	end if;
end process;
----write data synchrinization----
sync_data_pro : process(sys_clk_80M)
begin
	if rising_edge(sys_clk_80M) then
		cpld_fpga_data_i_1d	<=	cpld_fpga_dio_i;
--		cpld_fpga_data_i_2d	<=	cpld_fpga_data_i_1d;
	end if;
end process;
---*************************************

---****************************
---generate read enable,one clock width
rd_en_pro : process(sys_clk_80M)
begin
	if rising_edge(sys_clk_80M) then
		cpld_fpga_sglrd_req	<=	cpld_fpga_sglrd_2d	and (not cpld_fpga_sglrd_3d);
	end if;
end process;
---generate write enable,one clock width
wr_en_pro : process(sys_clk_80M)
begin
	if rising_edge(sys_clk_80M) then
		cpld_fpga_sglwr_req	<=	cpld_fpga_sglwr_2d	and (not cpld_fpga_sglwr_3d);
	end if;
end process;
---***************************************

---**** cpld burst read length ***
--write burst length
wr_len : process(sys_clk_80M,sys_rst_n)
begin
	if(sys_rst_n = '0') then
		cpld_burst_length	<=	(others => '0');
	elsif rising_edge(sys_clk_80M) then		
		if(cpld_fpga_sglwr_req = '1') then
			if(cpld_fpga_addr_1d = CPLD_Base_Addr) then
				cpld_burst_length	<=	cpld_fpga_data_i_1d(11 downto 0);
			else
				cpld_burst_length	<=	cpld_burst_length;
			end if;
		else
			cpld_burst_length	<=	cpld_burst_length;
		end if;
	end if;
end process;
---indicate fifo has restore more than a burst length
brt_len : process(sys_clk_80M,sys_rst_n) 
begin
	if(sys_rst_n = '0') then
		fpga_cpld_burst_en	<=	'0';
	elsif rising_edge(sys_clk_80M) then		
		if(fifo_rd_data_count >= cpld_burst_length + 64) then
			fpga_cpld_burst_en	<=	'1';
		else
			fpga_cpld_burst_en	<=	'0';
		end if;
	end if;
end process;
---********* end ************

-----************generate three state enable signal***----------
---single read output length--
len_cnt : process(sys_clk_80M,sys_rst_n)
begin
	if(sys_rst_n = '0') then
		sglrd_cnt	<=	sglrd_length;
	elsif rising_edge(sys_clk_80M) then
		if(cpld_fpga_sglrd_req = '1') then
			sglrd_cnt	<=	"000";
		else
			if(sglrd_cnt = sglrd_length) then
				sglrd_cnt	<=	sglrd_cnt;
			else
				sglrd_cnt	<=	sglrd_cnt + '1';
			end if;
		end if;
	end if;
end process;
---single read IO enable--
dio_t_sgl : process(sglrd_cnt)
begin
	if(sglrd_cnt >= X"00" and sglrd_cnt < sglrd_length) then---0 to 15
		dio_t_sglrd	<=	'0';
	else
		dio_t_sglrd	<=	'1';
	end if;
end process;
---one clock delay of cpld_fpga_brtrd_req
btrrd_req_1d : process(cpld_fpga_clk_bufg,sys_rst_n) begin
	if(sys_rst_n = '0') then
		cpld_fpga_brtrd_req_1d	<=	'0';
	elsif rising_edge(cpld_fpga_clk_bufg) then
		cpld_fpga_brtrd_req_1d	<=	cpld_fpga_brtrd_req;
	end if;
end process;
-----burst read IO enable---
dio_t_brt : process(cpld_fpga_clk_bufg,sys_rst_n) begin
	if(sys_rst_n = '0') then
		dio_t_burst	<=	'1';
	elsif rising_edge(cpld_fpga_clk_bufg) then
		if(cpld_fpga_brtrd_req = '1') then
			dio_t_burst	<=	'0';
		elsif(cpld_fpga_brtrd_req_1d = '0' and cpld_fpga_brtrd_req = '0') then
			dio_t_burst	<=	'1';
		else
			dio_t_burst	<=	dio_t_burst;
		end if;
	end if;
end process;
-----*****************************************************-

---select single read,burst read or register output
data_sel : process(cpld_fpga_clk_bufg,sys_rst_n)
begin
	if(sys_rst_n = '0') then
		cpld_fpga_dio_o <= (others => '0');
	elsif rising_edge(cpld_fpga_clk_bufg) then
		if(cpld_fpga_brtrd_req = '1' or cpld_fpga_brtrd_req = '1' ) then --burst read output
			cpld_fpga_dio_o	<=	fifo_rd_data;
		else							--single read output
			if(cpld_fpga_addr_1d >= SERIAL_Base_addr and cpld_fpga_addr_1d <= SERIAL_high_addr) then
				cpld_fpga_dio_o	<=	dps_cpldif_rd_data;
			elsif(cpld_fpga_addr_1d >= DAC_Base_Addr and cpld_fpga_addr_1d <= DAC_High_Addr) then
				cpld_fpga_dio_o	<=	dac_cpldif_rd_data;
			elsif(cpld_fpga_addr_1d >= CNT_Base_Addr and cpld_fpga_addr_1d <= CNT_High_Addr) then
				cpld_fpga_dio_o	<=	count_cpldif_rd_data;
			elsif(cpld_fpga_addr_1d = CRG_Base_Addr) then
				cpld_fpga_dio_o	<=	crg_cpldif_rd_data;
			elsif(cpld_fpga_addr_1d(7 downto 4) = x"3") then
				cpld_fpga_dio_o	<=	sysmon_cpldif_rd_data;
			elsif(cpld_fpga_addr_1d >= TDC_Base_Addr and cpld_fpga_addr_1d <= TDC_High_Addr) then
				cpld_fpga_dio_o	<=	tdc_cpldif_rd_data;
			elsif(cpld_fpga_addr_1d >= TIME_Base_Addr and cpld_fpga_addr_1d <= TIME_High_Addr) then
				cpld_fpga_dio_o	<=	time_cpldif_rd_data;	
			elsif(cpld_fpga_addr_1d >= Qtel_Base_Addr and cpld_fpga_addr_1d <= Qtel_High_Addr) then
				cpld_fpga_dio_o	<=qtel_cpldif_rd_data;		
			else
				cpld_fpga_dio_o	<=	cpld_fpga_dio_o;
			end if;
		end if;
	end if;
end process;

cpldif_rd_en	<=	cpld_fpga_sglrd_req;
cpldif_wr_en	<=	cpld_fpga_sglwr_req;
cpld_fpga_dio_t	<=	dio_t_burst and dio_t_sglrd;--IO three state enable
cpldif_wr_data	<=	cpld_fpga_data_i_1d;
cpldif_addr		<=	cpld_fpga_addr_1d;
----------
fifo_rst	<=	(not sys_rst_n) or tdc_cpldif_fifo_clr;---fifo reset:high active
fpga_cpld_burst_act <= fifo_data_valid;

Inst_TDC_CPLD_FIFO: TDC_CPLD_FIFO PORT MAP(
		din => tdc_cpldif_fifo_wr_data,
		rd_clk => cpld_fpga_clk_bufg,
		rd_en => cpld_fpga_brtrd_req,
		rst => fifo_rst,
		wr_clk => sys_clk_80M,
		wr_en => tdc_cpldif_fifo_wr_en,
		dout => fifo_rd_data,
		empty => open,
		full => cpldif_tdc_fifo_full,
		almost_full =>	cpldif_tdc_fifo_almost_full,
		prog_full => cpldif_tdc_fifo_prog_full,
		valid => fifo_data_valid,
		rd_data_count => fifo_rd_data_count
	);
	

end Behavioral;

