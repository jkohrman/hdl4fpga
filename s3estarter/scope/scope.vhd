--                                                                            --
-- Author(s):                                                                 --
--   Miguel Angel Sagreras                                                    --
--   Nicolas Alvarez                                                          --
--                                                                            --
-- Copyright (C) 2015                                                         --
--    Miguel Angel Sagreras                                                   --
--                                                                            --
-- This source file may be used and distributed without restriction provided  --
-- that this copyright statement is not removed from the file and that any    --
-- derivative work contains  the original copyright notice and the associated --
-- disclaimer.                                                                --
--                                                                            --
-- This source file is free software; you can redistribute it and/or modify   --
-- it under the terms of the GNU General Public License as published by the   --
-- Free Software Foundation, either version 3 of the License, or (at your     --
-- option) any later version.                                                 --
--                                                                            --
-- This source is distributed in the hope that it will be useful, but WITHOUT --
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or      --
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for   --
-- more details at http://www.gnu.org/licenses/.                              --
--                                                                            --

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library hdl4fpga;
use hdl4fpga.std.all;
use hdl4fpga.xdr_db.all;
--use hdl4fpga.cgafont.all;

library unisim;
use unisim.vcomponents.all;

architecture scope of s3Estarter is
	constant sclk_phases : natural := 4;
	constant data_phases : natural := 2;
	constant data_edges  : natural := 2;
	constant cmd_phases  : natural := 1;
	constant bank_size   : natural := 2;
	constant addr_size   : natural := 13;
	constant line_size   : natural := 2*16;
	constant word_size   : natural := 16;
	constant byte_size   : natural := 8;

	constant sys_per : real := 20.0;

	signal sys_rst   : std_logic;
	signal sys_clk : std_logic;

	--------------------------------------------------
	-- Frequency   -- 133 Mhz -- 166 Mhz -- 166 Mhz --
	-- Multiply by --   8     --   3     --  10     --
	-- Divide by   --   3     --   1     --   3     --
	--------------------------------------------------

	constant ddr_mul : natural := 3;
	constant ddr_div : natural := 1;

	signal input_rst : std_logic;
	signal ddrs_rst  : std_logic;
	signal vga_rst   : std_logic;

	signal ddrs_lckd  : std_logic;
	signal input_lckd : std_logic;

	signal input_clk : std_logic;
	signal video_clk : std_logic;

	signal ddrs_clk0  : std_logic;
	signal ddrs_clk90 : std_logic;

	signal ddr_clk  : std_logic_vector(0 downto 0);
	signal ddr_dqst : std_logic_vector(word_size/byte_size-1 downto 0);
	signal ddr_dqso : std_logic_vector(word_size/byte_size-1 downto 0);
	signal ddr_dqt  : std_logic_vector(sd_dq'range);
	signal ddr_dqo  : std_logic_vector(sd_dq'range);

	signal ddr_lp_clk : std_logic;
	signal ddr_sto1_open : std_logic;

	signal ddrphy_cke : std_logic_vector(cmd_phases-1 downto 0);
	signal ddrphy_cs  : std_logic_vector(cmd_phases-1 downto 0);
	signal ddrphy_ras : std_logic_vector(cmd_phases-1 downto 0);
	signal ddrphy_cas : std_logic_vector(cmd_phases-1 downto 0);
	signal ddrphy_we  : std_logic_vector(cmd_phases-1 downto 0);
	signal ddrphy_odt : std_logic_vector(cmd_phases-1 downto 0);
	signal ddrphy_b   : std_logic_vector(cmd_phases*sd_ba'length-1 downto 0);
	signal ddrphy_a   : std_logic_vector(cmd_phases*sd_a'length-1 downto 0);
	signal ddrphy_dqsi : std_logic_vector(line_size/byte_size-1 downto 0);
	signal ddrphy_dqst : std_logic_vector(line_size/byte_size-1 downto 0);
	signal ddrphy_dqso : std_logic_vector(line_size/byte_size-1 downto 0);
	signal ddrphy_dmi : std_logic_vector(line_size/byte_size-1 downto 0);
	signal ddrphy_dmt : std_logic_vector(line_size/byte_size-1 downto 0);
	signal ddrphy_dmo : std_logic_vector(line_size/byte_size-1 downto 0);
	signal ddrphy_dqi : std_logic_vector(line_size-1 downto 0);
	signal ddrphy_dqt : std_logic_vector(line_size/byte_size-1 downto 0);
	signal ddrphy_dqo : std_logic_vector(line_size-1 downto 0);
	signal ddrphy_sto : std_logic_vector(data_phases*line_size/word_size-1 downto 0);
	signal ddrphy_sti : std_logic_vector(line_size/byte_size-1 downto 0);

	signal rxdv : std_logic;
	signal rxd  : std_logic_vector(e_rxd'range);
	signal txen : std_logic;
	signal txd  : std_logic_vector(e_txd'range);

	signal vga_clk   : std_logic;
	signal vga_hsync : std_logic;
	signal vga_vsync : std_logic;
	signal vga_blank : std_logic;
	signal vga_frm   : std_logic;
	signal vga_red   : std_logic_vector(8-1 downto 0);
	signal vga_green : std_logic_vector(8-1 downto 0);
	signal vga_blue  : std_logic_vector(8-1 downto 0);

begin

	clkin_ibufg : ibufg
	port map (
		I => xtal ,
		O => sys_clk);

	sys_rst <= not sw0;
	dcms_e : entity hdl4fpga.dcms
	generic map (
		ddr_mul => ddr_mul,
		ddr_div => ddr_div,
		sys_per => sys_per)
	port map (
		sys_rst => sys_rst,
		sys_clk => sys_clk,
		input_clk => input_clk,
		ddr_clk0 => ddrs_clk0,
		ddr_clk90 => ddrs_clk90,
		video_clk => video_clk,
		ddr_rst  => ddrs_rst, 
		video_rst   => vga_rst);

	scope_e : entity hdl4fpga.scope
	generic map (
		fpga => spartan3,
		DDR_MARK => M6T,
		DDR_TCP => integer(sys_per*1000.0)*ddr_div/ddr_mul,
		DDR_SCLKEDGES => 2,
		DDR_STROBE => "INTERNAL",
		DDR_CLMNSIZE => 7,
		DDR_BANKSIZE => sd_ba'length,
		DDR_ADDRSIZE => sd_a'length,
		DDR_SCLKPHASES => sclk_phases,
		DDR_DATAPHASES => data_phases,
		DDR_DATAEDGES => data_edges,
		DDR_LINESIZE => line_size,
		DDR_WORDSIZE => word_size,
		DDR_BYTESIZE => byte_size)
	port map (

--		input_rst => input_rst,
		input_clk => input_clk,

		ddrs_rst => ddrs_rst,
		ddrs_clks(0) => ddrs_clk0,
		ddrs_clks(1) => ddrs_clk90,
		ddrs_bl  => "011",
		ddrs_cl  => "110",
		ddrs_rtt => "--",
		ddr_cke  => ddrphy_cke(0),
		ddr_cs   => ddrphy_cs(0),
		ddr_ras  => ddrphy_ras(0),
		ddr_cas  => ddrphy_cas(0),
		ddr_we   => ddrphy_we(0),
		ddr_b    => ddrphy_b(sd_ba'length-1 downto 0),
		ddr_a    => ddrphy_a(sd_a'length-1 downto 0),
		ddr_dmi  => ddrphy_dmi,
		ddr_dmt  => ddrphy_dmt,
		ddr_dmo  => ddrphy_dmo,
		ddr_dqst => ddrphy_dqst,
		ddr_dqsi => ddrphy_dqsi,
		ddr_dqso => ddrphy_dqso,
		ddr_dqi  => ddrphy_dqi,
		ddr_dqt  => ddrphy_dqt,
		ddr_dqo  => ddrphy_dqo,
		ddr_odt  => ddrphy_odt(0),
		ddr_sto  => ddrphy_sto,
		ddr_sti  => ddrphy_sti,

--		mii_rst  => mii_rst,
		mii_rxc  => e_rx_clk,
		mii_rxdv => rxdv,
		mii_rxd  => rxd,
		mii_txc  => e_tx_clk,
		mii_txen => txen,
		mii_txd  => txd,

--		vga_rst   => vga_rst,
		vga_clk   => vga_clk,
		vga_hsync => vga_hsync,
		vga_vsync => vga_vsync,
		vga_frm   => vga_frm,
		vga_blank => vga_blank,
		vga_red   => vga_red,
		vga_green => vga_green,
		vga_blue  => vga_blue);

	ddrphy_e : entity hdl4fpga.ddrphy
	generic map (
		loopback => false,
		registered_dout => false,
		BANK_SIZE => sd_ba'length,
		ADDR_SIZE => sd_a'length,
		data_gear => line_size/word_size,
		WORD_SIZE => word_size,
		BYTE_SIZE => byte_size)
	port map (
		sys_clk0 => ddrs_clk0,
		sys_clk90 => ddrs_clk90, 
		phy_rst => ddrs_rst,

		sys_cke => ddrphy_cke,
		sys_cs  => ddrphy_cs,
		sys_ras => ddrphy_ras,
		sys_cas => ddrphy_cas,
		sys_we  => ddrphy_we,
		sys_b   => ddrphy_b,
		sys_a   => ddrphy_a,
		sys_dqsi => ddrphy_dqsi,
		sys_dqst => ddrphy_dqst,
		sys_dqso => ddrphy_dqso,
		sys_dmi => ddrphy_dmo,
		sys_dmt => ddrphy_dmt,
		sys_dmo => ddrphy_dmi,
		sys_dqi => ddrphy_dqi,
		sys_dqt => ddrphy_dqt,
		sys_dqo => ddrphy_dqo,
		sys_odt => ddrphy_odt,
		sys_sti => ddrphy_sto,
		sys_sto => ddrphy_sti,

		ddr_clk => ddr_clk,
		ddr_cke => sd_cke,
		ddr_cs  => sd_cs,
		ddr_ras => sd_ras,
		ddr_cas => sd_cas,
		ddr_we  => sd_we,
		ddr_b   => sd_ba,
		ddr_a   => sd_a,

		ddr_dm  => sd_dm,
		ddr_dqt  => ddr_dqt,
		ddr_dqi  => sd_dq,
		ddr_dqo  => ddr_dqo,
		ddr_dqst => ddr_dqst,
		ddr_dqsi => sd_dqs,
		ddr_dqso => ddr_dqso);

	e_mdc  <= '0';
	e_mdio <= '0';

	mii_iob_e : entity hdl4fpga.mii_iob
	generic map (
		xd_len => e_txd'length)
	port map (
		mii_rxc  => e_rx_clk,
		iob_rxdv => e_rx_dv,
		iob_rxd  => e_rxd,
		mii_rxdv => rxdv,
		mii_rxd  => rxd,

		mii_txc  => e_tx_clk,
		mii_txen => txen,
		mii_txd  => txd,
		iob_txen => e_txen,
		iob_txd  => e_txd);

	ddr_dqs_g : for i in sd_dqs'range generate
		sd_dqs(i) <= ddr_dqso(i) when ddr_dqst(i)='0' else 'Z';
	end generate;

	process (ddr_dqt, ddr_dqo)
	begin
		for i in sd_dq'range loop
			sd_dq(i) <= 'Z';
			if ddr_dqt(i)='0' then
				sd_dq(i) <= ddr_dqo(i);
			end if;
		end loop;
	end process;

	ddr_clk_i : obufds
	generic map (
		iostandard => "DIFF_SSTL2_I")
	port map (
		i  => ddr_clk(0),
		o  => sd_ck_p,
		ob => sd_ck_n);


	-- LEDs DAC --
	--------------
		
	led0 <= '0';
	led1 <= '0';
	led2 <= '0';
	led3 <= '0';
	led4 <= '0';
	led5  <= '0';
	led6  <= '0';
	led7  <= not sys_rst;

	-- RS232 Transceiver --
	-----------------------

	-- Ethernet Transceiver --
	--------------------------

	e_mdc  <= '0';
	e_mdio <= 'Z';
	e_txd_4 <= '0';


end;
