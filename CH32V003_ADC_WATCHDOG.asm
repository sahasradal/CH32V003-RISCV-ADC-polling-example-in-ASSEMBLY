# ANALOG ADC WATCHDOG WORKS FINE, watched area between 600 to 300 adc counts, if beyond these limits watchdog interrupt is triggered and message displayed in UART terminal
# PD4 is ADC channel 7 , PD5 & PD6 USART TX & RX, 
########
fclk = 24000000   	# 24Mhz RCO internal , AHB =8Mhz by default
statusreg = 0x20000004
buffer1 = 0x20000008
state = 0x2000000C
result1 = 0x20000010
result2 = 0x20000014
dividend = 0x20000018 
divisor = 0x2000001C
scratch = 0x20000020
mem = 0x20000024
##########

include ch32v003_reg1.asm


vtable:
	j reset_handler		#  longs 0x00000000 # RESERVED 0
align 4
  longs   0x00000000 # RESERVED 1
  longs   0x00000000 #pack <l longs NMI_IRQhandler
  longs   0x00000000 #pack <l HardFault_IRQhandler
  longs   0x00000000 # RESERVED 4
  longs   0x00000000 # RESERVED 5
  longs   0x00000000 # RESERVED 6
  longs   0x00000000 # RESERVED 7
  longs   0x00000000 # RESERVED 8
  longs   0x00000000 # RESERVED 9
  longs   0x00000000 # RESERVED 10
  longs   0x00000000 # RESERVED 11
  longs   0x00000000 # pack <l SysTick_IRQhandler	#; place the address of the mtime ISR subroutine in the vector table position 7,assembler will store isr address here, longs 0x00000000 # RESERVED 12	
  longs   0x00000000 # RESERVED 13
  longs   0x00000000 #pack <l SW_Software_IRQhandler
  longs   0x00000000 # RESERVED 15
  longs   0x00000000 #pack <l WWDG_IRQhandler
  longs   0x00000000 #pack <l PVD_IRQhandler
  longs   0x00000000 #pack <l FLASH_IRQhandler
  longs   0x00000000 #pack <l RCC_IRQhandler
  longs   0x00000000 #pack <l EXTI7_0_IRQhandler
  longs   0x00000000 #pack <l AWU_IRQhandler
  longs   0x00000000 #pack <l DMA1_CH1_IRQhandler
  longs   0x00000000 #pack <l DMA1_CH2_IRQhandler
  longs   0x00000000 #pack <l DMA1_CH3_IRQhandler
  longs   0x00000000 #pack <l DMA1_CH4_IRQhandler
  longs   0x00000000 #pack <l DMA1_CH5_IRQhandler
  longs   0x00000000 #pack <l DMA1_CH6_IRQhandler
  longs   0x00000000 #pack <l DMA1_CH7_IRQhandler
pack <l ADC1_IRQhandler				# ADC1 interrupt vector
  longs   0x00000000 #pack <l I2C1_EV_IRQhandler
  longs   0x00000000 #pack <l I2C1_ER_IRQhandler
  longs   0x00000000 #pack <l USART1_IRQhandler
  longs   0x00000000 #pack <l SPI1_IRQhandler
  longs   0x00000000 #pack <l TIM1BRK_IRQhandler
  longs   0x00000000 #pack <l TIM1UP_IRQhandler
  longs   0x00000000 #pack <l TIM1TRG_COM_IRQhandler
  longs   0x00000000 #pack <l TIM1CC_IRQhandler
  longs   0x00000000 #pack <l TIM2_IRQhandler

reset_handler:


    	li sp, STACK			# load stack pointer with stack end address
	 
    	li t0, vtable			#BASEADDR[31:2],The interrupt vector table base address,which needs to be 1KB aligned
    	ori t0, t0, 3			#BASEADDR[31:2],1: Identify by absolute address,1: Address offset based on interrupt number *4
    	#csrrw zero,t0, mtvec		# write to mtvec
	longs 0x30529073  
    
   	li t0,main
	longs 0x34129073          	#csrw	mepc,t0 :mepc updated with address of main
	longs 0x30200073		# mret ( return from interrupt)	.
  
	align 4
