----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:37:00 08/12/2013 
-- Design Name: 
-- Module Name:    ground_pro_top - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;


entity ground_pro_top is
	generic(
		DAC_Base_Addr : std_logic_vector(7 downto 0) := X"40";
		DAC_High_Addr : std_logic_vector(7 downto 0) := X"43";
		CNT_Base_Addr : std_logic_vector(7 downto 0) := X"50";
		CNT_High_Addr : std_logic_vector(7 downto 0) := X"71";
		CPLD_Base_Addr : std_logic_vector(7 downto 0):=X"80";
		CRG_Base_Addr : std_logic_vector(7 downto 0):=X"90";
		TDC_Base_Addr : std_logic_vector(7 downto 0) := X"10";
		TDC_High_Addr : std_logic_vector(7 downto 0) := X"14";
		TIME_Base_Addr : std_logic_vector(7 downto 0) := X"20";
		TIME_High_Addr : std_logic_vector(7 downto 0) := X"23";
		QTEL_base_addr	:	std_logic_vector(7 downto 0) := X"7B";
		QTEL_high_addr	:	std_logic_vector(7 downto 0) := X"7D";
		SERIAL_base_addr	:	std_logic_vector(7 downto 0) := X"A0";------------
		SERIAL_high_addr	:	std_logic_vector(7 downto 0) := X"AF";-------------
		tdc_chl_num		:	integer := 4;
                CH_NUM : integer := 40;
		RND_CHIP_NUM   : integer := 4     -- No. of random chip wng-x
		);
	port(
		clk_40M_I	:	in	std_logic;
		clk_40M_IB	:	in	std_logic;
		
		ext_clk_I	:	in	std_logic;
		ext_clk_IB	:	in	std_logic;
--
                laser_clk    : in std_logic;

                trig_out : out std_logic_vector(CH_NUM-1 downto 0);
--		sys_clk_80M	:	in	std_logic;--system clock,80MHz
--		reset_in_n	:	in	std_logic;--system reset,high active;
		----cpld interface------
		cpld_fpga_clk	:	in	std_logic;--33MHz clock from cpld
		cpld_fpga_data	:	inout	std_logic_vector(31 downto 0);
		cpld_fpga_addr	:	in	std_logic_vector(7 downto 0);
		cpld_fpga_sglrd	:	in	std_logic;--single read enable,high active
		cpld_fpga_sglwr	:	in	std_logic;--single write enable,high active
		cpld_fpga_brtrd_req	:	in	std_logic;--burst read request,high active
		fpga_cpld_burst_act	:	out	std_logic;
		fpga_cpld_burst_en	:	out	std_logic;--burst enable,indicate fifo has stored a burst length	
		fpga_cpld_rst_n		:	out	std_logic
		--*************************

		);
end ground_pro_top;

