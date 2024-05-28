*-----------------------------------------------------------
* Title      : PRAFIN24
* Written by : Quintana Benitez, David // Ortiz García, Alex
* Date       : 26/05/2024
* Description: Emulador de la SUIBC
*-----------------------------------------------------------
    ORG $1000
MEM: DC.W $A00C,$00A0,$7002,$5000,$A80D,$00A0,$4420,$63FD 
     DC.W $00A0,$2060,$800E,$C000,$0003,$0004,$0000
EIR: DC.W 0 ;eregistro de instruccion
EPC: DC.W 0 ;econtador de programa
ER0: DC.W 0 ;eregistro R0
ER1: DC.W 0 ;eregistro R1
ER2: DC.W 0 ;eregistro R2
ER3: DC.W 0 ;eregistro R3
ESR: DC.W 0 ;eregistro de estado (00000000 00000ZNC)


START:

    CLR.W EPC   ;ESTABLECE EL EPC A 0

FETCH:
    ;--- IFETCH: INICIO FETCH
        ;*** En esta seccion debeis introducir el codigo necesario para cargar
        ;*** en el EIR la siguiente instruccion a ejecutar, indicada por el EPC,
	    ;*** y dejar listo el EPC para que apunte a la siguiente instruccion
	
	        ; ESCRIBID VUESTRO CODIGO AQUI           
    MOVE.W  EPC,A0  ;MOVER VALOR DE EPC A A 0  
    ADD.W   A0,A0   ;ADAPTAR A TAMAÑO WORD
    MOVE.W  EMEM(A0),EIR   ;PASAR EL CONTENIDO DE EMEM EN LA POSICIÓN A0 A D0
    ADDQ.W  #1,EPC  ;INCREMENTAR EN 1 EL EPC
    
    ;--- FFETCH: FIN FETCH
    
    ;--- IBRDECOD: INICIO SALTO A DECOD
        ;*** En esta seccion debeis preparar la pila para llamar a la subrutina
        ;*** DECOD, llamar a la subrutina, y vaciar la pila correctamente,
        ;*** almacenando el resultado de la decodificacion en D1

    	    ; ESCRIBID VUESTRO CODIGO AQUI    	    
IBRDECOD:
    ;--- FBRDECOD: FIN SALTO A DECOD
    SUBQ.L  #2,A7       ;RESERVAR ESPACIO PARA NÚMERO DE SALTO
    MOVE.W  EIR,-(A7)   ;INSTRUCCIÓN A DECODIFICAR
    JSR DECOD
    ADDQ.L  #2,A7       
    MOVE.W  (A7)+,D1  ;D1 = VALOR DE SALTO
    
    
    
    ;--- IBREXEC: INICIO SALTO A FASE DE EJECUCION
        ;*** Esta seccion se usa para saltar a la fase de ejecucion
        ;*** NO HACE FALTA MODIFICARLA
    MULU #6,D1
    MOVEA.L D1,A1
    JMP JMPLIST(A1)
JMPLIST:
    JMP ESTO
    JMP ELOA
    JMP ECMP
    JMP EADD
    JMP ESUB
    JMP ENOR
    JMP ESET
    JMP EADQ
    JMP ETRA
    JMP EJMZ
    JMP EJMN
    JMP EJMI
    JMP EHLT
    ;--- FBREXEC: FIN SALTO A FASE DE EJECUCION
    
    ;--- IEXEC: INICIO EJECUCION
        ;*** En esta seccion debeis implementar la ejecucion de cada einstr.
	
	; ESCRIBID EN CADA ETIQUETA LA FASE DE EJECUCION DE CADA INSTRUCCION
	
ESTO:   ;0 - STORE
        ;STO Rj, M
        ;M <-- [Rj]
        ;INSTRUCCIÓN QUE PERMITE ALMACENAR EL CONTENIDO DE Rj EN 
        ;LA POSICIÓN DE MEMORIA M
        ;CODIFICACIÓN = 100 X JXXX MMMMMMMM
        ;NO SE ACTUALIZAN LOS FLAGS
    
    MOVE.W  EIR,D0  ;D0 = EIR
    
    ;PREPARACIÓN DE SUBRUTINA MEM_DECOD_1
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA POSICIÓN M  
    MOVE.W  D0,-(A7)   ;INSTRUCCIÓN A DECODIFICAR POSICIÓN M   
    JSR MEM_DECOD_1
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,A2    ;POSICIÓN M
    
    ADD.L   A2,A2   ;ADAPTAR A WORD
    
    ;VERIFICAR A QUE REGISTRO SE ACCEDE
    BTST    #11,D0
    BEQ REG_01

    REG_11: ;REGISTRO R1
        MOVE.W  ER1,EMEM(A2)
        JMP SKIP_S

    REG_01: ;REGISTRO R0
        MOVE.W  ER0,EMEM(A2)
    
    SKIP_S:
        JMP FETCH
    