main:
	nop
	li x10,result1			# clear result1 variable
	sw x0,0(x10)
	li x10,result2			# clear result1 variable
	sw x0,0(x10)
	

#Enable GPIO clocks & AFIO in APB2 clock register
        
    	li x10,R32_RCC_APB2PCENR	# load address of APB2PCENR register to x10 ,for enabling GPIO A,D,C peripherals
	lw x11,0(x10)			# load contents from peripheral register R32_RCC_APB2PCENR pointed by x10
	li x7,((1<<2)|(1<<4)|(1<<5)|(1<<0)|(1<<14))|(1<<9)	# 1<<IOPA_EN,1<<IOPC_EN,1<<IOPD_EN,1<<AFIOEN,1<<USART ,1<<ADC enable port A,C,D and AFIO functions
	or x11,x11,x7			# or values 
	sw x11,0(x10)			# store modified enable values in R32_RCC_APB2PCENR



#configure GPIO 
	li x10,R32_GPIOD_CFGLR		# load pointer x10 with address of R32_GPIOD_CFGLR , GPIO configuration register
	lw x11,0(x10)			# load contents from register pointed by x10
	li x7,~((0xf<<20)|(0xf<<24)|(0xf<<16)|(0xf<<12))	#clear pd4,pd5,pd6. we need to setup PD5 & PD6 for usart tx and rx and pd4 for ADC7
	and x11,x11,x7			# clear pd4,pd5,pd6 mode and cnf bits for selected pin D4,D5,D6
	li x7,(0x8<<24)|(0xB<<20)	# pd6 = input with PU/PD,pd5= multiplex pushpull output 50mhz,pd4 analog input for ADC 0b0000
	or x11,x11,x7			# OR value to register
	sw x11,0(x10)			# store in R32_GPIOD_CFGLR

#configure USART baud
	li x10,R32_USART_BRR		# USART BAUD setting
	lw x11,0(x10)			# copy R32_USART_BRR to x11
	li x7,((52<<4)|(1<<0))		# 52.1 in BRR =9600
	or x11,x11,x7			# or registers
	sw x11,0(x10)			# store in R32_USART_BRR

#setup UART control and enable	
	li x10,R32_USART_CTLR1		# load x10 with R32_USART_CTLR1 address
	lw x11,0(x10)			# load to x11 contents
	li x7,(1<<13)|(1<<3)|(1<<2)	# enable USART UE, TX,RX bits		# UE 
	or x11,x11,x7
	sw x11,0(x10)			# store back new values

#disable ADC before configuration
	li x10,R32_ADC_CTLR2
	lw x11,0(x10)
	li x7,0xfffffffe		#disable ADON bit , 0 written in 0bit
	and x11,x11,x7
	sw x11,0(x10)

#set number of conversions R32_ADC_RSQR1 		# 0 in register is considered as 1 channel conversion


#set sequence of conversion channel
	li x10,R32_ADC_RSQR3		# sequence register, if multiple sensors used we can determine the order of conversion
	lw x11,0(x10)
	li x7,(7<<0)			# AIN7 adc channel is written to sequence 1 (only one channel in this project)	
	or x11,x11,x7
	sw x11,0(x10)

#set sampling cycles
	li x10,R32_ADC_SAMPTR2		# takes sampling cycles for each measurement
	lw x11,0(x10)
	li x7,(7<<21)			# 0b111/0x7 is 241 cycles for ADC channel 7 (PD4)	
	or x11,x11,x7
	sw x11,0(x10)

#enable WD interrupt ,WD single mode,WD regular channel, channel number in ADC contorl register1 
	li x10,R32_ADC_CTLR1
	lw x11,0(x10)
	li x7,(1<<23)|(1<<6)|(1<<9)|(7<<0)	#(1<<23) enable WD for rule channel,(1<<6) analog WD interrupt enable,(1<<9)WD on single channel,(7<<0) channel 7 selected for WD	
	or x11,x11,x7
	sw x11,0(x10)	

