--                                                                            --
-- Author(s):                                                                 --
--   Miguel Angel Sagreras                                                    --
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

entity scope is
	generic (
		constant fpga : natural;
		constant DDR_TCP      : natural;
		constant DDR_SCLKPHASES : natural;
		constant DDR_SCLKEDGES : natural;
		constant DDR_DATAPHASES : natural :=  1;
		constant DDR_DATAEDGES : natural :=  1;
		constant DDR_CMNDPHASES : natural :=  2;
		constant DDR_MARK     : natural;
		constant DDR_STROBE   : string := "NONE";
		constant DDR_BANKSIZE : natural :=  3;
		constant DDR_ADDRSIZE : natural := 13;
		constant DDR_CLMNSIZE : natural :=  6;
		constant DDR_LINESIZE : natural := 16;
		constant DDR_WORDSIZE : natural := 16;
		constant DDR_BYTESIZE : natural :=  8;
		constant PAGE_SIZE    : natural := 9;
		constant NIBBLE_SIZE  : natural := 4);

	port (
		ddrs_rst : in std_logic;
		sys_ini : out std_logic;

		input_rst : in std_logic := '0';
		input_clk : in std_logic;

		ddrs_clks : in std_logic_vector(0 to ddr_sclkphases/ddr_sclkedges-1);
		ddrs_rtt : in std_logic_vector;
		ddrs_bl  : in std_logic_vector(3-1 downto 0) := "000";
		ddrs_cl  : in std_logic_vector(3-1 downto 0) := "010";
		ddrs_cwl : in std_logic_vector(3-1 downto 0) := "000";
		ddrs_wr  : in std_logic_vector(3-1 downto 0) := "101";
		ddrs_ini : out std_logic;
		ddr_wlreq : out std_logic;
		ddr_wlrdy : in  std_logic := '-';

		ddr_rst : out std_logic;
		ddr_cke : out std_logic;
		ddr_cs  : out std_logic;
		ddr_ras : out std_logic;
		ddr_cas : out std_logic;
		ddr_we  : out std_logic;
		ddr_b   : out std_logic_vector(DDR_BANKSIZE-1 downto 0);
		ddr_a   : out std_logic_vector(DDR_ADDRSIZE-1 downto 0);
		ddr_dmi : in  std_logic_vector(DDR_LINESIZE/DDR_BYTESIZE-1 downto 0);
		ddr_dmo : out std_logic_vector(DDR_LINESIZE/DDR_BYTESIZE-1 downto 0);
		ddr_dmt : out std_logic_vector(DDR_LINESIZE/DDR_BYTESIZE-1 downto 0);
		ddr_dqsi : in  std_logic_vector(DDR_DATAPHASES*DDR_WORDSIZE/DDR_BYTESIZE-1 downto 0);
		ddr_dqst : out std_logic_vector(DDR_LINESIZE/DDR_BYTESIZE-1 downto 0);
		ddr_dqso : out std_logic_vector(DDR_LINESIZE/DDR_BYTESIZE-1 downto 0);
		ddr_dqt : out std_logic_vector(DDR_LINESIZE/DDR_BYTESIZE-1 downto 0);
		ddr_dqi : in  std_logic_vector(DDR_LINESIZE-1 downto 0);
		ddr_dqo : out std_logic_vector(DDR_LINESIZE-1 downto 0);
		ddr_odt : out std_logic;
		ddr_sto : out std_logic_vector(DDR_LINESIZE/DDR_BYTESIZE-1 downto 0);
		ddr_sti : in  std_logic_vector(DDR_DATAPHASES*DDR_WORDSIZE/DDR_BYTESIZE-1 downto 0);

		mii_rst  : in std_logic := '0';
		mii_rxc  : in std_logic;
		mii_rxdv : in std_logic;
		mii_rxd  : in std_logic_vector;
		mii_txc  : in std_logic;
		mii_txen : out std_logic;
		mii_txd  : out std_logic_vector;

		vga_rst   : in  std_logic := '0';
		vga_clk   : in  std_logic;
		vga_hsync : out std_logic;
		vga_vsync : out std_logic;
		vga_blank : out std_logic;
		vga_frm   : out std_logic;
		vga_red   : out std_logic_vector(8-1 downto 0);
		vga_green : out std_logic_vector(8-1 downto 0);
		vga_blue  : out std_logic_vector(8-1 downto 0);

		tpo : out std_logic_vector(0 to 4-1) := (others  => 'Z'));