ELOA:   ;1 - LOAD
        ;LOA Rj,M
        ;Rj <-- [M]
        ;INSTRUCCIÓN QUE PERMITE ALMACENAR EL CONTENIDO EN LA
        ;POSICIÓN DE MEMORIA M EN EL EREGISTRO Rj
        ;CODIFICACIÓN = 101 X J XXX MMMMMMMM
        ;C = NO SE ACTUALIZA, Z/N = SE ACTUALIZAN
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR    
    
    ;PREPARACIÓN DE SUBRUTINA MEM_DECOD_1
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA POSICIÓN M     
    MOVE.W  D0,-(A7)   ;INSTRUCCIÓN A DECODIFICAR POSICIÓN M
    JSR MEM_DECOD_1
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,A2    ;POSICIÓN M
    
    ADD.L   A2,A2   ;ADAPTAR A WORD 
    
    ;PREPARACIÓN SUBRUTINA FLAGS_2
    MOVE.W  D2,-(A7)    ;ESR
    MOVE.W  EMEM(A2),-(A7)  ;VALOR A VERIFICAR
    JSR FLAGS_2
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,ESR   ;ACTUALIZAR VALOR ESR
    
    ;VERIFICAR A QUE REGISTRO SE ALMACENA
    BTST    #11,D0
    BEQ REG_02    
    
    REG_12: ;REGISTRO R1
        MOVE.W  EMEM(A2),ER1
        JMP SKIP_L

    REG_02: ;REGISTRO R0
        MOVE.W  EMEM(A2),ER0
    
    SKIP_L:
        JMP FETCH
    