#enable high threshold register
	li x10,R32_ADC_WDHTR		# watchdog high threshold register
	li x7,600			# 600 is the max ADC count of safe zone , high threshold	
	sw x7,0(x10)			# store in register

#enable low threshold register
	li x10,R32_ADC_WDLTR		# watchdog low threshold register
	li x7,300			# 400 is the min ADC count of the safe/guarded zone, low threshold	
	sw x7,0(x10)			# store in register

#enable adc trigger ,continues mode and ADON in control register2
	li x10,R32_ADC_CTLR2
	lw x11,0(x10)
	li x7,(1<<0)|(7<<17)|(1<<1)	#7<<17 SWSTART trigger for ADC ,(1<<0) enable ADC- ADON , (1<<1)enable CONT continues mode
	or x11,x11,x7
	sw x11,0(x10)

# Enable ADC interrupt in PFIC interrupt controller(NVIC)
PFIC_CONFIG:
	li x10,R32_PFIC_CFGR		# reset core PFIC register for interrupts (NVIC_IRQ enable)
	lw x11,0(x10)
	li x7,((PFIC_KEY3<<16)|(1<<7))	# key3  and SYSRESET , reference manual tells to do it
	or x11,x11,x7
	sw x11,0(x10)			# store back new values

	li x10,R32_PFIC_IENR1		# PFIC Interrupt Enable in core PFIC
	lw x11,0(x10)
	li x7,(1<<29)			# enabled ADC interrupts in PFIC (29th bit)
	or x11,x11,x7
	sw x11,0(x10)			# store back new values

# enabling GLOBAL INTERRUPTS
	li t0, 0x88			# load MPIE and MIE bits , 1<<MIE in mstatus is enabling GLOBAL INTERRUPTS
	longs 0x30029073        	#csrw	mstatus,t0 ,manually assembled opcode


	call delay			# delay for man in front of terminal

# start ADC conversion trigger
	li x10,R32_ADC_CTLR2
	lw x11,0(x10)
	li x7,(1<<22)			# (1<<SWSTART) start conversion
	ori x11,x11,1
	sw x11,0(x10)

align 4					# align code to 4 word size

# uart transmit test, prints a string in terminal
Utest:
	li x10,name			# load address of label "name" to x10, string to be transmitted
string_loop:
	lb x8,0(x10)			# load 1 byte from 0 offset of "name"
	beqz x8,sfinish			# if byte in x8 null branch to label "finish"
	call USART_TX			# call subroutine USART_TX to transmit byte
	addi x10,x10,1			# increase pointer by 1 byte
	j string_loop			# jump back to label string_loop until null is encountered
sfinish:		

# ADC measure loop
measure:
	nop				# no operation
	nop				# no operation
checkflag:
	li x10,R32_ADC_STATR		# adc status register (flags)
	lw x11,0(x10)			# copy valyes to x11
	andi x11,x11,2			# AND with adc conversion finish flag mask
	beqz x11,checkflag		# wait till bit 1 is set , if 0 branch to checkflag label (busy loop)
	li x10,R32_ADC_RDATAR		# pointer x10 is loaded with ADC data register address, reading ADC_RDATAR register clears the EOC flag in ADC status register
	lw x11,0(x10)			# copy data register to x11
	li x10,result1			# load address of result1 variable in SRAM in pointer x10
	sw x11,0(x10)			# store ADC result in x11 to result1 in SRAM , pointed by x10
printresult:
	call D_ASCII			# procedure to convert result to ASCII , subroutine called with x10 pointing to result1 in SRAM
	call print			# prints result converted by D_ASCII and stored in MEM registar/variable in SRAM to USART
	li x8,' '			# load space (0x20) , print space
	call USART_TX			# call uart
	li x8,0x0d			# line feed	
	call USART_TX			# call uart
	li x8,0x0a			# carriage feed
	call USART_TX			# call uart
