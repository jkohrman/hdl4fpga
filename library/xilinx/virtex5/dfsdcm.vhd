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

entity dfsdcm is
	generic (
		dcm_per : real;
		dfs_div : natural;
		dfs_mul : natural);
	port ( 
		dfsdcm_rst : in std_logic; 
		dfsdcm_clkin : in std_logic; 
		dfsdcm_clk0  : out std_logic; 
		dfsdcm_clk90 : out std_logic; 
		dfsdcm_lckd : out std_logic);
end;

library unisim;
use unisim.vcomponents.all;

architecture def of dfsdcm is
	signal dfs_clkfb  : std_logic;
	signal dfs_clkfx  : std_logic;
	signal dfs_clk0  : std_logic;
	signal dfs_lckd  : std_logic;

	signal dcm_rst : std_logic;
	signal dcm_clkin : std_logic;
	signal dcm_clkfb : std_logic;
	signal dcm_clk0  : std_logic;
	signal dcm_clk90 : std_logic;
	signal dcm_lckd  : std_logic;
begin

	dfs_i : dcm_base
	generic map (
		clkfx_divide => dfs_div,
		clkfx_multiply => dfs_mul,
		clkin_period => dcm_per,
		dfs_frequency_mode => "HIGH",
		startup_wait => FALSE)
	port map (
		rst   => dfsdcm_rst,
		clkfb => dfs_clkfb,
		clkin => dfsdcm_clkin,
		clk0  => dfs_clk0,
		clkfx => dfs_clkfx,
		locked => dfs_lckd);
   
	dfs_clkfxbufg_i : bufg
	port map (
		i => dfs_clkfx,
		o => dcm_clkin);
   
	dfs_clk0bufg_i : bufg
	port map (
		i => dfs_clk0,
		o => dfs_clkfb);
   
	process (dfsdcm_rst, dcm_clkin)
		variable q : std_logic_vector(0 to 4-1);
	begin
		if dfsdcm_rst='1' then
			q := (others => '1');
			dcm_rst <= q(0);
		elsif rising_edge(dcm_clkin) then
			q := q(1 to q'right) & not dfs_lckd;
			dcm_rst <= q(0);
		end if;
	end process;

	dcm_i : dcm_base
	generic map (
		clkin_period => (real(dfs_div)*dcm_per)/real(dfs_mul),
		dll_frequency_mode => "HIGH")
	port map (
		rst   => dcm_rst,
		clkin => dcm_clkin,
		clkfb => dcm_clkfb,
		clk0  => dcm_clk0,
		clk90 => dcm_clk90,
		locked => dcm_lckd);
   
	process (dfsdcm_rst, dcm_clkfb)
		variable q : std_logic_vector(0 to 4-1);
	begin
		if dfsdcm_rst='1' then
			q := (others => '0');
			dfsdcm_lckd <= q(0);
		elsif rising_edge(dcm_clkfb) then
			q := q(1 to q'right) & dcm_lckd;
			dfsdcm_lckd <= q(0);
		end if;
	end process;

	clk0_bufg_i : bufg
	port map (
		i => dcm_clk0,
		o => dcm_clkfb);
   
	dfsdcmclk90_bufg_i : bufg
	port map (
		i => dcm_clk90,
		o => dfsdcm_clk90);

	dfsdcm_clk0 <= dcm_clkfb;
end;
