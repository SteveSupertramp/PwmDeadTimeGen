------------------------------------------------------------------------------
--	Project :		ENDAT_SSI
--	File name :		Endat.vhd
--	Title/Code :    xxxxx
--  Description:	Bidirectional Synchronous-Serial Interface for Position Encoders					
------------------------------------------------------------------------------
--	Revisions History :
--	Author			Date		Revision	Comments
	
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- ENTITY --------------------------------------------------------------------

entity SM_TopBot is
    generic(regsize :   integer:=8);
	port(  	
       	CLK 			: in  	std_logic;	        		-- clock 20Mhz	
		nRST 			: in  	std_logic; 					-- reset 
        ENA             : in    std_logic;                  -- abilitazione    

		TOPP_IN			: in  	std_logic;	       			-- IGBT cmd TOP Positive   		
		TOPN_IN			: in  	std_logic;	        		-- IGBT cmd TOP Negative   		
		BOTP_IN			: in  	std_logic;	       			-- IGBT cmd BOT Positive   		
		BOTN_IN			: in  	std_logic;	        		-- IGBT cmd BOT Negative 
		
		DELAY			: in	std_logic_vector(regsize-1 downto 0);   -- Selezioni ritardo comandi

		TOPP_OUT		: out  	std_logic;	       			-- IGBT cmd TOP Positive   		
		TOPN_OUT		: out  	std_logic;	        		-- IGBT cmd TOP Negative   		
		BOTP_OUT		: out  	std_logic;	       			-- IGBT cmd BOT Positive   		
		BOTN_OUT		: out  	std_logic	        		-- IGBT cmd BOT Negative   		

	);	                                   
end entity;                              
                                          
architecture BEHAVIOR of SM_TopBot is    

    -- CONSTANTS -----------------------------------------------------------------
    constant LOW 						: std_logic := '0';
    constant HIGH						: std_logic := '1';
    constant REGWIDTH                   : integer := 8;
    constant CNTWIDTH                   : integer := 8;  
    constant RESET_ACTIVE 				: std_logic := '0';
    constant TIMEOUT 					: std_logic_vector (REGWIDTH-1 downto 0) := x"C8";		-- timeout 10 usec	

    -- SIGNALS -------------------------------------------------------------------
    signal r_edge_TOPP		:	std_logic   := '0';		-- impulso 1 clk rileva fronte salita su  TOP  Pos
    signal f_edge_TOPP		:	std_logic   := '0';		-- impulso 1 clk rileva fronte discesa su TOP Pos
    signal r_edge_TOPN		:	std_logic   := '0';	    -- impulso 1 clk rileva fronte salita su  TOP  Neg
    signal f_edge_TOPN		:	std_logic   := '0';		-- impulso 1 clk rileva fronte discesa su TOP Neg
    signal r_edge_BOTP		:	std_logic   := '0';		-- impulso 1 clk rileva fronte salita su  BOT  Pos
    signal f_edge_BOTP		:	std_logic   := '0';		-- impulso 1 clk rileva fronte discesa su BOT Pos
    signal r_edge_BOTN		:	std_logic   := '0';		-- impulso 1 clk rileva fronte salita su  BOT  Neg
    signal f_edge_BOTN		:	std_logic   := '0';		-- impulso 1 clk rileva fronte discesa su BOT Neg

    signal Cr_edge_TOPP		:	std_logic;		-- impulso 1 clk rileva fronte salita su  TOP  Pos
    signal Cf_edge_TOPN		:	std_logic;		-- impulso 1 clk rileva fronte discesa su TOP Neg
    signal Cr_edge_BOTP		:	std_logic;		-- impulso 1 clk rileva fronte salita su  BOT  Pos
    signal Cf_edge_BOTN		:	std_logic;		-- impulso 1 clk rileva fronte discesa su BOT Neg

    signal START_CNT		:   std_logic := '0';
    signal QCNT  			:   std_logic_vector (CNTWIDTH-1 downto 0);	 
    signal nCNT_RST 		:	std_logic := '1';	
    signal nRST_global		:   std_logic;

    -- state signals for target state machine 
    type	StateType is (TOP_BOT_OFF,	
                          TOP_ON_BOT_OFF,
                          TOP_OFF_BOT_ON,
                          WAIT_BOT_ON, 			  
                          WAIT_TOP_ON,
                          DELAY_BOT_ON,
                          DELAY_TOP_ON);			  
                                              
    signal 	 CURRENT_STATE, NEXT_STATE   : StateType; 

    -- COMPONENTS ----------------------------------------------------------------    
    component FedgeDetect is 
        Port (	CLK    	: in  STD_LOGIC;  
                EN		: in  STD_LOGIC;	
                nRST    : in  STD_LOGIC;
                CH_IN  	: in  STD_LOGIC;
                CH_OUT 	: out  STD_LOGIC
            );
    end component;

    component RedgeDetect is
        Port (	CLK    	: in  STD_LOGIC;  
                EN		: in  STD_LOGIC;	
                nRST    : in  STD_LOGIC;
                CH_IN  	: in  STD_LOGIC;
                CH_OUT 	: out  STD_LOGIC
            );	
    end component;

    component COUNTER is
        generic (size: integer := 8);
        -- ports
        port( 
            -- Inputs
            nRST     	: in  std_logic;  
            CLK     	: in  std_logic;
            EN        	: in  std_logic;
            START		: in  std_logic;
            STOP		: in  std_logic;	
            -- Outputs
            COUNT  		: out std_logic_vector (size-1 downto 0)            
        );
    end component;