blank_line:
	li x8,' '
	call USART_TX			# call uart
	li x8,0x0d			# line feed
	call USART_TX			# call uart
	li x8,0x0a			# carriage feed
	call USART_TX			# call uart


# below codw block checks "state" variable in SRAM , if 1 watchdog interrupt fired and ADC readings out of threshold
# if "state" is 0 watchdog not triggered loop to measure ADC by polling EOC bit in ADC status register.

wdresult:
	li x10, state			# x10 points to "state" variable in SRAM
	lw x11,0(x10)			# copy state to x11
	andi x11,x11,1			# AND contents with 1 , if state is set we get 1 else 0
	beqz x11, doagain		# if state is not set , WD not triggered. jump to label "doagain" by passing all below instructions
	sw x0,0(x10)			# clear state register by storing 0 for next trigger
printmsg1:
	li x10,msg1			# load address of label msg1 ("watchdog triggered")
string_loop1:
	lb x8,0(x10)			# load 1 byte from 0 offset of "msg1"
	beqz x8,m1finish		# if byte in x8 null branch to label "m1finish"
	call USART_TX			# call subroutine USART_TX to transmit byte
	addi x10,x10,1			# increase pointer by 1 byte
	j string_loop1			# jump back to label string_loop until null is encountered
m1finish:	
	li x10,result1			# x10 pointer points to result1 address
	lw x11,0(x10)			# copy contents of result1 to x11
	li x7,600			# load x7 with high threshold value 600
	bgeu x11,x7,printmsg2		# compare x11(result1) and x7(hight threshold 600), is x11 greater or equal to x7 ? if it is branch to label 'printmsg2'("Above Threshold")
	li x7,400			# load x7 with low threshold value 300
	bltu x11,x7,printmsg3		# if x11 less than x7 branch to label 'printmsg3' ("below threshhold")


printmsg2:
	li x10,msg2			# load address of label "msg2"("Above Threshold")
string_loop2:
	lb x8,0(x10)			# load 1 byte from 0 offset of "name"
	beqz x8,m2finish		# if byte in x8 null branch to label "finish"
	call USART_TX			# call subroutine USART_TX to transmit byte
	addi x10,x10,1			# increase pointer by 1 byte
	j string_loop2
m2finish:
	j doagain			# jump to exit procedure



printmsg3:
	li x10,msg3			# load address of label msg3 ("below threshhold")
string_loop3:
	lb x8,0(x10)			# load 1 byte from 0 offset of "name"
	beqz x8,m3finish			# if byte in x8 null branch to label "finish"
	call USART_TX			# call subroutine USART_TX to transmit byte
	addi x10,x10,1			# increase pointer by 1 byte
	j string_loop3
m3finish:
	nop


doagain:
	call delay
	j measure

	
	
align 4					# assembler instruction to align code
########################################################################################################################
# SUBROUTINES
#############################################################################################################################	
# UART subroutine , call with data in x8
##################################################################	
USART_TX:
	addi sp,sp,-16			# add space in stack
	sw ra,0(sp)			# push ra
	sw x7,4(sp)			# push x7
	sw x10,8(sp)			# push x10
	sw x11,12(sp)			# push x11

	li x10,R32_USART_STATR		# load address of usart status register
	lw x11,0(x10)			# load contents of status register in x11
	andi x11,x11,(1<<7)		# mask out 7th bit, transmit buffer empty flag
	beqz x11,USART_TX		# if 0 transmit buffer full, wait until bit is set
	#li x8,0x30
	mv x7,x8			# move byte in x8 to x7
	li x10,R32_USART_DATAR		# x10 has the address of data register
	sb x7,0(x10)			#store byte in x7 to data register
TC_check:
	li x10,R32_USART_STATR		# get contents of status register again
	lw x11,0(x10)
	andi x11,x11,(1<<6)		# check transmit complete bit
	beqz x11,TC_check		# wait if bit is 0 , when transmit complete = 1
		
	lw x11,12(sp)			# pop x11
	lw x10,8(sp)			# pop x10
	lw x7,4(sp)			# pop x7
	lw ra,0(sp)			# pop ra
	addi sp,sp,16			# set SP back 16 bytes
	ret				# return to caller

