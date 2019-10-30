library ieee;
use ieee.std_logic_1164.all;

	-- Add your library and packages declaration here ...

entity tb_i2c_slave is
end tb_i2c_slave;

architecture behavioral of tb_i2c_slave is
	-- Component declaration of the tested unit
	component i2c_slave
	port(
		CLK     : in STD_LOGIC;
		nRST    : in STD_LOGIC;
		SCL     : in STD_LOGIC;
		SDA     : inout STD_LOGIC;
		SDA_dir : buffer STD_LOGIC;
		REGDEL  : out STD_LOGIC_VECTOR(0 to 7) );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal 	CLK 	    : STD_LOGIC;
	signal 	nRST 	    : STD_LOGIC;
	signal 	SCL 	    : STD_LOGIC;
	signal 	SDA 	    : STD_LOGIC;	  
	signal 	SDA_node	: STD_LOGIC;  
	signal 	SDA_dir   	: STD_LOGIC;  	   
	signal 	READ_DATA 	: STD_LOGIC_VECTOR(0 to 7) := "00000000";	
	signal 	SDA_in 	 	: STD_LOGIC; 
	signal	REGDEL 		: STD_LOGIC_VECTOR(0 to 7);

					
	-- Observed signals - signals mapped to the output ports of tested entity
 
	CONSTANT WRITE			: STD_LOGIC := '0';								-- scrittura su bus I2C
	CONSTANT READ			: STD_LOGIC := '1';								-- lettura su bus I2C
	CONSTANT DEV_ADR		: STD_LOGIC_VECTOR(0 to 6) := "1000101";		-- indirizzo I2C dispositivo
	CONSTANT WR_DATA		: STD_LOGIC_VECTOR(0 to 7) := "01100100";		-- dato scritto su dispositivo I2C	
	CONSTANT CLK_PERIOD  	: time :=  50 nS;  							    -- 20 MHz 	
	CONSTANT tHD_STA  		: time :=  4  uS;  		-- SCL hold time START condition	
	CONSTANT tSCL  			: time :=  10 uS;  		-- periodo minimo SCL (100 Khz)	
    CONSTANT tSCL_H         : time :=  4 uS;  		-- durata minima SCL a livello alto
    CONSTANT tSCL_L         : time :=  6 uS;        -- durata massima SCL a livello basso    
	CONSTANT tSU_DAT		: time :=  1 uS;		-- Tempo set-up SDA	
	CONSTANT tHD_DAT		: time :=  1 uS;		-- Tempo Hold SDA	
	CONSTANT tSU_STO		: time :=  1 uS;		-- Tempo setup SCL nella condione di STOP 	
	
begin

	-- Unit Under Test port map
	UUT : i2c_slave
		port map (
			CLK => CLK,
			nRST => nRST,
			SCL => SCL,
			SDA => SDA,
			SDA_dir => SDA_dir,
			REGDEL => REGDEL
		);

-- create clock 10MHz process 
CREATE_CLK : process
begin
	CLK <= '0';
	wait for CLK_PERIOD/2;
	CLK <= '1';
	wait for CLK_PERIOD/2;
end process;

RESET:	process
begin		
		nRST  	<= '0' ;	  	
		wait for 1us;
		nRST  	<= '1' ;	
		wait ; 
end process;

with  SDA_dir select
	SDA		<=	SDA_node	when	'0',
				'Z'			when	'1',
				'-'			when  others;
	

GEN_PATTERN: process  

variable i: 	INTEGER    := 0;
variable ack:	STD_LOGIC  := '1';

