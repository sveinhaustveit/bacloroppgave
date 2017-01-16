library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity spi_master is
Port (
   CLK               :  in     std_logic;
   RESET             :  in     std_logic;
   ONESHOT           :  in     std_logic;
   CONTINOUS         :  in     std_logic;
   TEMP              :  out    std_logic_vector(9 downto 0);
   AI1               :  out    std_logic_vector(9 downto 0);
   AI2               :  out    std_logic_vector(9 downto 0);
   AI3               :  out    std_logic_vector(9 downto 0);
   AI4               :  out    std_logic_vector(9 downto 0);
   REFERENCE         :  out    std_logic_vector(9 downto 0);
   SPI_BUSY          :  buffer std_logic;
   --for å skru på bergnigene
   --math_sense		 :  in     std_logic;
   -- spi interface
   SCLK              :  out    std_logic;
   MOSI              :  out    std_logic;
   MISO              :  in     std_logic;
   CS_N              :  out    std_logic;
   WR_N              :  out    std_logic;
   CONVST_N          :  out    std_logic;
   BUSY              :  in     std_logic;
   OTI_N             :  in     std_logic
   );
end;

Architecture rtl of spi_master is

component spi_driver is
Port (
		clk 			:in 	std_logic;
		reset 			:in 	std_logic;
		data_mosi		:in 	std_logic_vector(7 downto 0);
		data_miso		:out 	std_logic_vector(9 downto 0);
		start_spi 		:in 	std_logic;
		spi_busy		:out	std_logic;
		-- for spi bus interface
		sclk			:out	std_logic := '1';
		mosi			:out	std_logic;
		miso			:in		std_logic;
		cs_n			:out	std_logic;
		wr_n			:out	std_logic;
		convst_n		:out	std_logic := '1';
		busy			:in		std_logic;
		oti_n			:in		std_logic
		);
end component;
signal start_spi, busy_spi,  read_hold, start, hold_clk: std_logic := '0';
signal teller_mosi : std_logic_vector(7 downto 0);
signal data_miso_buffer : std_logic_vector(9 downto 0);
type arrey is array (7 downto 0) of std_logic_vector(9 downto 0);
signal tabell : arrey;
type state is (vent, star, les, ferdig);
signal su_state : state;
Begin
	spi_masten : component spi_driver Port map
	(	clk 		=> clk,
		reset 		=> reset,
		data_mosi 	=> teller_mosi,
		data_miso	=> data_miso_buffer,
		start_spi 	=> start_spi,
		spi_busy 	=> busy_spi,
		-- for spi bus interface
		sclk		=> sclk,
		mosi		=> mosi,
		miso		=> miso,	
		cs_n		=> cs_n,	
		wr_n		=> wr_n,
		convst_n	=> convst_n,	
		busy		=> busy,
		oti_n		=> oti_n);
		
	-- om du vil gjøre om tallene slik at du får rett tempratur og spenning 
	--TEMP	  	<= tabell(0) when math_sense = '0' else std_logic_vector(to_unsigned((to_integer(unsigned(tabell(0)))/4)-103,10)); 
	--AI1       <= tabell(1) when math_sense = '0' else std_logic_vector(to_unsigned(to_integer(unsigned(tabell(1)))/410, 10));          
	--AI2    	<= tabell(2) when math_sense = '0' else std_logic_vector(to_unsigned(to_integer(unsigned(tabell(2)))/410, 10));             
	--AI3    	<= tabell(3) when math_sense = '0' else std_logic_vector(to_unsigned(to_integer(unsigned(tabell(3)))/410, 10));             
	--AI4  	 	<= tabell(4) when math_sense = '0' else std_logic_vector(to_unsigned(to_integer(unsigned(tabell(4)))/410, 10));
	--REFERENCE <= tabell(7) when math_sense = '0' else std_logic_vector(to_unsigned(to_integer(unsigned(tabell(5)))/410, 10));7
	
	TEMP		<= tabell(0); 
	AI1    		<= tabell(1);          
	AI2    		<= tabell(2);             
	AI3  	  	<= tabell(3);             
	AI4  		<= tabell(4);
	REFERENCE 	<= tabell(7);
	
	process(clk, reset)
	begin
		if reset = '1' then
			-- rest ting
			start <= '0';
			spi_busy <= '0';
			teller_mosi <= "00000000";
		elsif rising_edge(clk) then
		--start start
			if oneshot = '1' then
				start <= '1';
			elsif CONTINOUS = '1' then
				start <= '1';
			elsif spi_busy = '1' then
				start <= '0';
			end if;
		--start start
		case su_state is 
			when vent => 
				hold_clk <= '0';
				spi_busy <= '0';
				teller_mosi <= "00000000";
				if start = '1' then
					su_state <= star;
				end if;
			when star =>
				start_spi <= '1';
				spi_busy <= '1';
				if hold_clk = '0' then
					hold_clk <= '1';
				elsif hold_clk = '1' and busy_spi = '0' then
					hold_clk <= '0';
					start_spi <= '0';
					su_state <= les;
				end if;
			when les =>
				if busy_spi = '0' then
					tabell(to_integer(unsigned(teller_mosi)))<= data_miso_buffer;
					teller_mosi <= std_logic_vector(unsigned(teller_mosi)+1);
					if teller_mosi = "00000101" then
						teller_mosi <= "00000111";
						su_state <= star;
					elsif teller_mosi = "00000111" then
						teller_mosi <= "00000000";
						su_state <= ferdig;
					else 
						su_state <= star;
					end if;
				end if;
			when ferdig =>
				if busy_spi = '0' then
					spi_busy <= '0';
					su_state <= vent;
				end if;
			end case;
		end if;
	end process;
End;		