########################################
########################################
# Blinks LED on pd4, used for debugging
########################################
PD4_ON:
	addi sp,sp,-16			# move sp 16 bytes downward(4 words)
	sw ra,0(sp)			# push ra
	sw x7,4(sp)			# push x7
	sw x10,8(sp)			# push x10
	sw x11,12(sp)			# push x11
	li x10,R32_GPIOD_BSHR		# R32_GPIOD_BSHR register sets and resets GPIOD pins, load address into pointer x10
	lw x11,0(x10)			# load contents to x11
	li x7,1<<20			# reset pd4 by shifting 1 into bit position 20 of R32_GPIOD_BSHR
	or x11,x11,x7			# OR with x11
	sw x11,0(x10)			# store x11 to R32_GPIOD_BSHR
	

	call delay			# delay subroutine

PD4_OFF:
	li x10,R32_GPIOD_BSHR		# R32_GPIOD_BSHR register sets and resets GPIOD pins, load address into pointer x10
	lw x11,0(x10)			# load contents to x11
	li x7,(1<<4)			# set pd4 by shifting 1 to bit position 4
	or x11,x11,x7			# OR with x11
	sw x11,0(x10)			# store x11 to R32_GPIOD_BSHR

	

	call delay			# delay subroutine

	lw x11,12(sp)			# pop x11
	lw x10,8(sp)			# pop x10
	lw x7,4(sp)			# pop x7
	lw ra,0(sp)			# pop ra
	addi sp,sp,16			# move sp back 4 words
	ret				# return to caller
###################################################
# Delay routine
###################################################
delay:	
	addi sp,sp,-8			# move sp 2 words
	sw ra,0(sp)			# push ra
	sw x6,4(sp)			# push x6
	li x6,2000000			# load an arbitarary value 20000000 to t1 register		
dloop:
	addi x6,x6,-1			# subtract 1 from t1
	bne x6,zero,dloop		# if t1 not equal to 0 branch to label loop
	lw x6,4(sp)			# pop x6
	lw ra,0(sp)			# pop ra
	addi sp,sp,8			# sp back 2 words
	ret				# return to caller
###########################################################
###############################################################
# strings /messages to be printed 
###########################################################
name:
string SAJEEV SANKARAN CH32V003 UART
eol:
bytes 0x0d,0x0a,0x00

msg1:
string Watchdog Triggered
eol1:
bytes 0x0d,0x0a,0x00

msg2:
string Above Threshold
eol2:
bytes 0x0d,0x0a,0x00

msg3:
string Below Threshold
eol3:
bytes 0x0d,0x0a,0x00
##########################################################


align 4				# instruction to assembler to align code

#########################################################################################################################################
# D_ASCII subroutine for converting binary in result1 to DECIMAL (ASCII), point with x10 to register with value to be converted
#########################################################################################################################################

D_ASCII:			
	addi sp,sp,-32		# adjust stack pointer
	sw ra,28(sp)		# PUSH
	sw x15,24(sp)		# PUSH
	sw x11,20(sp)		# PUSH
	sw x8,16(sp)		# PUSH
	sw x7,12(sp)		# PUSH
	sw x5,8(sp)		# PUSH
	sw x4,4(sp)		# PUSH
	sw t1,0(sp)		# PUSH
	li x4,0			# clear register
	li x5,0			# clear register
	li x7,0			# clear register
	li x8,0			# clear register
	li x15,0		# clear register
	
#	li x10,0x20000010	# result1 (point address of value that has to be converted with x10)
	lw x4,0(x10)		# copy value from memory pointed by x10 to x4,this routine to be called after pointing to register with required value
#	li x4,0xffffffff	# 32bit word to be converted into ascii chars
	li x7,1000000000	# divisor
Y1:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X1		# if result negative(not divisible) branch to X1
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y1			# jump to label Y1 till not divisible
X1:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	li x10,mem		# set pointer x10 to SRAM register mem to store the byte
	sb x15,0(x10)		# store byte in mem+0
	li x15,0		# clear result
	li x7,100000000		# load x7 with new divisor