architecture Behavioral of ground_pro_top is
	COMPONENT cpld_if
	generic(
		DAC_Base_Addr : std_logic_vector(7 downto 0) := X"40";
		DAC_High_Addr : std_logic_vector(7 downto 0) := X"43";
		CNT_Base_Addr : std_logic_vector(7 downto 0) := X"50";
		CNT_High_Addr : std_logic_vector(7 downto 0) := X"71";
		CPLD_Base_Addr : std_logic_vector(7 downto 0):=X"80";
		CRG_Base_Addr : std_logic_vector(7 downto 0):=X"90";
		TDC_Base_Addr : std_logic_vector(7 downto 0) := X"10";
		TDC_High_Addr : std_logic_vector(7 downto 0) := X"14";
		TIME_Base_Addr : std_logic_vector(7 downto 0) := X"20";
		TIME_High_Addr : std_logic_vector(7 downto 0) := X"23";
		QTEL_Base_Addr : std_logic_vector(7 downto 0) := X"7B";
		QTEL_High_Addr : std_logic_vector(7 downto 0) := X"7D";
		SERIAL_base_addr	:	std_logic_vector(7 downto 0) := X"A0";------------
		SERIAL_high_addr	:	std_logic_vector(7 downto 0) := X"AF"-------------
	);
	PORT(
		sys_clk_80M : IN std_logic;
		sys_rst_n : IN std_logic;
		cpld_fpga_clk : IN std_logic;
		cpld_fpga_addr : IN std_logic_vector(7 downto 0);
		cpld_fpga_sglrd : IN std_logic;
		cpld_fpga_sglwr : IN std_logic;
		cpld_fpga_brtrd_req : IN std_logic;
		dps_cpldif_rd_data : IN std_logic_vector(31 downto 0);
		dac_cpldif_rd_data : IN std_logic_vector(31 downto 0);
		count_cpldif_rd_data : IN std_logic_vector(31 downto 0);
		crg_cpldif_rd_data : IN std_logic_vector(31 downto 0);
		sysmon_cpldif_rd_data : IN std_logic_vector(31 downto 0);
		tdc_cpldif_rd_data : IN std_logic_vector(31 downto 0);
		time_cpldif_rd_data : IN std_logic_vector(31 downto 0);
		qtel_cpldif_rd_data : IN std_logic_vector(31 downto 0);
		tdc_cpldif_fifo_wr_en : IN std_logic;
		tdc_cpldif_fifo_clr : IN std_logic;
		tdc_cpldif_fifo_wr_data : IN std_logic_vector(31 downto 0);    
		cpld_fpga_data : INOUT std_logic_vector(31 downto 0);      
		fpga_cpld_burst_act : OUT std_logic;
		fpga_cpld_burst_en : OUT std_logic;
		cpldif_addr : OUT std_logic_vector(7 downto 0);
		cpldif_rd_en : OUT std_logic;
		cpldif_wr_en : OUT std_logic;
		cpldif_wr_data : OUT std_logic_vector(31 downto 0);
		cpldif_tdc_fifo_almost_full : OUT std_logic;
		cpldif_tdc_fifo_prog_full : OUT std_logic;
		cpldif_tdc_fifo_full : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT CRG
	generic(
		CRG_Base_Addr : std_logic_vector(7 downto 0)
	);
	PORT(
--		clk_in : IN std_logic;
		clk_40M_I : IN std_logic;
		clk_40M_IB : IN std_logic;
		reset_in_n : IN std_logic;
		cpldif_crg_addr : IN std_logic_vector(7 downto 0);
		cpldif_crg_wr_en : IN std_logic;
		cpldif_crg_wr_data : IN std_logic_vector(31 downto 0);
		cpldif_crg_rd_en : IN std_logic;          
		sys_clk_80M : OUT std_logic;
		sys_clk_60M : OUT std_logic;
		sys_clk_200M : OUT std_logic;
		sys_clk_160M : OUT std_logic;
		sys_clk_160M_inv : OUT std_logic;
		sys_clk_dcm : OUT std_logic;
		sys_rst_n : OUT std_logic;
		crg_cpldif_rd_data : OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;
	
	COMPONENT DPS_QKD
          generic(
            CH_NUM : integer := 40
            );
	PORT(
		sys_clk  : in std_logic;
--	   sys_clk_60M : in std_logic;
                sys_clk_200M : in std_logic;
                laser_clk : in std_logic;
                trig_out : out std_logic_vector(CH_NUM-1 downto 0);
                
		ext_clk_I	:	in	std_logic;
		ext_clk_IB	:	in	std_logic;
--	   sys_clk_160M_inv : in std_logic;
		sys_rst_n : IN std_logic;

                dps_cpldif_rd_data : out std_logic_vector(31 downto 0);
		cpldif_dps_addr : IN std_logic_vector(7 downto 0);
		cpldif_dps_wr_en : IN std_logic;
		cpldif_dps_wr_data : IN std_logic_vector(31 downto 0);
		cpldif_dps_rd_en : IN std_logic

		);
	END COMPONENT;
	
	
	signal dac_cpldif_rd_data : std_logic_vector(31 downto 0);
--	signal tdc_cpldif_rd_data : std_logic_vector(31 downto 0);
	signal crg_cpldif_rd_data : std_logic_vector(31 downto 0);
	signal sysmon_cpldif_rd_data : std_logic_vector(31 downto 0);
	----------
	signal cpldif_rd_data	:	std_logic_vector(31 downto 0);
	signal cpldif_addr	:	std_logic_vector(7 downto 0);
	signal cpldif_rd_en	:	std_logic;
	signal cpldif_wr_en	:	std_logic;
	signal cpldif_wr_data	:	std_logic_vector(31 downto 0);
	-----tdc module and time module
	signal tdc_cpldif_fifo_wr_en	:	std_logic;
	signal tdc_cpldif_fifo_wr_data	:	std_logic_vector(31 downto 0);
	signal cpldif_tdc_fifo_full	:	std_logic;
	signal cpldif_tdc_fifo_almost_full	:	std_logic;
	signal cpldif_tdc_fifo_prog_full	:	std_logic;
	signal tdc_cpldif_fifo_clr	:	std_logic;
	
--	signal dps_cpldif_fifo_clr	:	std_logic;
	signal tdc_fifo_wr_en		:	std_logic;
	signal tdc_fifo_wr_data		:	std_logic_vector(63 downto 0);
	signal tdc_fifo_prog_full	:	std_logic;

	--------------
	signal tdc_cpldif_rd_data : std_logic_vector(31 downto 0);
	signal time_cpldif_rd_data : std_logic_vector(31 downto 0);
	signal time_local_cur : std_logic_vector(47 downto 0);
	signal gps_pps	:	std_logic;
	signal tdc_data_store_en	:	std_logic;
	signal tdc_count_hit : std_logic_vector(tdc_chl_num-1 downto 0);	
	-------------------------------------------------------	
	signal chopper_ctrl_80M	:	std_logic;
	signal qtel_clk_80M_out	:	std_logic;
	signal qtel_clk_80M_delay_out	:	std_logic;
	signal tdc_qtel_hit  : std_logic_vector(tdc_chl_num-1 downto 0);	
	signal  qtel_counter_match : std_logic_vector(tdc_chl_num-1 downto 0);
	--
--	signal clk_40M_p : std_logic;
--	signal clk_40M_n : std_logic;
	signal sys_clk_80M : std_logic;
	signal sys_clk_60M : std_logic;
	signal sys_clk_200M : std_logic;
	signal sys_clk_160M : std_logic;
	signal sys_clk_160M_inv : std_logic;
	signal sys_clk_dcm : std_logic;
	signal sys_rst_n : std_logic;
	signal fpga_cpld_rst_d : std_logic;
	signal cpldif_burst_len : std_logic_vector(10 downto 0);
	--count interface
--	signal tdc_count_time_value : std_logic_vector(31 downto 0);
	signal dps_cpldif_rd_data   : std_logic_vector(31 downto 0);
	signal count_cpldif_rd_data : std_logic_vector(31 downto 0);
	signal qtel_cpldif_rd_data : std_logic_vector(31 downto 0);
	signal cnt : std_logic_vector(3 downto 0) := X"0";
	signal apd_fpga_hit : std_logic_vector(tdc_chl_num-1 downto 0);		
	signal burst_en : std_logic;
	signal burst_act : std_logic;
	--signal qtel ---
	signal exp_running : std_logic;
	signal qtel_en : std_logic;
	signal reset_in_n : std_logic;
	signal GPS_pulse_reg : std_logic;
	signal GPS_pulse_int			:  std_logic;--80M clock domain
	signal GPS_pulse_int_active:  std_logic;--80M clock domain
	
	signal syn_light_int			:  std_logic;--80M clock domain
	signal syn_light_in			:  std_logic;--80M clock domain
	signal syn_light_sel			:  std_logic;--80M clock domain
	
--	signal data_count32 : std_logic_vector(31 downto 0) := (others => '0');	
	signal reset_count32 : std_logic_vector(7 downto 0) := (others => '0');	
--	signal data5_1 : std_logic_vector(4 downto 0) := (others => '0');
--	signal data5_2 : std_logic_vector(4 downto 0) := (others => '0');	
--	signal data5_3 : std_logic_vector(4 downto 0) := (others => '0');	
--	signal data5_4 : std_logic_vector(4 downto 0) := (others => '0');	
--	signal data5_5 : std_logic_vector(4 downto 0) := (others => '0');	
--	signal data5_6 : std_logic_vector(4 downto 0) := (others => '0');	

--	constant delay : integer := 4000;
--	constant delay_add : integer := 1000;
--	constant delay_1_1 : integer := delay + delay_add;
--	constant delay_1_2 : integer := delay + delay_add+1;
--	constant delay_1_3 : integer := delay + delay_add+2;
--	
--	constant delay_2_1 : integer := delay + delay_add + delay_add;
--	constant delay_2_2 : integer := delay + delay_add + delay_add+1;
--	constant delay_2_3 : integer := delay + delay_add + delay_add+2;
--	
--	constant delay_3_1 : integer := delay + delay_add + delay_add + delay_add;
--	constant delay_3_2 : integer := delay + delay_add + delay_add + delay_add+1;
--	constant delay_3_3 : integer := delay + delay_add + delay_add + delay_add+2;
	
begin
	---Test point----
	fpga_cpld_burst_en<=burst_en;
	fpga_cpld_burst_act<= burst_act;
--	out_ttl<= qtel_clk_80M_delay_out;
--	out_nim<= sys_clk_80M;
--	Tp(0)<= cpld_fpga_clk;--TP15
--	Tp(1)<= burst_en;--TP14
--	Tp(2)<= cpld_fpga_brtrd_req;--TP13
--	Tp(3)<= burst_act;--TP16
--	Tp(4)<= cpld_fpga_sglwr;--TP12
--	Tp(5)<= cpld_fpga_sglrd;--TP22
	--Test point----
	
--	tdc_cpldif_fifo_clr	<=	'0';
	fpga_cpld_rst_n	<=	sys_rst_n;
	

	Inst_cpld_if: cpld_if 
	generic map(
		DAC_Base_Addr => DAC_Base_Addr,
		DAC_High_Addr => DAC_High_Addr,
		CNT_Base_Addr => CNT_Base_Addr,
		CNT_High_Addr => CNT_High_Addr,
		CPLD_Base_Addr => CPLD_Base_Addr,
		CRG_Base_Addr => CRG_Base_Addr,
		TDC_Base_Addr => TDC_Base_Addr,
		TDC_High_Addr => TDC_High_Addr,
		QTEL_Base_Addr => Qtel_Base_Addr,
		QTEL_High_Addr => Qtel_High_Addr,
		TIME_Base_Addr => TIME_Base_Addr,
		TIME_High_Addr => TIME_High_Addr,
		SERIAL_High_Addr => SERIAL_High_Addr,
		SERIAL_Base_Addr => SERIAL_Base_Addr
	)
	PORT MAP(
		sys_clk_80M => sys_clk_80M,
		sys_rst_n => sys_rst_n,
		cpld_fpga_clk => cpld_fpga_clk,
		cpld_fpga_data => cpld_fpga_data,
		cpld_fpga_addr => cpld_fpga_addr,
		cpld_fpga_sglrd => cpld_fpga_sglrd,
		cpld_fpga_sglwr => cpld_fpga_sglwr,
		cpld_fpga_brtrd_req => cpld_fpga_brtrd_req,
		fpga_cpld_burst_act => burst_act,
		fpga_cpld_burst_en => burst_en,
		dps_cpldif_rd_data => dps_cpldif_rd_data,
		dac_cpldif_rd_data => dac_cpldif_rd_data,
		count_cpldif_rd_data => count_cpldif_rd_data,
		qtel_cpldif_rd_data => qtel_cpldif_rd_data, 
		crg_cpldif_rd_data => crg_cpldif_rd_data,
		sysmon_cpldif_rd_data => sysmon_cpldif_rd_data,
		tdc_cpldif_rd_data => tdc_cpldif_rd_data,
		time_cpldif_rd_data => time_cpldif_rd_data,
		cpldif_addr => cpldif_addr,
		cpldif_wr_en => cpldif_wr_en,
		cpldif_wr_data => cpldif_wr_data,
		cpldif_rd_en => cpldif_rd_en,
--		cpldif_addr => open,
--		cpldif_wr_en => open,
--		cpldif_wr_data => open,
		tdc_cpldif_fifo_wr_en => tdc_cpldif_fifo_wr_en,
		tdc_cpldif_fifo_clr => tdc_cpldif_fifo_clr,
		tdc_cpldif_fifo_wr_data => tdc_cpldif_fifo_wr_data,
		cpldif_tdc_fifo_almost_full => cpldif_tdc_fifo_almost_full,
		cpldif_tdc_fifo_prog_full => cpldif_tdc_fifo_prog_full,
		cpldif_tdc_fifo_full => cpldif_tdc_fifo_full
	);
	dac_cpldif_rd_data	<= (others => '0');
	sysmon_cpldif_rd_data	<= (others => '0');
	time_cpldif_rd_data	<= (others => '0');
	time_local_cur	<= (others => '0');
	qtel_counter_match	<= (others => '0');
	qtel_cpldif_rd_data	<= (others => '0');
	qtel_en	<= '0';
	
	Inst_CRG: CRG 
	generic map(
		CRG_Base_Addr => CRG_Base_Addr
	)
	PORT MAP(
--		clk_in => clk_40M_p,
		clk_40M_I => clk_40M_I,
		clk_40M_IB => clk_40M_IB,
		reset_in_n => reset_in_n,
		sys_clk_80M => sys_clk_80M,
		sys_clk_60M => open,
		sys_clk_200M => sys_clk_200M,
		sys_clk_160M => sys_clk_160M,
		sys_clk_160M_inv => sys_clk_160M_inv,
		sys_clk_dcm => sys_clk_dcm,
		sys_rst_n => sys_rst_n,
		cpldif_crg_addr => cpldif_addr,
		cpldif_crg_wr_en => cpldif_wr_en,
		cpldif_crg_wr_data => cpldif_wr_data,
		cpldif_crg_rd_en => cpldif_rd_en,
		crg_cpldif_rd_data => crg_cpldif_rd_data
	);
	
	Inst_DPS_QKD: DPS_QKD
generic map (
  CH_NUM => CH_NUM)
          PORT MAP(
		sys_clk => sys_clk_80M,
--		sys_clk_60M => sys_clk_60M,
		sys_clk_200M => sys_clk_200M,
		ext_clk_I => ext_clk_I,
		ext_clk_IB => ext_clk_IB,
		sys_rst_n => sys_rst_n,
	
		cpldif_dps_addr => cpldif_addr,
		cpldif_dps_wr_en => cpldif_wr_en,
		cpldif_dps_wr_data => cpldif_wr_data,
		cpldif_dps_rd_en => cpldif_rd_en,
		dps_cpldif_rd_data => dps_cpldif_rd_data,

                laser_clk => laser_clk,
                trig_out => trig_out
	);

	
process (sys_clk_80M)
begin  
   if (sys_clk_80M'event and sys_clk_80M = '1') then
      if (reset_count32 >= x"FF") then
         reset_count32	<= reset_count32;
		else
			reset_count32	<= reset_count32 + 1;
      end if;
   end if;
end process;

process (sys_clk_80M)
begin  
   if (sys_clk_80M'event and sys_clk_80M = '1') then
      if (reset_count32 < x"FF") then
         reset_in_n	<= '0';
		else
			reset_in_n	<= '1';
      end if;
   end if;
end process;


end Behavioral;

