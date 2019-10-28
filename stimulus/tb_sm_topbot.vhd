library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

	-- Add your library and packages declaration here ...

entity tb_sm_topbot is
end tb_sm_topbot;

architecture behavioral of tb_sm_topbot is

	-- Constant declaration of the tested unit
    CONSTANT HIGH           : std_logic := '1';
    CONSTANT LOW            : std_logic := '0';    
	CONSTANT CLK_PERIOD  	: time :=  50 ns;  		-- 20 MHz 	
	CONSTANT DEAD_TIME  	: time :=  20 us; 
    CONSTANT REGWIDTH       : integer := 8;    
	CONSTANT DELAY_TIME  	: std_logic_vector(REGWIDTH-1 downto 0) := X"50" ; 	
	CONSTANT PWM_PERIOD  	: time :=  125 us; 	
	CONSTANT PWM_TOP_ON  	: time :=  50  us; 	
	CONSTANT PWM_TOP_OFF  	: time :=  PWM_PERIOD - PWM_TOP_ON; 
        
	-- Component declaration of the tested unit
	component sm_topbot
    generic (regsize: integer := 8);
	port(
		CLK         :   in STD_LOGIC;
		nRST        :   in STD_LOGIC;
        ENA         :   in STD_LOGIC;
		TOPP_IN     :   in STD_LOGIC;
		TOPN_IN     :   in STD_LOGIC;
		BOTP_IN     :   in STD_LOGIC;
		BOTN_IN     :   in STD_LOGIC;
		DELAY       :   in STD_LOGIC_VECTOR(regsize-1 downto 0);
		TOPP_OUT    :   out STD_LOGIC;
		TOPN_OUT    :   out STD_LOGIC;
		BOTP_OUT    :   out STD_LOGIC;
		BOTN_OUT    :   out STD_LOGIC );
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal CLK  : STD_LOGIC;
	signal nRST : STD_LOGIC;
	signal ENA  : STD_LOGIC;    
	signal TOPP_IN : STD_LOGIC;
	signal TOPN_IN : STD_LOGIC;
	signal BOTP_IN : STD_LOGIC;
	signal BOTN_IN : STD_LOGIC;
	signal DELAY   : STD_LOGIC_VECTOR(REGWIDTH-1 downto 0);
	-- Observed signals - signals mapped to the output ports of tested entity
	signal TOPP_OUT : STD_LOGIC;
	signal TOPN_OUT : STD_LOGIC;
	signal BOTP_OUT : STD_LOGIC;
	signal BOTN_OUT : STD_LOGIC;
    
begin

    DELAY <= DELAY_TIME;		

	-- Unit Under Test port map
	UUT : sm_topbot
        generic map(REGWIDTH)
        port map (
			CLK => CLK,
			nRST => nRST,
            ENA  => ENA,
			TOPP_IN => TOPP_IN,
			TOPN_IN => TOPN_IN,
			BOTP_IN => BOTP_IN,
			BOTN_IN => BOTN_IN,
			DELAY => DELAY,
			TOPP_OUT => TOPP_OUT,
			TOPN_OUT => TOPN_OUT,
			BOTP_OUT => BOTP_OUT,
			BOTN_OUT => BOTN_OUT
		);
				
    CREATE_CLK : process
    begin
        CLK <= '0';
        wait for (CLK_PERIOD/2);
        CLK <= '1';
        wait for (CLK_PERIOD/2);
    end process;

    RESET:	process
    begin		
            nRST  <= '0' ;
                        
            wait for 10us;
            nRST  <= '1' ;
            wait ;	-- wait forever			
    end process;   

    EN_PROC:	process
    begin		
            ENA  <= '0' ;
            wait until nRST'event and  nRST=HIGH;
            
            wait for 5 us;
            ENA  <= '1' ;
            wait ;	-- wait forever			
    end process;       
    
    
    -- testbench
    TEST_1 : process  
    variable i:  integer  := 0 ;
    begin 	

        --IGBT BOT spento
        BOTP_IN <= '0' ;	
        BOTN_IN <= '1' ;
        --IGBT TOP spento
        TOPP_IN <= '0' ;	
        TOPN_IN <= '1' ;

--        wait until ENA'event and  ENA=HIGH;
        wait for 50us;
         
        while(i < 100) loop	  
            
            i := i + 1;

            BOTP_IN <= '0' ;	
            BOTN_IN <= '1' ;

            TOPP_IN <= '1' ;	
            TOPN_IN <= '0' ;
                    
            wait for PWM_TOP_ON;		

            TOPP_IN <= '0' ;	
            TOPN_IN <= '1' ;
            
            wait for DEAD_TIME;
                    
            BOTP_IN <= '1' ;
            BOTN_IN <= '0' ;
            
            wait for PWM_TOP_OFF - 2*DEAD_TIME;
                    
            BOTP_IN <= '0' ; 
            BOTN_IN <= '1' ;
            
            wait for DEAD_TIME;		
        end loop;	
    end process;	 
		
end behavioral;