-- PROCESSES -----------------------------------------------------------------
begin

    nRST_global <= nRST and nCNT_RST;	

    U1: RedgeDetect
        port map(	
                CLK    	=>		CLK, 
                EN		=>		ENA,
                nRST    =>		nRST,
                CH_IN  	=>		TOPP_IN,
                CH_OUT 	=>		r_edge_TOPP		
        );

    U2: FedgeDetect
        port map(	
                CLK    	=>		CLK, 
                EN		=>		ENA,	
                nRST    =>		nRST,
                CH_IN  	=>		TOPP_IN,
                CH_OUT 	=>		f_edge_TOPP		
        );

    U3: RedgeDetect
        port map(	
                CLK    	=>		CLK, 
                EN		=>		ENA,	
                nRST    =>		nRST,
                CH_IN  	=>		TOPN_IN,
                CH_OUT 	=>		r_edge_TOPN		
        );

    U4: FedgeDetect
        port map(	
                CLK    	=>		CLK, 
                EN		=>		ENA,
                nRST    =>		nRST,
                CH_IN  	=>		TOPN_IN,
                CH_OUT 	=>		f_edge_TOPN		
        );

    U5: RedgeDetect
        port map(	
                CLK    	=>		CLK,  
                EN		=>		ENA,
                nRST    =>		nRST,
                CH_IN  	=>		BOTP_IN,
                CH_OUT 	=>		r_edge_BOTP		
        );

    U6: FedgeDetect
        port map(	
                CLK    	=>		CLK, 
                EN		=>		ENA,
                nRST    =>		nRST,
                CH_IN  	=>		BOTP_IN,
                CH_OUT 	=>		f_edge_BOTP		
        );

    U7: RedgeDetect
        port map(	
                CLK    	=>		CLK, 
                EN		=>		ENA,
                nRST    =>		nRST,
                CH_IN  	=>		BOTN_IN,
                CH_OUT 	=>		r_edge_BOTN		
        );

    U8: FedgeDetect
        port map(	
                CLK    	=>		CLK,
                EN		=>		ENA,
                nRST    =>		nRST,
                CH_IN  	=>		BOTN_IN,
                CH_OUT 	=>		f_edge_BOTN		
        );

    U9: COUNTER 				-- contatore 8 bit
        generic map(CNTWIDTH)
        port map(	
                nRST    => 		nRST_global,	
                CLK 	=>    	CLK,
                EN      =>		START_CNT,
                START   =>      HIGH,
                STOP    =>      LOW,
                COUNT	=>		QCNT  
        );

        	
    R_EDGE_TOPP_PROC: process(CLK,nRST)
    begin
        if (nRST = RESET_ACTIVE) then
            Cr_edge_TOPP <= LOW;
        elsif(rising_edge(CLK)) then 
                Cr_edge_TOPP <= r_edge_TOPP and not(BOTP_IN) and BOTN_IN;  
        end if;
    end process;

    F_EDGE_TOPN_PROC: process(CLK,nRST)
    begin
        if (nRST = RESET_ACTIVE) then
            Cf_edge_TOPN <= LOW;
        elsif(rising_edge(CLK)) then 
                Cf_edge_TOPN <= f_edge_TOPN and not(BOTP_IN) and BOTN_IN; 
        end if;
    end process;

    R_EDGE_BOTP_PROC: process(CLK,nRST)
    begin
        if (nRST = RESET_ACTIVE) then
            Cr_edge_BOTP <= LOW;
        elsif(rising_edge(CLK)) then 
                Cr_edge_BOTP <= r_edge_BOTP and not(TOPP_IN) and TOPN_IN;  -- genera impulso se TOP spento  
        end if;
    end process;

    F_EDGE_BOTN_PROC: process(CLK,nRST)
    begin
        if (nRST = RESET_ACTIVE) then
            Cf_edge_BOTN <= LOW;
        elsif(rising_edge(CLK)) then 
                Cf_edge_BOTN <= f_edge_BOTN and not(TOPP_IN) and TOPN_IN;  -- genera impulso se TOP spento 
        end if;
    end process;

    -- control state machine 
    SYNC_PROC: process (CLK, nRST)
    begin
        if (nRST = RESET_ACTIVE) then
            CURRENT_STATE <= TOP_BOT_OFF;
        elsif (rising_edge(CLK)) then
            CURRENT_STATE <= NEXT_STATE;				
        end if;
    end process;

    COMB_PROC: process (CLK) 
    begin
        if(falling_edge(CLK)) then
            
            case CURRENT_STATE is
        
                -- TOP_BOT_OFF 
                when TOP_BOT_OFF =>	 
            
                    START_CNT	<=  LOW;			-- disabilita contatore 	 
                    nCNT_RST	<=  LOW;
                            
                    TOPP_OUT	<=  	LOW	;   		
                    TOPN_OUT	<=		HIGH;	 	-- IGBT TOP  SPENTO    		
                    BOTP_OUT	<=		LOW;   		
                    BOTN_OUT	<=  	HIGH;		-- IGBT BOT  SPENTO  		
                                    
                    if((Cr_edge_TOPP = HIGH) and (Cf_edge_TOPN = HIGH)) then 
                        
                        nCNT_RST	<=  HIGH;		-- TOGLIE RESET DA COUNTER
                        TOPP_OUT	<=  HIGH;   		
                        TOPN_OUT	<=	LOW;	 	-- IGBT TOP  ACCESO    		
                        BOTP_OUT	<=  LOW;   		
                        BOTN_OUT	<=	HIGH;	 	-- IGBT BOT  SPENTO    						
                        NEXT_STATE <= TOP_ON_BOT_OFF; 	
                    else
                        if((Cr_edge_BOTP = HIGH)  and (Cf_edge_BOTN = HIGH)) then				
                        
                            nCNT_RST	<=  HIGH;		-- TOGLIE RESET DA COUNTER
                            BOTP_OUT	<=  HIGH;   		
                            BOTN_OUT	<=	LOW;	 	-- IGBT BOT  ACCESO  
                            TOPP_OUT	<=  LOW;   		
                            TOPN_OUT	<=	HIGH;	 	-- IGBT TOP  SPENTO    						
                            NEXT_STATE 	<=  TOP_OFF_BOT_ON; 							
                        else
                            NEXT_STATE 	<=  TOP_BOT_OFF; 			
                        end if;											

                    end if;	
        
                -- TOP_ON_BOT_OFF          
                when TOP_ON_BOT_OFF =>

                    TOPP_OUT	<=  	HIGH;   		
                    TOPN_OUT	<=		LOW;	 	-- IGBT TOP  ACCESO    		
                    BOTP_OUT	<=		LOW;   		
                    BOTN_OUT	<=  	HIGH;		-- IGBT BOT  SPENTO  		

                    START_CNT	<=  LOW;			-- disabilita contatore 	 
                    nCNT_RST	<=  LOW;
                    
                    -- Testa se è arrivato un comando di spegnimento per IGBT TOP    
                    if ((f_edge_TOPP = HIGH)  and (r_edge_TOPN = HIGH)) then				
                        TOPP_OUT	<=  LOW;   		
                        TOPN_OUT	<=	HIGH;	 		-- IGBT TOP  SPENTO 
                        START_CNT	<=  HIGH;			-- START contatore attesa intervallo 	 
                        nCNT_RST	<=  HIGH;                    
                        NEXT_STATE <= 	WAIT_BOT_ON;  	
                    else
                        if(
                            ((BOTP_IN = HIGH) and (BOTN_IN = LOW))  or    -- Comando accensione BOT 
                            ((TOPP_IN = HIGH) and (TOPN_IN = HIGH)) or    -- Condizione fault su TOP
                            ((TOPP_IN = LOW)  and (TOPN_IN = LOW))        -- Condizione fault su TOP 
                        ) then	 
                            NEXT_STATE <= TOP_BOT_OFF; 	
                        else
                            NEXT_STATE <= TOP_ON_BOT_OFF;
                        end if;	 							        						
                    end if;	 	
            
                -- TOP_OFF_BOT_ON          
                when TOP_OFF_BOT_ON => 

                    TOPP_OUT	<=  	LOW;   		
                    TOPN_OUT	<=		HIGH;	 	-- IGBT TOP  SPENTO    		
                    BOTP_OUT	<=		HIGH;   		
                    BOTN_OUT	<=  	LOW;		-- IGBT BOT  ACCESO  		

                    START_CNT	<=  LOW;			-- disabilita contatore 	 
                    nCNT_RST	<=  LOW;

                    -- Testa se è arrivato un comando di spegnimento per IGBT BOT                 
                    if ((f_edge_BOTP = HIGH) and (r_edge_BOTN = HIGH)) then
                    
                        BOTP_OUT	<=  LOW;   		
                        BOTN_OUT	<=	HIGH;	 		-- IGBT BOT  SPENTO  
                        NEXT_STATE <= 	WAIT_TOP_ON;  	
                    else
                        if(
                            ((TOPP_IN = HIGH) and (TOPN_IN = LOW)) or    -- Comando accensione TOP 
                            ((BOTP_IN = HIGH) and (BOTN_IN = HIGH)) or   -- Condizione fault su BOT
                            ((BOTP_IN = LOW)  and (BOTN_IN = LOW))       -- Condizione fault su BOT
                        ) then	 
                            NEXT_STATE <= TOP_BOT_OFF; 	
                        else
                            NEXT_STATE <= TOP_OFF_BOT_ON;
                        end if;	 												
                    end if;	 	

                -- WAIT_BOT_ON          
                when WAIT_BOT_ON => 

                    TOPP_OUT	<=  	LOW;   		
                    TOPN_OUT	<=		HIGH;	 	-- IGBT TOP  SPENTO    		
                    BOTP_OUT	<=		LOW;   		
                    BOTN_OUT	<=  	HIGH;		-- IGBT BOT  SPENTO   	

                    nCNT_RST	<=  HIGH;
                    START_CNT	<=  HIGH;			-- abilita contatore 	 
                
                    if(QCNT < TIMEOUT) then
                        if((Cr_edge_BOTP = HIGH) and (Cf_edge_BOTN = HIGH)) then  -- accensione IGBT BOT
                            NEXT_STATE  <= DELAY_BOT_ON;
                            START_CNT	<=  LOW;
                            nCNT_RST	<=  LOW;
                        else
                            if((TOPP_IN = HIGH) and (TOPN_IN = LOW)) then
                                nCNT_RST	<=  LOW;
                                START_CNT	<=  LOW;						-- spegne tutto se vede 	 
                                NEXT_STATE  <=  TOP_ON_BOT_OFF;				-- i comandi di accensione del TOP attivi
                            else
                                NEXT_STATE  <=  WAIT_BOT_ON;					
                            end if;				    	
                        end if;		
                    else								-- non è arrivato nessun comando di accensione BOT
                        START_CNT	<=  LOW;
                        nCNT_RST	<=  LOW;
                        NEXT_STATE <= TOP_BOT_OFF;			
                        end if;
                   
                -- WAIT_TOP_ON          
                when WAIT_TOP_ON => 

                    TOPP_OUT	<=  	LOW;   		
                    TOPN_OUT	<=		HIGH;	 	-- IGBT TOP  SPENTO    		
                    BOTP_OUT	<=		LOW;   		
                    BOTN_OUT	<=  	HIGH;		-- IGBT BOT  SPENTO   		

                    nCNT_RST	<=  HIGH;
                    START_CNT	<=  HIGH;			-- abilita contatore 	 
                
                    if(QCNT < TIMEOUT) then
                        if ((Cr_edge_TOPP = HIGH) and (Cf_edge_TOPN = HIGH)) then  -- accensione IGBT TOP
                            NEXT_STATE  <=  DELAY_TOP_ON;
                            START_CNT	<=  LOW ;
                            nCNT_RST	<=  LOW;
                        else
                            if((BOTP_IN = HIGH) and (BOTN_IN = LOW)) then
                                nCNT_RST	<=  LOW;
                                START_CNT	<=  LOW;					-- disabilita contatore 	 
                                NEXT_STATE  <=  TOP_OFF_BOT_ON;
                            else
                                NEXT_STATE  <=  WAIT_TOP_ON;					
                            end if;				    	
                        end if;		
                    else								-- non è arrivato nessun comando di accensione TOP
                        START_CNT	<=  LOW;
                        nCNT_RST	<=  LOW;
                        NEXT_STATE <= TOP_BOT_OFF;			
                    end if;

                -- DELAY_BOT_ON          
                when DELAY_BOT_ON => 

                    START_CNT	<=  HIGH ;
                    nCNT_RST	<=  HIGH; 
                
                    if (QCNT >= DELAY) then			-- se è trascorso il delay comando l'IGBT BOT 
                        NEXT_STATE 	<= TOP_OFF_BOT_ON;
                        START_CNT	<=  LOW; 
                        nCNT_RST	<=  LOW; 
                    else
                        if((BOTP_IN = LOW) and (BOTN_IN = HIGH)) then 
                            NEXT_STATE 	<= TOP_BOT_OFF;
                        else
                            NEXT_STATE 	<= DELAY_BOT_ON;
                        end if;							 					        		
                    end if;

                -- DELAY_TOP_ON          
                when DELAY_TOP_ON => 

                    START_CNT	<=  HIGH ;
                    nCNT_RST	<=  HIGH; 
                
                    if (QCNT >= DELAY) then			-- se è trascorso il delay comando l'IGBT TOP 
                        NEXT_STATE 	<= TOP_ON_BOT_OFF;
                        START_CNT	<=  LOW;
                        nCNT_RST	<=  LOW;
                    else
                        if((TOPP_IN = LOW) and (TOPN_IN = HIGH)) then 
                            NEXT_STATE 	<= TOP_BOT_OFF;
                        else
                            NEXT_STATE 	<= DELAY_TOP_ON;
                        end if;							 					        		
                    end if;

    --		 	when others =>
    --					NEXT_STATE 	<= TOP_BOT_OFF;
                
            end case;
        end if;	
    end process;

end BEHAVIOR;		
	
