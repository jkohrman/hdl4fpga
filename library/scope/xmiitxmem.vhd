library ieee;
use ieee.std_logic_1164.all;

entity miitxmem is
	generic (
		bram_size : natural := 9;
		data_size : natural := 32);
	port (
		ddrs_clk   : in  std_logic;
		ddrs_gnt   : in  std_logic;
		ddrs_req   : in  std_logic := '1';
		ddrs_rdy   : out std_logic;
		ddrs_direq : out std_logic;
		ddrs_dirdy : in  std_logic;
		ddrs_di    : in  std_logic_vector(data_size-1 downto 0);

		miitx_clk  : in  std_logic;
		miitx_ena  : in  std_logic := '1';
		miitx_addr : in  std_logic_vector(bram_size-1 downto 0);
		miitx_data : out std_logic_vector(data_size-1 downto 0));
end;

library hdl4fpga;
use hdl4fpga.std.all;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

architecture def of miitxmem is
	constant bram_num : natural := 2;

	subtype aword is std_logic_vector(bram_size-1 downto 0);
	type aword_vector is array(natural range <>) of aword;

	subtype dword is std_logic_vector(data_size-1 downto 0);
	type dword_vector is array(natural range <>) of dword;

	signal addri : std_logic_vector(0 to bram_size-1);
	signal addro : std_logic_vector(0 to bram_size-1);

	signal wr_address : std_logic_vector(0 to bram_size-1);
	signal wr_ena  : std_logic;
	signal wr_data : dword;

	signal rd_address : std_logic_vector(0 to bram_size-1);

begin

	process (ddrs_clk)
		variable addri0_edge : std_logic;
	begin
		if rising_edge(ddrs_clk) then
			addri <= dec (
				cntr => addri,
				ena  => not ddrs_gnt or ddrs_dirdy,
				load => not ddrs_gnt,
				data => 2**bram_size/2-1);

			wr_ena <= ddrs_dirdy;
		end if;
	end process; 

	process (ddrs_clk)
		variable edge : std_logic;
	begin
		if rising_edge(ddrs_clk) then
			if ddrs_gnt='1' then
				if ddrs_req='1' then
					if (addri(0) xor edge)='1' then
						ddrs_rdy   <= '1';
						ddrs_direq <= '0';
					else
						ddrs_direq <= '1';
						ddrs_rdy   <= '0';
					end if;
				else
					ddrs_rdy   <= '0';
					ddrs_direq <= '0';
				end if;
			else
				ddrs_rdy   <= '0';
				ddrs_direq <= '0';
			end if;
			edge := addri(0);
		end if;
	end process;

	wr_address_i : entity hdl4fpga.align
	generic map (
		n => wr_address'length,
		d => (wr_address'range => 1))
	port map (
		clk => ddrs_clk,
		di  => addri(wr_address'range),
		do  => wr_address);

	wr_data_i : entity hdl4fpga.align
	generic map (
		n => ddrs_di'length,
		d => (ddrs_di'range => 1))
	port map (
		clk => ddrs_clk,
		di  => ddrs_di,
		do  => wr_data);

	rd_address_i : entity hdl4fpga.align
	generic map (
		n => rd_address'length,
		d => (rd_address'range => 1))
	port map (
		clk => miitx_clk,
		ena => miitx_ena,
		di  => miitx_addr,
		do  => rd_address);

	bram_e : entity hdl4fpga.dpram
	port map (
		wr_clk => ddrs_clk,
		wr_addr => wr_address, 
		wr_ena => wr_ena,
		wr_data => wr_data,
		rd_clk => miitx_clk,
		rd_ena => miitx_ena,
		rd_addr => rd_address,
		rd_data => miitx_data);
end;