Y2:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X2		# if result negative(not divisible) branch to X2
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y2			# jump to label Y2 till not divisible
X2:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+1 to store the byte
	sb x15,0(x10)		# store byte in mem+1
	li x15,0		# clear result
	li x7,10000000		# load x7 with new divisor
Y3:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X3		# if result negative(not divisible) branch to X3
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y3			# jump to label Y3 till not divisible
X3:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+2 to store the byte
	sb x15,0(x10)		# store byte in mem+2
	li x15,0		# clear result
	li x7,1000000		# load x7 with new divisor
Y4:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X4		# if result negative(not divisible) branch to X4
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y4			# jump to label Y4 till not divisible
X4:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+3		
	sb x15,0(x10)		# store byte in mem+3
	li x15,0		# clear result
	li x7,100000		# load x7 with new divisor
Y5:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X5		# if result negative(not divisible) branch to X5
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y5			# jump to label Y5 till not divisible
X5:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+4 to store the byte
	sb x15,0(x10)		# store byte in mem+4
	li x15,0		# clear result
	li x7,10000		# load x7 with new divisor
Y6:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X6		# if result negative(not divisible) branch to X6
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y6			# jump to label Y6 till not divisible
X6:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+5 to store the byte
	sb x15,0(x10)		# store byte in mem+5
	li x15,0		# clear result
	li x7,1000		# load x7 with new divisor
Y7:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X7		# if result negative(not divisible) branch to X7
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y7			# jump to label Y7 till not divisible
X7:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+6 to store the byte
	sb x15,0(x10)		# store byte in mem+6
	li x15,0		# clear result
	li x7,100		# load x7 with new divisor
Y8:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X8		# if result negative(not divisible) branch to X8
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y8			# jump to label Y8 till not divisible
X8:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+7 to store the byte
	sb x15,0(x10)		# store byte in mem+7
	li x15,0		# clear result
	li x7,10		# load x7 with new divisor
Y9:
	sub x8,x4,x7		# subtract divisor from word to be converted
	sltu x5,x4,x7		# if result negative set x5 to indicate cannot be divided
	bnez x5,X9		# if result negative(not divisible) branch to X9
	mv x4,x8		# else move remainder to x4 for further division/subtraction
	addi x15,x15,1		# increase result by 1
	j Y9			# jump to label Y9 till not divisible
X9:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+8 to store the byte
	sb x15,0(x10)		# store byte in mem+8
	li x15,0		# clear result
	mv x15,x4
X10:
	addi x15,x15,0x30	# add ascii 0 to result to convert to ASCII char
	addi x10,x10,1		# set pointer x10 to SRAM register mem+9 to store the byte	
	sb x15,0(x10)		# store byte in mem+9

	lw t1,0(sp)		# POP
	lw x4,4(sp)		# POP
	lw x5,8(sp)		# POP
	lw x7,12(sp)		# POP
	lw x8,16(sp)		# POP
	lw x11,20(sp)		# POP
	lw x15,24(sp)		# POP
	lw ra,28(sp)		# POP
	addi sp,sp,32		# adjust stack pointer
	ret			# return to caller
######################################################
align 4
################################################################################
# Prints 10 bytes from result1 to USART with lead 0 suppress, values to be stored in mem0-mem9
################################################################################
print:
	addi sp,sp,-20		# adjust stack pointer
	sw ra,16(sp)		# PUSH
	sw x11,12(sp)		# PUSH
	sw x10,8(sp)		# PUSH
	sw x8,4(sp)		# PUSH
	sw t1,0(sp)		# PUSH

	li x11,scratch		# point x11 to scratch register in SRAM
	sw zero,0(x11)		# clear scratch register

	li x10,mem		# point to address mem ,top byte stored in mem0 lowest byte in mem+9, need to print top byte 1st
	li t1,0			# byte counter loaded with 10 , total 10 bytes to be printed
	li x15,10		# max count of 10bytes in x15