ECMP:   ;2 - COMPARE
        ;CMP Ra,Rj
        ;[Rj] - [Ra]
        ;INSTRUCCIÓN QUE REALIZA LA DIFERENCIA ENTRE EL
        ;CONTENIDO DE LOS EREGISTROS Rj y Ra, ESTA DIFERENCIA
        ;PERMITE MODIFICAR LOS FLAGS, NO ALMACENA EL VALOR EN 
        ;NINGÚN REGISTRO NI ESPACIO DE MEMORIA
        ;CODIFICACIÓN = 010000 XXX J AA XXXX
        ;Z/N/C = SE ACTUALIZAN
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D4 = Rj
    ;PREPARACIÓN SUBRUTINA REG_LOA_1
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO EN Rj
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO Rj
    JSR REG_LOA_1
    ADDQ.L  #2,A7
    
    MOVE.W  (A7)+,D4

    ;EXTENDER EL SIGNO DE Rj
    EXT.L   D4    
     
    ;D5 = Ra    
    ;PREPARACIÓN SUBRUTINA REG_LOA_2
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO EN Ra
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO Ra
    JSR REG_LOA_2
    ADDQ.L  #2,A7
        
    MOVE.W  (A7)+,D5  

    ;EXTENDER EL SIGNO DE Ra
    EXT.L   D5    
         
    ;REALIZAR OPERACIÓN
    NOT D5
    ADDQ.W  #1,D5
    EXT.L   D5  ;EXTENDER SIGNO DE Ra
    ADD.L   D5,D4   ;Rj + (Ra' + 1)
    
    ;PREPARACIÓN SUBRUTINA FLAGS_1
    MOVE.W  D2,-(A7)    ;ESR
    MOVE.L  D4,-(A7)    ;VALOR A VERIFICAR
    JSR FLAGS_1
    ADDQ.L  #4,A7
    MOVE.W  (A7)+,ESR   ;ACTUALIZAR VALOR ESR

    
    JMP FETCH
    
EADD:   ;3 - ADD
        ;ADD Ra,Rj
        ;Rj <-- [Rj] + [Ra]
        ;INSTRUCCIÓN QUE REALIZA LA SUMA ENTRE EL CONTENIDO DE 
        ;LOS EREGISTRO Rj Y Ra, EL RESULTADO SE ALMACENA
        ;EN Rj
        ;CODIFICACIÓN = 010001 XXX J AA XXXX
        ;Z/N/C = SE ACTUALIZAN
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D4 = Rj
    ;PREPARACIÓN SUBRUTINA REG_LOA_1
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO DE Rj
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    JSR REG_LOA_1
    ADDQ.L  #2,A7
    
    MOVE.W  (A7)+,D4
    
    ;EXTENDER EL SIGNO DE Rj
    EXT.L   D4
    
    ;D5 = Ra
    ;PREPARACIÓN SUBRUTINA REG_LOA_2
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO DE Ra
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    JSR REG_LOA_2
    ADDQ.L  #2,A7
        
    MOVE.W  (A7)+,D5
    
    ;EXTENDER EL SIGNO DE Ra
    EXT.L   D5
    
    ;REALIZAR OPERACIÓN    
    ADD.L   D5,D4   ;Rj <- Rj + Ra
            
    ;PREPARACIÓN SUBRUTINA FLAGS_1
    MOVE.W  D2,-(A7)    ;ESR
    MOVE.L  D4,-(A7)    ;VALOR A VERIFICAR
    JSR FLAGS_1
    ADDQ.L  #4,A7
    MOVE.W  (A7)+,ESR   ;ACTUALIZAR VALOR ESR
    
    ;PREPARACIÓN SUBRUTINA REG_STO_1
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    MOVE.W  D4,-(A7)    ;VALOR A ALMACENAR
    JSR REG_STO_1
    ADDQ.L  #4,A7        
    
    JMP FETCH
    
ESUB:   ;4 - SUBSTRACT
        ;SUB Ra,Rj
        ;Rj <-- [Rj] - [Ra]
        ;INSTRUCCIÓN QUE REALIZA LA DIFERENCIA ENTRE EL CONTENIDO DE 
        ;LOS EREGISTRO Rj Y Ra, EL RESULTADO SE ALMACENA
        ;EN Rj
        ;CODIFICACIÓN = 010010 XXX J AA XXXX
        ;Z/N/C = SE ACTUALIZAN
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D4 = Rj
    ;PREPARACIÓN SUBRUTINA REG_LOA_1
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO DE Rj
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    JSR REG_LOA_1
    ADDQ.L  #2,A7
    
    MOVE.W  (A7)+,D4
    
    ;EXTENDER EL SIGNO DE Rj
    EXT.L   D4
    
    ;D5 = Ra
    ;PREPARACIÓN SUBRUTINA REG_LOA_2
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO DE Ra
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    JSR REG_LOA_2
    ADDQ.L  #2,A7
        
    MOVE.W  (A7)+,D5
    
    ;EXTENDER EL SIGNO DE Ra
    EXT.L   D5
        
    ;REALIZAR OPERACIÓN
    NOT.W   D5
    ADDQ.W  #1,D5
    ADD.L   D5,D4   ;Rj <- Rj + (Rb' + 1)
    
    ;PREPARACIÓN SUBRUTINA FLAGS_1
    MOVE.W  D2,-(A7)    ;ESR
    MOVE.L  D4,-(A7)    ;VALOR A VERIFICAR
    JSR FLAGS_1
    ADDQ.L  #4,A7
    MOVE.W  (A7)+,ESR   ;ACTUALIZAR VALOR ESR
    
    ;PREPARACIÓN SUBRUTINA REG_STO_1
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    MOVE.W  D4,-(A7)    ;VALOR A ALMACENAR
    JSR REG_STO_1
    ADDQ.L  #4,A7
    
    JMP FETCH
    
ENOR:   ;5 - NOT OR
        ;NOR Ra,Rj
        ;Rj <-- [Rj] nor [Ra]
        ;INSTRUCCIÓN QUE REALIZA LA OPERACIÓN LÓGICA NOR ENTRE
        ;EL CONTENIDO DE LOS EREGISTRO Rj Y Ra, EL RESULTADO
        ;SE ALMACENA EN Rj
        ;CODIFICACIÓN = 010011 XXX J AA XXXX
        ;C = NO SE ACTUALIZA, Z/N = SE ACTUALIZAN
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D4 = Rj
    ;PREPARACIÓN SUBRUTINA REG_LOA_1
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO DE Rj
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    JSR REG_LOA_1
    ADDQ.L  #2,A7
    
    MOVE.W  (A7)+,D4
    
    ;EXTENDER EL SIGNO DE Rj
    EXT.L   D4
    
    ;D5 = Ra
    ;PREPARACIÓN SUBRUTINA REG_LOA_2
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO DE Ra
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    JSR REG_LOA_2
    ADDQ.L  #2,A7
        
    MOVE.W  (A7)+,D5
    
    ;EXTENDER EL SIGNO DE Ra
    EXT.L   D5

    ;REALIZAR OPERACIÓN
    OR  D5,D4
    NOT D4  ;Rj <- (Rj ^ Ra)'

    ;PREPARACIÓN SUBRUTINA FLAGS_2
    MOVE.W  D2,-(A7)    ;ESR
    MOVE.W  D4,-(A7)    ;VALOR A VERIFICAR    
    JSR FLAGS_2
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,ESR   ;ACTUALIZAR VALOR ESR
    
    ;PREPARACIÓN SUBRUTINA REG_STO_1
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    MOVE.W  D4,-(A7)    ;VALOR A ALMACENAR
    JSR REG_STO_1
    ADDQ.L  #4,A7
            
    JMP FETCH
    
ESET:   ;6 - SET
        ;SET #c,Rb
        ;Rb <-- c
        ;INSTRUCCIÓN QUE PERMITE ALMACENAR UNA CONSTANTE DENTRO
        ;DEL EREGISTRO Rb
        ;CODIFICACIÓN = 0101 XX CCCCCCCC BB
        ;C = NO SE ACTUALIZA, Z/N = SE ACTUALIZAN
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D4 = c
    ;PREPARACIÓN SUBRUTINA CONSTANT_DECOD
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONSTANTE CODIFICADA
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR CONSTANTE
    JSR CONSTANT_DECOD
    ADDQ.L  #2,A7
    
    MOVE.W  (A7)+,D4
    
    ;EXTENDER EL SIGNO DE LA CONSTANTE
    EXT.L   D4
    
    ;PREPARACIÓN SUBRUTINA FLAGS_2
    MOVE.W  D2,-(A7)    ;ESR
    MOVE.W  D4,-(A7)    ;VALOR A VERIFICAR
    JSR FLAGS_2
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,ESR   ;ACTUALIZAR VALOR ESR
    
    ;PREPARACIÓN SUBRUTINA REG_STO_2
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    MOVE.W  D4,-(A7)    ;VALOR A ALMACENAR
    JSR REG_STO_2
    ADDQ.L  #4,A7    
    
    JMP FETCH
    
EADQ:   ;7 - ADD QUICK
        ;ADQ #c,Rb
        ;Rb <-- [Rb] + c
        ;INSTRUCCIÓN QUE REALIZA LA SUMA ENTRE EL CONTENIDO 
        ;DEL EREGISTRO Rb Y UNA CONSTANTE CODIFICADA EN LA
        ;MISMA INSTRUCCIÓN
        ;CODIFICACIÓN = 0110 XX CCCCCCCC BB
        ;Z/N/C = SE ACTUALIZAN
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D4 = Rb
    ;PREPARACIÓN SUBRUTINA REG_LOA_3
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO DE Rb
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    JSR REG_LOA_3
    ADDQ.L  #2,A7
    
    MOVE.W  (A7)+,D4
    
    ;D5 = c
    ;PREPARACIÓN SUBRUTINA CONSTANT_DECOD
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONSTANTE CODIFICADA
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR CONSTANTE
    JSR CONSTANT_DECOD
    ADDQ.L  #2,A7
    
    MOVE.W  (A7)+,D5
    
    ;EXTENDER EL SIGNO DE LA CONSTANTE
    EXT.L   D5
    
    ;REALIZAR OPERACIÓN
    ADD.L   D5,D4   ;Rb <- Rb + c
       
    ;PREPARACIÓN SUBRUTINA FLAGS_1
    MOVE.W  D2,-(A7)    ;ESR
    MOVE.L  D4,-(A7)    ;VALOR A VERIFICAR
    JSR FLAGS_1
    ADDQ.L  #4,A7
    MOVE.W  (A7)+,ESR   ;ACTUALIZAR VALOR DE ESR
    
    ;PREPARACIÓN SUBRUTINA REG_STO_2
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    MOVE.W  D4,-(A7)    ;VALOR A ALMACENAR
    JSR REG_STO_2
    ADDQ.L  #4,A7
    
    JMP FETCH
    
ETRA:   ;8 - TRANSFER
        ;TRA Ra,Rb
        ;Rb <-- [Ra]
        ;INSTRUCCIÓN QUE PERMITE MOVER EL CONTENIDO DEL EREGISTRO
        ;Ra AL EREGISTRO Rb
        ;CODIFICACIÓN = 0111 XXXXXX AAXX BB
        ;C = NO SE ACTUALIZA, Z/N = SE ACTUALIZA
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D5 = Ra
    ;PREPARACIÓN SUBRUTINA REG_LOA_2
    SUBQ.L  #2,A7   ;ESPACIO RESERVADO PARA CONTENIDO DE Ra
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    JSR REG_LOA_2
    ADDQ.L  #2,A7
    
    MOVE.W  (A7)+,D5
    
    ;EXTENDER EL SIGNO DE Rq
    EXT.L   D5
    
    ;D4 = Rb
    ;OPERACIÓN A REALIZAR
    MOVE.L  D5,D4   ;Rb <- Ra
    
    ;PREPARACIÓN SUBRUTINA FLAGS_2
    MOVE.W  D2,-(A7)    ;ESR
    MOVE.W  D4,-(A7)    ;VALOR A VERIFICAR
    JSR FLAGS_2
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,ESR   ;ACTUALIZAR VALOR ESR

    ;PREPARACIÓN REG_STO_2
    MOVE.W  D0,-(A7)    ;INSTRUCCIÓN A DECODIFICAR REGISTRO
    MOVE.W  D4,-(A7)    ;VALOR A ALMACENAR
    JSR REG_STO_2
    ADDQ.L  #4,A7
    
    JMP FETCH
    
EJMZ:   ;9 - JUMP IF Z
        ;JMZ M
        ;If Z = 1, EPC <-- M
        ;INSTRUCCIÓN QUE REALIZA UN SALTO A LA POSICIÓN DE MEMORIA M
        ;SI EL FLAG Z ESTÁ ACTIVADO (Z = 1)
        ;CODIFICACIÓN = 0000 MMMMMMMM XXXX
        ;NO SE ACTUALIZAN LOS FLAGS
    
    MOVE.W  EIR,D0  ;D0 = EIR
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D3 = M
    ;PREPARACIÓN SUBRUTINA MEM_DECOD_2
    SUBQ.L  #2,A7
    MOVE.W  D0,-(A7)
    JSR MEM_DECOD_2
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,D3
    
    ;VERIFICAR VALOR DE FLAG Z
    BTST    #2,D2
    BEQ SKIP2
    
    MOVE.W  D3,EPC  ;ACTUALIZAR EPC CON VALOR EN D3
        
    SKIP2:
        JMP FETCH
    
EJMN:   ;10 - JUMP IF N
        ;JMZ N
        ;If N = 1, EPC <-- M
        ;INSTRUCCIÓN QUE RELIZA UN SALTO A LA POSICIÓN DE MEMORIA M
        ;SI EL FLAG N ESTÁ ACTIVADO (N = 1)
        ;CODIFICACIÓN = 0001 MMMMMMMM XXXX
        ;NO SE ACTUALIZAN LOS FLAGS
    
    MOVE.W  EIR,D0  ;D0 = INSTRUCCIÓN
    MOVE.W  ESR,D2  ;D2 = ESR
    
    ;D3 = M
    ;PREPARACIÓN SUBRUTINA MEM_DECOD_2
    SUBQ.L  #2,A7
    MOVE.W  D0,-(A7)
    JSR MEM_DECOD_2
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,D3
    
    ;VERIFICAR VALOR DE FLAG N
    BTST    #1,D2
    BEQ SKIP3
    
    MOVE.W  D3,EPC  ;ACTUALIZAR EPC CON VALOR EN D3     
    
    SKIP3:    
        JMP FETCH
    
EJMI:   ;11 - INCONDITIONAL JUMP
        ;JMI M
        ;EPC <-- M
        ;INSTRUCCIÓN QUE REALIZA UN SALTO A LA POSICIÓN DE MEMORIA M
        ;CODIFICACIÓN = 0010 MMMMMMMM XXXX
        ;NO SE ACTUALIZAN LOS FLAGS
    
    MOVE.W  EIR,D0  ;D0 = EIR
    
    ;D3 = M
    ;PREPARACIÓN SUBRUTINA MEM_DECOD_2
    SUBQ.L  #2,A7
    MOVE.W  D0,-(A7)
    JSR MEM_DECOD_2
    ADDQ.L  #2,A7
    MOVE.W  (A7)+,D3
    
    MOVE.W  D3,EPC  ;ACTUALIZAR EPC CON VALOR EN D3
    
    JMP FETCH
    
EHLT:   ;12 - HALT
        ;HLT
        ;INSTRUCCIÓN QUE DETIENE LA MÁQUINA
        ;CODIFICACIÓN = 11 XXXXXXXXXXXXXX
       
    SIMHALT
    
    ;--- FEXEC: FIN EJECUCION
    
    

    ;--- ISUBR: INICIO SUBRUTINAS
        ;*** Aqui debeis incluir las subrutinas que necesite vuestra solucion
        ;*** SALVO DECOD, que va en la siguiente seccion

	        ; ESCRIBID VUESTRO CODIGO AQUI
   
MEM_DECOD_1:    ;SUBRUTINA DE LIBRERÍA QUE PERMITE OBTENER
                ;LA DIRECCIÓN A CARGAR/GUARDAR (LOA/STO)

    MOVE.L  D0,-(A7)    ;D0 = INSTRUCCIÓN
    MOVE.W  8(A7),D0
    
    AND.W   #$00FF,D0   
    MOVE.W  D0,10(A7)
    
    MOVE.L  (A7)+,D0 
    RTS
    
MEM_DECOD_2:    ;SUBRUTINA DE LIBRERÍA QUE PERMITE OBTENER
                ;LA DIRECCIÓN A ALMACENAR EN EL EPC (JMZ, JMN, JMI)
                
    MOVE.L  D0,-(A7)
    MOVE.W  8(A7),D0    ;D0 = INSTRUCCIÓN
    
    AND.W   #$0FF0,D0
    LSR.W   #4,D0
    MOVE.W  D0,10(A7)
    
    MOVE.L  (A7)+,D0
    RTS

REG_LOA_1:      ;SUBRUTINA DE LIBRERÍA QUE PERMITE OBTENER
                ;EL VALOR DEL REGISTRO CODIFICADO J(CMP, ADD, SUB, NOR)
   
    MOVE.L  D0,-(A7)
    MOVE.W  8(A7),D0    ;D0 = INSTRUCCIÓN

    BTST #6,D0
    BEQ J_0  

    J_1: ;REGISTRO ER1
        MOVE.W  ER1,10(A7)
        JMP SKIP_SR1 
        
    J_0: ;REGISTRO ER0
        MOVE.W  ER0,10(A7)

    SKIP_SR1:
        MOVE.L  (A7)+,D0
        RTS                  
    
REG_LOA_2:      ;SUBRUTINA DE LIBRERÍA QUE PERMITE OBTENER
                ;EL VALOR DEL REGISTRO CODIFICADO AA(CMP, ADD, SUB, NOR, TRA)
                
    MOVE.L  D0,-(A7)
    MOVE.W  8(A7),D0    ;D0 = INSTRUCCIÓN
    
    BTST #5,D0
    BEQ A_101
    
    ;ÁRBOL DE CODIFICACIÓN PARA Ra    
    A_321:
        BTST #4,D0
        BEQ A_21
            
        A_31:    ;REGISTRO ER3
            MOVE.W  ER3,10(A7)
            JMP SKIP_SR2
                
        A_21:    ;REGISTRO ER2
            MOVE.W  ER2,10(A7)
            JMP SKIP_SR2
                
    A_101:   
        BTST #4,D0
        BEQ A_01
            
        A_11:    ;REGISTRO ER1
            MOVE.W  ER1,10(A7)
            JMP SKIP_SR2
                
        A_01:    ;REGISTRO ER0
            MOVE.W  ER0,10(A7)
               
    SKIP_SR2:
        MOVE.L  (A7)+,D0
        RTS

REG_LOA_3:  ;SUBRUTINA DE LIBRERÍA QUE PERMITE OBTENER
            ;EL VALOR DEL REGISTRO CODIFICADO BB (SET, ADQ, TRA)
    
    MOVE.L  D0,-(A7)
    MOVE.W  8(A7),D0    ;D0 = INSTRUCCIÓN
    
    BTST #1,D0
    BEQ B_101
    
    ;ÁRBOL DE CODIFICACIÓN PARA Rb    
    B_321:
        BTST #0,D0
        BEQ B_21
            
        B_31:    ;REGISTRO ER3
            MOVE.W  ER3,10(A7)
            JMP SKIP_SR3
                
        B_21:    ;REGISTRO ER2
            MOVE.W  ER2,10(A7)
            JMP SKIP_SR3
                
    B_101:   
        BTST #4,D0
        BEQ B_01
            
        B_11:    ;REGISTRO ER1
            MOVE.W  ER1,10(A7)
            JMP SKIP_SR3
                
        B_01:    ;REGISTRO ER0
            MOVE.W  ER0,10(A7)
               
    SKIP_SR3:
        MOVE.L  (A7)+,D0
        RTS
        
REG_STO_1:  ;SUBRUTINA DE LIBRERÍA QUE PERMITE ALMACENAR
            ;EL VALOR AL REGISTRO CODIFICADO J(ADD, SUB, NOR) 
    
    MOVE.L  D0,-(A7)
    MOVE.W  10(A7),D0   ;D0 = INSTRUCCIÓN

    BTST    #6,D0
    BEQ J_01  

    J_11: ;REGISTRO ER1
        MOVE.W  8(A7),ER1  
        JMP SKIP_SR4
        
    J_01: ;REGISTRO ER0
        MOVE.W  8(A7),ER0

    SKIP_SR4:
        MOVE.L  (A7)+,D0
        RTS       
       
REG_STO_2:  ;SUBRUTINA DE LIBRERÍA QUE PERMITE ALMACENAR 
            ;EL VALOR AL REGISTRO CODIFICADO B(SET, ADQ, TRA)
                
    MOVE.L  D0,-(A7)
    MOVE.W  10(A7),D0    ;D0 = INSTRUCCIÓN

    BTST #1,D0
    BEQ B_102
    
    ;ÁRBOL DE CODIFICACIÓN PARA Rb    
    B_322:   ;REGISTROS ER3 Y ER2
        BTST #0,D0
        BEQ B_22
            
        B_32:    ;REGISTRO ER3
            MOVE.W  8(A7),ER3
            JMP SKIP_SR5
                
        B_22:    ;REGISTRO ER2
            MOVE.W  8(A7),ER2
            JMP SKIP_SR5
                
    B_102:   ;REGISTROS ER1 Y ER0
        BTST #0,D0
        BEQ B_02
            
        B_12:    ;REGISTROS ER1
            MOVE.W  8(A7),ER1
            JMP SKIP_SR5
                
        B_02:    ;REGISTROS ER0
            MOVE.W  8(A7),ER0
    
    SKIP_SR5:
        MOVE.L  (A7)+,D0
        RTS

CONSTANT_DECOD: ;SUBRUTINA DE LIBRERÍA QUE DECODIFICA LA CONSTANTE
                ;CODIFICADA DENTRO DE LA INSTRUCCIÓN
   
    MOVE.L  D0,-(A7)
    MOVE.W  8(A7),D0   ;D0 = INSTRUCCIÓN
    
    AND.W   #$03FC,D0   ;#$03FC = 0000 0011 1111 1100
    LSR.W   #2,D0       ;DESPLAZAR LA MÁSCARA DOS BITS A LA DERECHA
    EXT.W   D0          ;EXTENDER SIGNO DE CONSTANTE
    MOVE.W  D0,10(A7)
    
    MOVE.L  (A7)+,D0
    RTS          
        
FLAGS_1:        ;SUBRUTINA DE LIBRERÍA QUE VERIFICA SI SE TIENE
                ;QUE ACTIVAR ALGÚN FLAG (ZNC)
                
    MOVE.L  D0,-(A7)
    MOVE.L  D2,-(A7)
    MOVE.L  12(A7),D0   ;D0 = VALOR A VERIFICAR
    MOVE.W  16(A7),D2   ;D2 = ESR
    
    FLAGZ:   ;VERIFICACIÓN FLAG Z
        CMP.W   #0,D0   ;COMPARAR VALOR CON 0
        BEQ UPDZ
    
        BCLR    #2,D2   ;Z = 0
        JMP FLAGN
    
        UPDZ:
            BSET    #2,D2   ;Z = 1
    
    FLAGN:  ;VERIFICACIÓN FLAG N
        BTST    #15,D0  ;VERIFICAR EL VALOR DEL BIT 15 (BIT MÁS SIGNIFICATIVO)
        BNE UPDN

        BCLR    #1,D2   ;N = 0
        JMP FLAGC

        UPDN:
            BSET    #1,D2   ;N = 1
        
    FLAGC:  ;VERIFICACIÓN FLAG C
        BTST  #16,D0    ;VERIFICAR EL VALOR DEL BIT 16 
                        ;(1 BIT MAYOR AL TAMAÑO WORD)
        BNE UPDC
        
        BCLR    #0,D2   ;C = 0
        JMP SKIP_SR6

        UPDC:
            BSET    #0,D2   ;C = 1 
            
    SKIP_SR6:
        MOVE.W  D2,16(A7)
        MOVE.L  (A7)+,D2
        MOVE.L  (A7)+,D0
        RTS
        
FLAGS_2:        ;SUBRUTINA DE LIBRERÍA QUE VERIFICA SI SE TIENE
                ;QUE ACTIVAR ALGÚN FLAG (ZN)(LOA, NOR, SET, TRA)
                
    MOVE.L  D0,-(A7)
    MOVE.L  D2,-(A7)
    MOVE.W  12(A7),D0   ;D0 = VALOR A VERIFICAR
    MOVE.W  14(A7),D2   ;D2 = ESR
    
    FLAGZ1:   ;VERIFICACIÓN FLAG Z
        CMP.W   #0,D0   ;COMPARAR VALOR CON 0
        BEQ UPDZ1
    
        BCLR    #2,D2   ;Z = 0
        JMP FLAGN1
    
        UPDZ1:
            BSET    #2,D2   ;Z = 1
    
    FLAGN1:  ;VERIFICACIÓN FLAG N
        BTST    #15,D0  ;VERIFICAR EL VALOR DEL BIT 15 (BIT MÁS SIGNIFICATIVO)
        BNE UPDN1

        BCLR    #1,D2   ;N = 0
        JMP SKIP_SR7

        UPDN1:
            BSET    #1,D2   ;N = 1 
            
    SKIP_SR7:
        MOVE.W  D2,14(A7)
        MOVE.L  (A7)+,D2
        MOVE.L  (A7)+,D0
        RTS
             
    ;--- FSUBR: FIN SUBRUTINAS
    
    ;--- IDECOD: INICIO DECOD
        ;*** Tras la etiqueta DECOD, debeis implementar la subrutina de 
        ;*** decodificacion, que debera ser de libreria, siguiendo la interfaz
        ;*** especificada en el enunciado
        
DECOD:
	        ; ESCRIBID VUESTRO CODIGO AQUI
    
    MOVE.L  D0,-(A7)    
    MOVE.L  D2,-(A7)    
    SUBQ.L  #2,A7       ;ESPACIO RESERVADO PARA NÚMERO DE SALTO
    MOVE.W  14(A7),D0   ;D0 = INSTRUCCIÓN
    MOVE.W  #15,D2      ;D2 = NÚMERO DE BIT A TESTEAR (MSB BIT = 15)
    BTST.L  D2,D0       ;BTST.L #15,D0
    BEQ B0
    
    B1:
        SUBQ.L  #1,D2   ;D2 = 14
        BTST.L  D2,D0   ;BTST.L #14,D0
        BEQ B10
        
    B11:    ;EHLT
        MOVE.W  #12,0(A7) 
        JMP ENDROUT
        
    B10:
        SUBQ.L  #1,D2   ;D2 = 13
        BTST.L  D2,D0   ;BTST.L #13,D0
        BEQ B100

    B101:   ;ELOA
        MOVE.W  #1,0(A7)
        JMP ENDROUT
        
    B100:   ;ESTO                
        MOVE.W  #0,0(A7) 
        JMP ENDROUT
    
    B0:
        SUBQ.L  #1,D2   ;D2 = 14
        BTST.L  D2,D0   ;BTST.L #14,D0
        BEQ B00
        
    B01:
        SUBQ.L  #1,D2   ;D2 = 13
        BTST.L  D2,D0   ;BTST.L #13,D0
        BEQ B010
    
    B011:
        SUBQ.L  #1,D2   ;D2 = 12
        BTST.L  D2,D0   ;BTST.L #12,D0
        BEQ B0110
        
    B0111:  ;ETRA
        MOVE.W  #8,0(A7) 
        JMP ENDROUT
        
    B0110:  ;EADQ
        MOVE.W  #7,0(A7)
        JMP ENDROUT
        
    B00:    
        SUBQ.L  #1,D2   ;D2 = 13
        BTST.L  D2,D0   ;BTST.L #13,D0
        BEQ B000
        
    B001:   ;EJMI
        MOVE.W  #11,0(A7) 
        JMP ENDROUT
        
    B010:
        SUBQ.L  #1,D2   ;D2 = 12
        BTST.L  D2,D0   ;BTST.L #12,D0
        BEQ B0100
        
    B0101:  ;ESET
        MOVE.W  #6,0(A7) 
        JMP ENDROUT
        
    B000:
        SUBQ.L  #1,D2   ;D2 = 12
        BTST.L  D2,D0   ;BTST.L  #12,D0
        BEQ B0000
        
    B0001: ;EJMN
        MOVE.W  #10,0(A7)
        JMP ENDROUT
        
    B0000: ;EJMZ
        MOVE.W  #9,0(A7) 
        JMP ENDROUT
        
    B0100:
        SUBQ.L  #1,D2   ;D2 = 11
        BTST.L  D2,D0   ;BTST.L  #11,D0
        BEQ B01000
    
    B01001:
        SUBQ.L  #1,D2   ;D2 = 10
        BTST.L  D2,D0   ;BTST.L  #10,D0
        BEQ B010010
      
    B010011:    ;ENOR
        MOVE.W  #5,0(A7) 
        JMP ENDROUT
        
    B010010:    ;ESUB
        MOVE.W  #4,0(A7) 
        JMP ENDROUT
        
    B01000:
        SUBQ.L  #1,D2   ;D2 = 10
        BTST.L  D2,D0   ;BTST.L  #10,D0
        BEQ B010000
        
    B010001:    ;EADD
        MOVE.W  #3,0(A7) 
        JMP ENDROUT
        
    B010000:    ;ECMP
        MOVE.W  #2,0(A7) 
        
    ENDROUT:   ;ENDROUT
        MOVE.W  0(A7),16(A7)
        
        ADDQ.L  #2,A7           
        MOVE.L  (A7)+,D2 
        MOVE.L  (A7)+,D0               
        RTS
    ;--- FDECOD: FIN DECOD
    
    END    START







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
