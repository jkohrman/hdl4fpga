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
use ieee.std_logic_textio.all;

use std.textio.all;
library hdl4fpga;
use hdl4fpga.xdr_param.all;

architecture xdr_mpu of testbench is
	constant period : time := 4 ns;

	signal clk : std_logic := '0';
	signal rst : std_logic;
	signal rdy : std_logic;
	subtype cmdword is std_logic_vector(0 to 2);
	type cmdword_vector is array (natural range <>) of cmdword;

	signal cmd : std_logic_vector(0 to 2);
begin
	clk <= not clk after period/2;
	rst <= '1', '0' after 10 ns;

	process (clk)
		variable i : natural := 0;
		constant cmds : cmdword_vector(0 to 2) := ("011", "101", "010");
	begin
		if rst='1' then
			cmd <= cmds(i);
			i := 0;
		elsif rising_edge(clk) then
			if rdy='1' then
				i := (i+1) mod cmdword'length;
				cmd <= cmds(i);
			end if;
		end if;
	end process;

	du : entity hdl4fpga.xdr_mpu
	generic map (
		lRCD => to_xdrlatency(6 ns, M6T, tRCD),
		lRFC => to_xdrlatency(6 ns, M6T, tRFC),
		lWR  => to_xdrlatency(6 ns, M6T, tWR),
		lRP  => to_xdrlatency(6 ns, M6T, tRP),
		bl_cod => xdr_latcod(1, BL),
		bl_tab => xdr_lattab(1, BL),
		cl_cod => xdr_latcod(1, CL),
		cl_tab => xdr_lattab(1, CL),
		cwl_cod => xdr_latcod(1, CWL),
		cwl_tab => xdr_lattab(1, CWL))
	port map (
		xdr_mpu_bl  => "001",
		xdr_mpu_cl  => "011",
		xdr_mpu_cwl => "001",

		xdr_mpu_rst => rst,
		xdr_mpu_clk => clk,
		xdr_mpu_cmd => cmd,
		xdr_mpu_rdy => rdy);

end;