-------------------------------------------------------------------------------
--
-- Title       : i2c_slave
-- Design      : PWM_DeadTime
-- Author      : USERKT340
-- Company     : Lattice Semiconductor
--
-------------------------------------------------------------------------------
--
-- File        : i2c_slave.vhd
-- Generated   : Tue Sep  1 11:21:54 2009
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.20
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------

--{{ Section below this comment is automatically maintained
--   and may be overwritten
--{entity {i2c_slave} architecture {i2c_slave}}

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity i2c_slave is
	 port(
		 CLK 		: in 		STD_LOGIC;
		 nRST 		: in 		STD_LOGIC;
		 SCL 		: in 		STD_LOGIC;					-- linea clock bus I2C
		 SDA 		: inout  	STD_LOGIC;					-- linea dato bus I2C 	
		 SDA_dir	: buffer	STD_LOGIC;      	 		-- 0 ingresso ; 1 uscita
		 REGDEL		: out		STD_LOGIC_VECTOR(0 to 7) 	-- registro ritardo
	     );
end i2c_slave;

--}} End of automatically maintained section

architecture i2c_slave of i2c_slave is 

component FedgeDetect is
    Port (	CLK    	: in  STD_LOGIC;
			EN		: in  STD_LOGIC;	
         	nRST    : in  STD_LOGIC;
			CH_IN  	: in  STD_LOGIC;
			CH_OUT 	: out STD_LOGIC
		);
end component;	

component RedgeDetect is
    Port (	CLK    	: in  STD_LOGIC; 
			EN		: in  STD_LOGIC;		
         	nRST    : in  STD_LOGIC;
			CH_IN  	: in  STD_LOGIC;
			CH_OUT 	: out STD_LOGIC
		);
end component;

type  StateType is (IDLE_BUS,
					ACQ_DEV_ADR,
					GEN_ACK, 
					END_ACK,
					RD_DATA,
					WR_DATA,
					WAIT_ACK,
					GEN_ACK_WR,
					STOP_BUS);

					
constant	DEV_ADR			:	STD_LOGIC_VECTOR(6 downto 0)	:= "1000101" ;	 
constant 	LOW 			: 	STD_LOGIC := '0';
constant 	HIGH			: 	STD_LOGIC := '1';
constant 	RESET_ACTIVE 	: 	STD_LOGIC := '0';

signal 	f_edge_SDA		:	STD_LOGIC;		-- impulso sincrono CLK fronte discesa SDA
signal 	r_edge_SDA		:	STD_LOGIC; 		-- impulso sincrono CLK fronte salita  SDA
signal 	r_edge_SCL		:	STD_LOGIC; 		-- impulso sincrono CLK fronte salita  SCL
signal 	f_edge_SCL		:	STD_LOGIC;		-- impulso sincrono CLK fronte doscesa SCL
signal	Rd_nWR 			:	STD_LOGIC;
signal  I2C_address		:	STD_LOGIC_VECTOR(6 downto 0)  := "0000000";	
signal	Delay_reg		:	STD_LOGIC_VECTOR(0 to 7)      := "00000000";    -- Registro ritardo
signal  SDA_out			:   STD_LOGIC;
signal	bits_counter	:   INTEGER := 0;

signal	next_state		:   StateType;
signal	current_state	:   StateType;	 

begin

U1: FedgeDetect
	port map(	
			CLK    	=>	CLK,  
			EN		=>  HIGH,	
         	nRST    =>	nRST,
			CH_IN  	=>	SDA,
			CH_OUT 	=>	f_edge_SDA		
	);
	

U2: RedgeDetect 
	port map(	
			CLK    	=> 	CLK,
			EN		=>  HIGH,	
         	nRST    =>	nRST,
			CH_IN  	=>	SDA,
			CH_OUT 	=>	r_edge_SDA
	);

U3: RedgeDetect 
	port map(	
			CLK    	=> 	CLK,  
			EN		=>  HIGH,	
         	nRST    =>	nRST,
			CH_IN  	=>	SCL,
			CH_OUT 	=>	r_edge_SCL
	);
	
U4: FedgeDetect
	port map(	
			CLK    	=>	CLK, 
			EN		=>  HIGH,	
         	nRST    =>	nRST,
			CH_IN  	=>	SCL,
			CH_OUT 	=>	f_edge_SCL		
	);


with  SDA_dir select
		SDA	<=	'Z'			when  	LOW,		-- configurato come ingresso
				SDA_out  	when 	HIGH,		-- configurato come uscita
				'-' 		when 	others;

-- control state machine 
I2C_SYNC_PROC: process (CLK, nRST)
begin
	if (nRST = RESET_ACTIVE) then
		current_state <= IDLE_BUS;	
	elsif (rising_edge(CLK)) then
		current_state <= next_state;				
	end if;
end process;