end;

library hdl4fpga;
use hdl4fpga.std.all;
--use hdl4fpga.cgafont.all;

architecture def of scope is
	signal video_don : std_logic;
	signal video_frm : std_logic;
	signal video_ena : std_logic;
	signal video_hsync : std_logic;
	signal video_vsync : std_logic;
	signal video_blank : std_logic;

	signal cga_clk : std_logic;
	signal vga_row : std_logic_vector(9-1 downto 0);
	signal cga_row : std_logic_vector(9-1 downto 4);
	signal cga_col : std_logic_vector(4-1 downto 0);
	signal cga_ptr : std_logic_vector(9-1 downto 0);
	signal cga_we  : std_logic;
	signal cga_dot : std_logic;
	signal cga_don : std_logic;
	signal cga_code : byte;

	signal ddrs_clk180 : std_logic;

	signal ddr_lp_clk : std_logic;

	signal ddr_ini : std_logic;
	signal xdr_ini : std_logic;
	signal ddr_cmd_req : std_logic;
	signal ddr_cmd_rdy : std_logic;
	signal ddr_ba : std_logic_vector(0 to DDR_BANKSIZE-1);
	signal xdr_a  : std_logic_vector(0 to DDR_ADDRSIZE-1);
	signal ddr_act : std_logic;
	signal xdr_cas : std_logic;
	signal ddr_pre : std_logic;
	signal ddr_rw  : std_logic;
	signal ddr_di_rdy : std_logic;
	signal ddr_di_req : std_logic;
	signal ddr_di : std_logic_vector(DDR_LINESIZE-1 downto 0);
	signal ddr_do_rdy : std_logic_vector(DDR_DATAPHASES*DDR_WORDSIZE/DDR_BYTESIZE-1 downto 0);


	signal ddrs_ref_req : std_logic;
	signal ddrs_cmd_req : std_logic;
	signal ddrs_cmd_rdy : std_logic;
	signal ddrs_ba : std_logic_vector(0 to DDR_BANKSIZE-1);
	signal ddrs_a  : std_logic_vector(0 to DDR_ADDRSIZE-1);
	signal ddrs_rowa  : std_logic_vector(0 to DDR_ADDRSIZE-1);
	signal ddrs_cola  : std_logic_vector(0 to DDR_ADDRSIZE-1);
	signal ddrs_act : std_logic;
	signal ddrs_cas : std_logic;
	signal ddrs_pre : std_logic;
	signal ddrs_rw  : std_logic;
	signal ddrs_wlreq : std_logic;

	signal ddrs_di_rdy : std_logic;
	signal ddrs_di_req : std_logic;
	signal ddrs_di : std_logic_vector(DDR_LINESIZE-1 downto 0);
	signal ddrs_do_rdy : std_logic_vector(DDR_DATAPHASES*DDR_WORDSIZE/DDR_BYTESIZE-1 downto 0);
	signal ddrs_do : std_logic_vector(DDR_LINESIZE-1 downto 0);

	signal dataio_rst : std_logic;
	signal input_rdy : std_logic := '0';
	signal input_req : std_logic := '0';
	signal input_dat : std_logic_vector(0 to 15);
	
	signal win_rowid  : std_logic_vector(2-1 downto 0);
	signal win_rowpag : std_logic_vector(5-1 downto 0);
    signal win_rowoff : std_logic_vector(7-1 downto 0);
    signal win_colid  : std_logic_vector(2-1 downto 0);
    signal win_colpag : std_logic_vector(2-1 downto 0);
    signal win_coloff : std_logic_vector(13-1 downto 0);

    signal chann_dat : std_logic_vector(32-1 downto 0);

	signal grid_dot : std_logic;
	signal plot_dot : std_logic_vector(0 to 2-1);

	signal miirx_req  : std_logic;
	signal miirx_rdy  : std_logic;
	signal miitx_req  : std_logic;
	signal miidma_rreq : std_logic;
	signal miidma_rrdy : std_logic;
	signal miidma_rxen : std_logic;
	signal miidma_rxd  : std_logic_vector(mii_txd'length-1 downto 0);
	signal miitx_addr : std_logic_vector(0 to 10-unsigned_num_bits(DDR_DATAPHASES*DDR_LINESIZE/mii_rxd'length-1));
	signal miitx_dat : std_logic_vector(mii_txd'length-1 downto 0);
	signal miitx_ena  : std_logic;

	signal miitx_udprdy : std_logic := '0';
	signal miitxudp_rdy : std_logic := '0';
	signal miitxudp_req : std_logic := '0';
	signal miitx_udpreq : std_logic := '0';
	signal miirx_udprdy : std_logic;
	signal udptx_rdy : std_logic;
	signal udprx_rdy : std_logic;

	signal rxdv : std_logic;
	signal rxd  : nibble;
	signal pkt_cntr : std_logic_vector(15 downto 0) := x"0000";
	signal tpkt_cntr : byte := x"00";
	signal a0 : std_logic;
	signal tp : nibble_vector(7 downto 0) := (others => "0000");

begin


--	process (input_clk)
--		variable sample : unsigned(0 to 15) := (others => '0');
--	begin
--		if falling_edge(input_clk) then
--			input_dat <= std_logic_vector(resize(sample, input_dat'length));
--			if ddrs_ini='0' then
--				input_req <= '0';
--			elsif input_rdy='0' then
--				input_req <= '1';
--			end if;
--			sample := sample + 1;
--		end if;
--	end process;

	input_req <= xdr_ini and not input_rdy;
	process (input_rst, input_clk)
		constant n : natural := 15;
		variable r : unsigned(0 to n);
	begin
		if input_rst='0' then
			r := to_unsigned(61, r'length);
		elsif rising_edge(input_clk) then
			input_dat <= std_logic_vector(resize(signed(r(0 to n)), input_dat'length));
--			input_dat <= (others => r(n-2));
			r := r + 1;
		end if;
	end process;

--	video_vga_e : entity hdl4fpga.video_vga
--	generic map (
--		n => 12)
--	port map (
--		clk   => vga_clk,
--		hsync => video_hsync,
--		vsync => video_vsync,
--		frm   => video_frm,
--		don   => video_don);
--	vga_frm <= video_frm;
--	video_blank <= video_don and video_frm;
--		
--	win_stym_e : entity hdl4fpga.win_sytm
--	port map (
--		win_clk => vga_clk,
--		win_frm => video_frm,
--		win_don => video_don,
--		win_rowid  => win_rowid ,
--		win_rowpag => win_rowpag,
--		win_rowoff => win_rowoff,
--		win_colid  => win_colid,
--		win_colpag => win_colpag,
--		win_coloff => win_coloff);
--
--	win_ena_b : block
--		signal scope_win : std_logic;
--		signal cga_win : std_logic;
--		signal grid_don : std_logic;
--		signal plot_dot1 : std_logic_vector(plot_dot'range);
--		signal grid_dot1 : std_logic;
--		signal plot_start  : std_logic;
--		signal plot_end  : std_logic;
--	begin
--		scope_win <= setif(win_rowid&win_colid = "1111");
--		cga_win   <= cga_dot and setif(win_rowid&win_colid="1101");
--
--		align_e : entity hdl4fpga.align
--		generic map (
--			n => 10,
--			d => (
--				0 to 2 => 4+10,		-- hsync, vsync, blank
--				3 to 3 => 2+10,		-- scope_win -> plot_end
--				4 to 5 => 1,		-- plot
--				6 to 6 => 1+10,		-- grid
--			    7 to 7 => 1,		-- plot_end -> grid_don
--			    8 to 8 => 3,		-- grid_don -> plot_start
--			    9 to 9 => 3))		-- cga_dot -> cga_dot
--		port map (
--			clk   => vga_clk,
--
--			di(0) => video_hsync,
--			di(1) => video_vsync,
--			di(2) => video_blank,
--
--			di(3) => scope_win,
--
--			di(4) => plot_dot(0),
--			di(5) => plot_dot(1),
--			di(6) => grid_dot,
--			di(7) => plot_end,
--			di(8) => grid_don,
--			di(9) => cga_win,
--
--			do(0) => vga_hsync,
--			do(1) => vga_vsync,
--			do(2) => vga_blank,
--
--			do(3) => plot_end,
--
--			do(4) => plot_dot1(0),
--			do(5) => plot_dot1(1),
--			do(6) => grid_dot1,
--			do(7) => grid_don,
--			do(8) => plot_start,
--			do(9) => cga_don);
--
--		vga_red   <= (others => (plot_start and plot_end and plot_dot1(1)) or cga_don);
--		vga_green <= (others => (plot_start and plot_end and plot_dot1(0)) or cga_don);
--		vga_blue  <= (others => (grid_don and grid_dot1) or cga_don);
--		
--	end block;
--
--	video_ena <= setif(win_rowid="11");

	ddrs_a <= ddrs_rowa when ddrs_act='1' else ddrs_cola;

	dataio_rst <= not xdr_ini;
	dataio_e : entity hdl4fpga.dataio 
	generic map (
		PAGE_SIZE => PAGE_SIZE,
		DDR_BANKSIZE => DDR_BANKSIZE,
		DDR_ADDRSIZE => DDR_ADDRSIZE,
		DDR_CLNMSIZE => DDR_CLMNSIZE,
		DDR_LINESIZE => DDR_LINESIZE)
	port map (
		sys_rst   => dataio_rst,

		input_req => input_req,
		input_rdy => input_rdy,
		input_clk => input_clk,
		input_dat => input_dat,

		video_clk => vga_clk,
		video_ena => video_ena,
		video_row => win_rowpag(3 downto 0),
		video_col => win_coloff,
		video_do  => chann_dat,

		ddrs_clk  => ddrs_clks(0),
		ddrs_rreq => ddrs_ref_req,
		ddrs_creq => ddrs_cmd_req,
		ddrs_crdy => ddrs_cmd_rdy,
		ddrs_bnka => ddrs_ba,
		ddrs_rowa => ddrs_rowa,
		ddrs_cola => ddrs_cola,
		ddrs_rw  => ddrs_rw,
		ddrs_act => ddrs_act,
		ddrs_cas => ddrs_cas,
		ddrs_pre => ddrs_pre,

		ddrs_di_rdy => ddr_di_rdy,
		ddrs_di_req => ddrs_di_req,
		ddrs_di => ddrs_di,
		ddrs_do_rdy => ddrs_do_rdy(0),
		ddrs_do => ddrs_do,

		mii_rst => mii_rst,
		mii_txc => mii_txc,
		miirx_req => miirx_req,
		miirx_rdy => miirx_rdy,
		miitx_req => miidma_rreq,
		miitx_rdy => miidma_rrdy,
		miitx_ena => miidma_rxen,
		miitx_dat => miidma_rxd);

	miirx_udp_e : entity hdl4fpga.miirx_mac
	port map (
		mii_rxc  => mii_rxc,
		mii_rxdv => mii_rxdv,
		mii_rxd  => mii_rxd,

		mii_txc  => open,
		mii_txen => miirx_udprdy);

	ddrsync_i : entity hdl4fpga.ffdasync
	generic map (
		n => 2)
	port map (
		arst => ddrs_rst,
		clk  => ddrs_clks(0),
		d(0) => miirx_udprdy,
		d(1) => miitxudp_rdy,
		q(0) => udprx_rdy,
		q(1) => udptx_rdy);

	rx_p : process (ddrs_clks(0))
		variable req_edge : std_logic;
		variable rdy_edge : std_logic;
	begin
		if rising_edge(ddrs_clks(0)) then
			if ddrs_rst='1' then
				miirx_req <= '0';
			elsif miirx_req='0' then
				if req_edge='0' then
					if udprx_rdy='1' then
						miirx_req <= '1';
					end if;
				end if;
			elsif miirx_rdy='1' then
				if rdy_edge='0' then
					miirx_req <= rdy_edge;
				end if;
			end if;
			rdy_edge := miirx_rdy;
			req_edge := udprx_rdy;
		end if;
	end process;

	tx_p : process (ddrs_clks(0))
		variable req_edge : std_logic;
		variable rdy_edge : std_logic;
	begin
		if rising_edge(ddrs_clks(0)) then
			if ddrs_rst='1' then
				miitx_req <= '0';
			elsif miirx_rdy='1' then
				if req_edge='0' then
					miitx_req <= '1';
				end if;
			elsif udptx_rdy='1' then
				if rdy_edge='0' then
					miitx_req <= '0';
				end if;
			end if;
			req_edge := miirx_rdy;
			rdy_edge := udptx_rdy;
		end if;
	end process;

	miitxsync_i : entity hdl4fpga.ffdasync
	port map (
		arst => ddrs_rst,
		clk  => mii_txc,
		d(0) => miitx_req,
		q(0) => miitxudp_req);

	miitx_udp_e : entity hdl4fpga.miitx_udp
	generic map (
		payload_size => 2**(PAGE_SIZE+1))
	port map (
		miidma_rrdy => miidma_rrdy,
		miidma_rreq => miidma_rreq,
		miidma_rxen => miidma_rxen,
		miidma_rxd  => miidma_rxd,
		mii_txc  => mii_txc,
		mii_treq => miitx_udpreq,
		mii_trdy => miitx_udprdy,
		mii_txen => miitx_ena,
		mii_txd  => mii_txd);

	process (mii_txc)
		variable req_edge : std_logic;
		variable rdy_edge : std_logic;
	begin
		if rising_edge(mii_txc) then
			if miitx_udpreq='0' then
				if miitxudp_req='1' then
					if  req_edge='0' then
						miitx_udpreq <= '1';
						miitxudp_rdy <= '0';
					end if;
				end if;
			elsif miitx_udprdy='1' then
				if rdy_edge='0' then
					miitx_udpreq <= '0';
					miitxudp_rdy <= '1';
				end if;
			end if;

			req_edge := miitxudp_req;
			rdy_edge := miitx_udprdy;
		end if;
	end process;

	tpo(0) <= miidma_rreq;
	tpo(1) <= miidma_rrdy;
	tpo(2) <= miirx_udprdy;
	mii_txen <= miitx_ena;
	process (mii_txc)
		variable edge : std_logic;
	begin
		if rising_edge(mii_txc) then
			if miitx_ena='1' then
				if edge='0' then
					tpkt_cntr <= byte(unsigned(tpkt_cntr) + 1);
				end if;
			end if;
			edge := miitx_ena;
		end if;
	end process;

	process (mii_rxc)
		variable edge : std_logic;
	begin
		if rising_edge(mii_rxc) then
			if miirx_udprdy='1' then
				if edge='0' then
					pkt_cntr <= std_logic_vector(unsigned(pkt_cntr) + 1);
				end if;
			end if;
			edge := miirx_udprdy;
		end if;
	end process;

	ddrs_di_g : for i in ddr_di'range generate
		signal xx : std_logic := '0';
	begin
		process (ddrs_clks(0))
		begin
			if rising_edge(ddrs_clks(0)) then
				if ddr_di_req='0' then
					xx <= '0';
				else
					xx <= not xx;
			
				end if;
			end if;
		end process;
		ddr_di(i) <= ddrs_di(i) when xdr_ini='1' else '1' when i/DDR_WORDSIZE=0 else '0';
	end generate;

	ddrs_ini <= xdr_ini;
	ddr_ba  <= ddrs_ba when xdr_ini='1' else (others => '0');
	xdr_a   <= ddrs_a  when xdr_ini='1' else (others => '0');
	ddrs_di_rdy <= ddr_di_rdy when xdr_ini='1' else ddr_di_req;
	ddrs_di_req <= ddr_di_req  when xdr_ini='1' else '0';
	ddrs_do_rdy <= ddr_do_rdy  when xdr_ini='1' else (others => '0');
	ddrs_cmd_rdy <= ddr_cmd_rdy  when xdr_ini='1' else '0';
	ddrs_act <= ddr_act;
	ddrs_cas <= xdr_cas;
	ddrs_pre <= ddr_pre;
	
	ddr_wlreq <= ddr_ini;
	process (
		ddrs_rst,
		ddrs_clks(0),
	   	ddrs_cmd_req,
		ddrs_rw,
		xdr_ini)
	begin
		if rising_edge(ddrs_clks(0)) then
			if ddrs_rst='1' then
				xdr_ini <= '0';
				ddr_rw  <= '0';
				ddr_cmd_req <= '0';
			elsif ddr_ini='1' then
				if ddr_cmd_req='1' then
					if ddr_cmd_rdy='0' then
						if ddr_rw='0' then 
							ddr_cmd_req <= '0';
							elsif ddr_wlrdy='1' then
							ddr_cmd_req <= '0';
						end if;
					end if;
				elsif ddr_cmd_rdy='1' then
					if ddr_rw='0' then 
						ddr_cmd_req <= '1';
					else
						xdr_ini <= '1';
					end if;
					ddr_rw <= '1';
				end if;
			elsif ddr_cmd_rdy='1' then
				ddr_cmd_req <= '1';
			end if;
		end if;

		if xdr_ini='1' then
			ddr_rw <= ddrs_rw;
			ddr_cmd_req <= ddrs_cmd_req;
		end if;
	end process;

	ddr_e : entity hdl4fpga.xdr
	generic map (
		fpga => fpga,
		mark => DDR_MARK,
		strobe    => DDR_STROBE,
		sclk_phases => DDR_SCLKPHASES,
		sclk_edges  => DDR_SCLKEDGES,
		data_phases => DDR_DATAPHASES,
		data_edges => DDR_DATAEDGES,
		bank_size => DDR_BANKSIZE,
		addr_size => DDR_ADDRSIZE,
		line_size => DDR_LINESIZE,
		word_size => DDR_WORDSIZE,
		byte_size => DDR_BYTESIZE,
		tCP  => DDR_tCP)
	port map (
		sys_rst => ddrs_rst,
		sys_rtt => ddrs_rtt,
		sys_bl  => ddrs_bl,
		sys_cl  => ddrs_cl,
		sys_cwl => ddrs_cwl,
		sys_wr  => ddrs_wr,
		sys_clks => ddrs_clks,
		sys_ini  => ddr_ini,

		sys_cmd_req => ddr_cmd_req,
		sys_cmd_rdy => ddr_cmd_rdy,
		sys_wlreq => open, --ddr_wlreq,
		sys_wlrdy => ddr_wlrdy,
		sys_b   => ddr_ba,
		sys_a   => xdr_a,
		sys_rw  => ddr_rw,
		sys_act => ddr_act,
		sys_cas => xdr_cas,
		sys_pre => ddr_pre,
		sys_di_rdy => ddrs_di_rdy,
		sys_di_req => ddr_di_req,
		sys_di  => ddr_di,
		sys_do_rdy => ddr_do_rdy,
		sys_do  => ddrs_do,

		sys_ref => ddrs_ref_req,

		xdr_rst => ddr_rst,
		xdr_cke => ddr_cke,
		xdr_cs  => ddr_cs,
		xdr_ras => ddr_ras,
		xdr_cas => ddr_cas,
		xdr_we  => ddr_we,
		xdr_b   => ddr_b,
		xdr_a   => ddr_a,
		xdr_dmi  => ddr_dmi,
		xdr_dmt  => ddr_dmt,
		xdr_dmo  => ddr_dmo,
		xdr_dqst => ddr_dqst,
		xdr_dqsi => ddr_dqsi,
		xdr_dqso => ddr_dqso,
		xdr_dqt => ddr_dqt,
		xdr_dqi => ddr_dqi,
		xdr_dqo => ddr_dqo,
		xdr_odt => ddr_odt,

		xdr_sti => ddr_sti,
		xdr_sto => ddr_sto);
end;