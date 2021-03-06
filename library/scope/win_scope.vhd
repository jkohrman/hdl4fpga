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

entity win_scope is
	generic (
		num_chann : natural;
		max_hght  : natural := 64);
	port(
		video_clk : in std_logic;

		chann_row : in std_logic_vector;
		chann_col : in std_logic_vector;
		chann_seg : in std_logic_vector;
		chann_dat : in std_logic_vector;

		grid_dot : out std_logic;
		plot_dot : out std_logic_vector);
end;

library hdl4fpga;
use hdl4fpga.std.all;

architecture def of win_scope is
	constant n : natural := unsigned_num_bits(max_hght);
	subtype oword is std_logic_vector(0 to num_chann*n-1);
	constant offset_val : oword := (
		std_logic_vector(unsigned'(
			to_unsigned (max_hght+1, n) &
			to_unsigned (         1, n))));
begin

	grid_e : entity hdl4fpga.grid
	generic map (
		col_div  => "1111",
		col_line => "11",
		row_div  => "1111",
		row_line => "11")
	port map (
		clk => video_clk,
		row => chann_row,
		col => chann_col,
		dot => grid_dot);

	plot_e : entity hdl4fpga.plot
	generic map (
		max_hght => max_hght)
	port map (
		video_clk => video_clk,
		video_row => chann_row,
		video_seg => chann_seg,
		video_off => offset_val,
		chann_dat => chann_dat,
		video_dot => plot_dot);
end;