Z:
	lb x8,0(x10)		# load byte from result1, msb to lsb
	
	li x4,0x30		# load ascii 0 in x4
	beq x8,x4,supress0	# if result1 byte in x8 is equal to ascii 0 in x4 branch to suppress0 label
	li x11,scratch		# point x11 to scratch if x8 is not 0,that means we have found the 1st byte that is not 0, all leading 0s finished
	li x5,1			# load x5 with 1
	sw x5,0(x11)		# store in scratch register in sram , used as a flag to indicate all leading 0s are finished

print1:
	addi x10,x10,1		# increase the address by 1 byte
	addi t1,t1,1		# increase the byte counter once
	call USART_TX		# call uart
	bne t1,x15,Z		# if t1 not equal to 10 as loaded in x15 loop back to print1 till al 10 bytes are transmitted via usart
	lw t1,0(sp)		# POP
	lw x8,4(sp)		# POP
	lw x10,8(sp)		# POP
	lw x11,12(sp)		# POP
	lw ra,16(sp)		# POP
	addi sp,sp,20		# adjust stack pointer
	ret			# return to caller
supress0:
	li x11,scratch		# point x11 to scratch	
	lw x5,0(x11)		# copy value of scratch to x5
	bnez x5,no_more_supress	# if x5 is not 0 branch to label "no_more_supress"
	li x8,0x20		# if x5 is 0 load x8 with space/blank	
	li x4,9			# load x4 with value 9, suppose the whole value is 0, we dont want to display blank space, test this is 9th byte 2nd last byte
	beq t1,x4,last0is0	# if t1 equals 9 in x4 branch to label "last0is0" which will keep last 0 as 0 on screen
no_more_supress:
	J print1		# no 0 suppression jump to print1	
last0is0:
	li x8,0x30		# load ascii 0 for last 0
	J print1		# jump to print1
##################################################################

align 4				# instruction to align code

##################################################################################
# ANALOG WATCHDOG ISR
##################################################################################
ADC1_IRQhandler:

	addi sp,sp,-60    		# adjust stack pointer
	sw x15,56(sp)			# PUSH
	sw x14,52(sp)			# PUSH
	sw x13,48(sp)			# PUSH
	sw x12,44(sp)			# PUSH
	sw x11,40(sp)			# PUSH
	sw x10,36(sp)			# PUSH
	sw x9,32(sp)			# PUSH
	sw x8,28(sp)			# PUSH
	sw x7,24(sp)			# PUSH
	sw x6,20(sp)			# PUSH
	sw x5,16(sp)			# PUSH
	sw x4,12(sp)			# PUSH
	sw x3,8(sp)			# PUSH
	sw x2,4(sp)			# PUSH
	sw x1,0(sp)			# PUSH
	
###########
	li x10,R32_ADC_STATR		# ADC status register
	lw x11,0(x10)			# copy data register
	andi x11,x11,1			# 1<<0 analog watchdog bit flag
	beqz x11,notwd			# if x11 0 interrupt not from AWD trigger, exit
	sw x0,0(x10)			# clear clear sttatus register
	li x7,1				# load number 1
	li x10,state			# store in state variable SRAM , used as watchdog trigger flag in main code loop
	sw x7,0(x10)
notwd:	

############
	lw x1,0(sp)			# POP
	lw x2,4(sp)			# POP
	lw x3,8(sp)			# POP
	lw x4,12(sp)			# POP
	lw x5,16(sp)			# POP
	lw x6,20(sp)			# POP
	lw x7,24(sp)			# POP
	lw x8,28(sp)			# POP
	lw x9,32(sp)			# POP
	lw x10,36(sp)			# POP
	lw x11,40(sp)			# POP
	lw x12,44(sp)			# POP
	lw x13,48(sp)			# POP
	lw x14,52(sp)			# POP
	lw x15,56(sp)			# POP
	addi sp,sp,60			# adjust stack pointer
	longs 0x30200073		# mret (manually assembled opcode for mret as per RISCV spec)
	
#################	


























	