SM_I2C_BUS:	process(CLK,nRST) 
begin	
	if(nRST = RESET_ACTIVE) then	 
		next_state <= IDLE_BUS;
	elsif(CLK'event and CLK = '0') then		
			case current_state is
	
			-- IDLE_BUS 
				when IDLE_BUS =>
		
					SDA_dir <= LOW;
					bits_counter  <= 0;
		
					if((f_edge_SDA = HIGH) and (SCL = HIGH)) then	-- condizione di START su bus	 			
						next_state <= ACQ_DEV_ADR; 	
					else
						next_state <= IDLE_BUS; 			
					end if;	
	
		-- ACQ_DEV_ADR : acquisisce indirizzo I2C dispositivo di 7 bits  : MSB first transmitted        
        		when ACQ_DEV_ADR =>

					if(r_edge_SCL = HIGH)  then						-- fronte salita CLK su MSB of DEVICE ADDRESS		 		
						if(bits_counter < 7) then
							I2C_address  <= I2C_address(5 downto 0) & SDA;
							bits_counter <= bits_counter + 1;
  				    		next_state   <= ACQ_DEV_ADR; 					
						else
							bits_counter <= 0;
							Rd_nWR		 <= SDA;
							next_state	 <= GEN_ACK;
						end if;	
	  				else
						next_state <= ACQ_DEV_ADR; 					
					end if;	

		-- GEN_ACK : genera acknowledge verso MASTER           
        		when GEN_ACK =>	
   
					if(f_edge_SCL = HIGH)  then						-- dopo fronte discesa SCL verifica indirizzo		 		
						SDA_dir <= HIGH;							-- Cambia direzione SDA from IN TO OUT			
						if(I2C_address = DEV_ADR) then					
							SDA_out	<= 	LOW;						-- fornisco ACK al MASTER						
						else
							SDA_out	<=  HIGH;						-- non dò ACK al MASTER
						end if;	 				
						next_state  <= END_ACK;													
	  				else
						next_state <= GEN_ACK; 					
					end if;		
		
				when END_ACK =>
		
					if(f_edge_SCL = HIGH)  then							-- dopo fronte discesa SCL verifica indirizzo		 								
						if(SDA_out = LOW) then
							if(Rd_nWR = HIGH) then						-- lettura byte SLAVE						
			  					SDA_dir <= HIGH;						-- Cambia direzione SDA from IN TO OUT			
  								SDA_out <=  Delay_reg(bits_counter);
								bits_counter <= bits_counter + 1;
								next_state   <= RD_DATA;			
							elsif(Rd_nWR = LOW) then					-- scrittura byte SLAVE
				  					SDA_dir <= LOW;						-- Cambia direzione SDA from IN TO OUT										
									next_state  <= WR_DATA;
							end if;	 
						else
							SDA_dir <=	LOW;							-- configuro SDA come ingresso 
							next_state <= STOP_BUS;
						end if;	
					else					
						next_state  <= END_ACK;
					end if;
		
 				when RD_DATA =>
					if(f_edge_SCL = HIGH)  then						-- dopo fronte discesa SCL verifica indirizzo		 						
						if(bits_counter < 8) then
							SDA_out <=  Delay_reg(bits_counter);
							bits_counter <= bits_counter + 1;
							next_state  <= RD_DATA;
						else
							SDA_dir 	<= LOW;						-- SDA passa da OUT a IN
							next_state  <= WAIT_ACK;				-- rimane in attesa dell'ACK dal MASTER
						end if;	
					else
						next_state  <= RD_DATA;			
					end if;	 
		
				when WR_DATA =>	
				
					if(r_edge_SCL = HIGH)  then							-- dopo fronte discesa SCL verifica indirizzo		 									
						if(bits_counter < 8) then
							Delay_reg <= Delay_reg(1 to 7) & SDA;
							bits_counter <= bits_counter + 1;
							next_state  <= WR_DATA;
						end if;
					elsif(f_edge_SCL = HIGH)  then
							if(bits_counter = 8) then 
								SDA_out	<=  LOW;						-- fornisco ACK al MASTER						
								SDA_dir <=  HIGH;						-- Cambia direzione SDA from IN TO OUT			
								next_state  <= GEN_ACK_WR;
							end if;	 	
						else	
							next_state  <= WR_DATA;			
						end if;	 
					
				when WAIT_ACK =>

					if(f_edge_SCL = HIGH)  then						-- dopo fronte discesa SCL verifica indirizzo		 						
						bits_counter <= 0;
						next_state  <= STOP_BUS;
					else
						next_state  <= WAIT_ACK;			
					end if;	 
		
				when GEN_ACK_WR =>

					if(f_edge_SCL = HIGH)  then						-- dopo fronte discesa SCL verifica indirizzo		 		
						SDA_dir <=  LOW;							-- Cambia direzione SDA from IN TO OUT			
						SDA_out	<=  HIGH;							-- fornisco ACK al MASTER						
						REGDEL	<= 	Delay_reg;						-- aggiorno il registro
						next_state	 <= STOP_BUS;
	  				else
						next_state <= GEN_ACK_WR; 					
					end if;				
					
				when STOP_BUS =>	
			
					if((r_edge_SDA = HIGH) and (SCL = HIGH)) then	-- condizione di STOP su bus	 			
						next_state   <= IDLE_BUS;					-- porta macchina a stati in IDLE_BUS 					
	  				else
						next_state <= STOP_BUS;						-- rimane in questo stato fino a quando 					
					end if;											-- vede uno STOP
			end case;
	end if;					
end process;		
end i2c_slave;