begin
	
	SCL			<= '1';
	SDA_node	<= '1';	
	
	wait until nRST'event and nRST = '1';
		
	wait for 10us;
		
	SDA_node	<= '0';						   	-- Genera condizione di START su I2C
		
	wait for tHD_STA;		  
		
	for i in 0 to 6 loop				   		-- Genera indirizzo dispositivo I2C  
		SCL <= '0';	
		wait for (tSCL_L-tSU_DAT);				-- Tempo di attesa prima di trasmettere bit di indirizzo
		SDA_node <= DEV_ADR(i);			
		wait for (tSU_DAT); 
		SCL <= '1'; 
		wait for tSCL_H;                        -- Tempo in cui la linea di clock rimane alta   
	end  loop;
		
	SCL <= '0';	
	wait for (tSCL_L-tSU_DAT);				    -- Tempo di attesa prima di trasmettere bit di R/W
	SDA_node <= WRITE;							--  Scrittura su bus I2C		
	wait for (tSU_DAT); 
	SCL <= '1'; 
	wait for (tSCL_H); 
		
	SCL <= '0';		                            -- Clock pulse of ACK bit
	wait for tSCL_L;   			   
	SCL <= '1';
	        
	if(SDA = '0') then
		ack := '0';					-- Acknowledge OK 
	else
		ack := '1';					-- NOT Acknowledge
		SDA_node <= '0';			-- messo a zero per produrre condizione di stop
	end if;
	
	wait for tSCL_H; 
					
	if(ack = '1') then				-- genera condione di STOP su bus I2C	
		wait for tSCL_L;
		SCL <= '1';					-- Riporto alto la linea di clock SCL
			
		wait for tSU_STO;			-- evento di stop
		SDA_node <= '1';
	else
   		SCL <= '0';					-- Riporto bassa la linea di clock SCL

		for i in 0 to 7 loop				   			-- Invia dato da scrivere  
        	wait for (tSCL_L-tSU_DAT);
			SDA_node <= WR_DATA(i);			
			wait for (tSU_DAT); 
			SCL <= '1'; 
            wait for (tSCL_H); 
			SCL <= '0';
		end  loop; 
						
		wait for tSCL_L;				-- Attende ACK da dispositivo I2C   			   
		SCL <= '1';

		if(SDA = '0') then
			ack := '0';					-- Acknowledge OK 
		else
			ack := '1';					-- NOT Acknowledge
		end if;
				
     	wait for tSCL_H;
		SCL	<= '0';
		SDA_node <= '0';					
		wait for tSCL_L;			
		SCL <= '1';
		wait for tSU_STO;
		SDA_node <= '1';			
	end if;	
					
	SCL <= '1';
   	SDA_node <= '1';
	   			
	wait for 10 uS;
 
    SDA_node	<= '0';						   	-- Genera condizione di START su I2C
		
	wait for tHD_STA;		  

	for i in 0 to 6 loop				   		-- Genera indirizzo dispositivo I2C  
		SCL <= '0';	
		wait for (tSCL_L-tSU_DAT);				-- Tempo di attesa prima di trasmettere bit di indirizzo
		SDA_node <= DEV_ADR(i);			
		wait for tSU_DAT; 
		SCL <= '1'; 
		wait for tSCL_H;                        -- Tempo in cui la linea di clock rimane alta   
	end  loop;

	SCL <= '0';	
	wait for (tSCL_L-tSU_DAT);				    -- Tempo di attesa prima di trasmettere bit di R/W
	SDA_node <= READ;							--  Scrittura su bus I2C		
	wait for tSU_DAT; 
	SCL <= '1'; 
	wait for tSCL_H; 
    
	SCL <= '0';		                            -- Clock pulse of ACK bit
	wait for tSCL_L;   			   
	SCL <= '1';
	        
	if(SDA = '0') then
		ack := '0';					-- Acknowledge OK 
	else
		ack := '1';					-- NOT Acknowledge
		SDA_node <= '0';			-- messo a zero per produrre condizione di stop
	end if;
  
    wait for tSCL_H; 
  
	if(ack = '1') then				-- genera condione di STOP su bus I2C	
		wait for tSCL_L;
		SCL <= '1';					-- Riporto alto la linea di clock SCL
			
		wait for tSU_STO;			-- evento di stop
		SDA_node <= '1';
	else
   		SCL <= '0';					-- Riporto bassa la linea di clock SCL    
		for i in 0 to 7 loop				   	-- Invia dato da scrivere  
            wait for tSCL_L;				    -- Tempo di attesa prima di trasmettere bit di indirizzo
			SCL  <= '1';
			READ_DATA(0 to 6) <= READ_DATA(1 to 7);
			READ_DATA(7) <= SDA;
			wait for tSCL_H;
			SCL <= '0';
		end  loop; 
	
		SDA_node	<= '0';				-- Fornisce ACK allo slave
		SCL <= '0';		
		wait for tSCL_L;				-- Attende ACK da dispositivo I2C   			   
		SCL <= '1';
		wait for tSCL_H;				-- Attende ACK da dispositivo I2C   			   
		SCL <= '0';
		wait for tSCL_L;				-- Attende ACK da dispositivo I2C   			   
		SCL <= '1';
		wait for tSCL_H;				-- Attende ACK da dispositivo I2C   			   
        
		wait for tSU_STO;
		SDA_node <= '1';	
	
	end if;	
		
end process;		

end behavioral;



