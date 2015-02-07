'--------------------------------------------------------------
'                         Thomas Jensen
'--------------------------------------------------------------
'  file: AVR_LIGHT_SENSOR_v1.0
'  date: 18/03/2007
'--------------------------------------------------------------
$regfile = "m8def.dat"
$crystal = 1000000
Config Watchdog = 1024
Config Portb = Output
Config Portd = Output
Config Portc = Input

Dim W As Word , Volt As Word , Read_timer As Integer
Dim C_limit1 As Integer , C_limit2 As Integer
Dim Over_limit As Bit , Limit As Integer
Dim Volt_temp As String * 1 , Volt_string As String * 3
Dim Volt_number As Integer , Set_timer As Integer
Dim Over_limit_set As Bit , Action_timer As Integer
Dim Up_counter As Integer , Down_counter As Integer
Dim Eeprom_limit As Eram Integer , Eeprom_save As Integer
Dim Lowlimit As Integer , Highlimit As Integer

Config Adc = Single , Prescaler = Auto , Reference = Avcc
Start Adc

'Inn
'PinC.0 Lyssensor, analog
'PinC.1 Grenseverdi opp
'PinC.2 Grenseverdi ned
'PinC.3 Over Grenseverdi(under Er Standard)

'Ut
'PortB.0 LED-segment siffer 1 (f.v)
'PortB.1 LED-segment siffer 2 (f.v)
'PortB.2 LED-segment siffer 3 (f.v)
'PortB.3 Signal utgang konstant
'PortD.4 Signal Utgang Puls
'PortD LED segment

'get eeprom values
Limit = Eeprom_limit

Portd = 64
Portb.0 = 1
Portb.1 = 0
Portb.2 = 0
Waitms 500
Portb.0 = 0
Portb.1 = 1
Waitms 500
Portb.1 = 0
Portb.2 = 1
Waitms 500
Portb.2 = 0
Waitms 500

Start Watchdog

'program start
Main:
'read light
If Read_timer = 0 Then
W = Getadc(0)
Volt = W
Read_timer = 666
End If

'set limit up
If Pinc.1 = 1 Then
   C_limit1 = 0
   Up_counter = 0
   End If
If Pinc.1 = 0 Then
   If C_limit1 = 0 Then Incr Limit
   C_limit1 = 1
   Incr Up_counter
   Eeprom_save = 20000
   Set_timer = 133
   End If

'set limit down
If Pinc.2 = 1 Then
   C_limit2 = 0
   Down_counter = 0
   End If
If Pinc.2 = 0 Then
   If C_limit2 = 0 Then Decr Limit
   C_limit2 = 1
   Incr Down_counter
   Eeprom_save = 20000
   Set_timer = 133
   End If

'correct if value out of range
If Limit < 0 Then Limit = 0
If Limit > 999 Then Limit = 999
If Volt > 999 Then Volt = 999

'check limit and set conditions
Lowlimit = Limit - 25
Highlimit = Limit + 25

If Pinc.3 = 0 Then
   If Volt > Highlimit Then Over_limit = 1
   If Volt < Lowlimit Then Over_limit = 0
   Else
   If Volt < Lowlimit Then Over_limit = 1
   If Volt > Highlimit Then Over_limit = 0
End If

'show light level/threshold
If Set_timer = 0 Then Volt_string = Str(volt)
If Set_timer > 0 Then Volt_string = Str(limit)

'digit 1
If Len(volt_string) > 2 Then Volt_temp = Left(volt_string , 1) Else Volt_temp = "0"
Volt_number = Val(volt_temp)
Portd = Lookup(volt_number , Table)
If Set_timer > 0 Then Portd.7 = 1
If Len(volt_string) > 3 Then Portd = 121
Portb.0 = 1
Portb.1 = 0
Portb.2 = 0
Waitms 5

Portb.0 = 0
Portb.1 = 0
Portb.2 = 0

'digit 2
If Len(volt_string) = 2 Then Volt_temp = Left(volt_string , 1)
If Len(volt_string) > 2 Then Volt_temp = Mid(volt_string , 2 , 1)
If Len(volt_string) < 2 Then Volt_temp = "0"
Volt_number = Val(volt_temp)
Portd = Lookup(volt_number , Table)
If Over_limit = 1 Then Portd.7 = 1
If Len(volt_string) > 3 Then Portd = 80
Portb.0 = 0
Portb.1 = 1
Portb.2 = 0
Waitms 5

Portb.0 = 0
Portb.1 = 0
Portb.2 = 0

'digit 3
Volt_temp = Right(volt_string , 1)
Volt_number = Val(volt_temp)
Portd = Lookup(volt_number , Table)
If Read_timer > 600 And Eeprom_save = 0 Then Portd.7 = 1
If Read_timer < 600 And Eeprom_save > 0 Then Portd.7 = 1
If Len(volt_string) > 3 Then Portd = 80
Portb.0 = 0
Portb.1 = 0
Portb.2 = 1
Waitms 5

Portb.0 = 0
Portb.1 = 0
Portb.2 = 0

'set outputs
If Over_limit = 1 And Over_limit_set = 0 Then
   Over_limit_set = 1
   Portb.3 = 1
   Action_timer = 33
   End If
If Over_limit = 0 Then
   If Over_limit_set = 1 Then Action_timer = 100
   Over_limit_set = 0
   Portb.3 = 0
   End If

'pulse output
If Action_timer > 0 Then
   Decr Action_timer
   Portb.4 = 1
   End If
If Action_timer = 0 Then Portb.4 = 0

'timers
If Set_timer > 0 Then Decr Set_timer
If Read_timer > 0 Then Decr Read_timer

'fast threshold adjust
If Up_counter > 66 Then Incr Limit
If Down_counter > 66 Then Decr Limit

'save eeprom values
If Eeprom_save > 0 Then Decr Eeprom_save
If Eeprom_save = 1 Then Eeprom_limit = Limit

'loop
Reset Watchdog
Goto Main
End

'---- data for correct display of numbers on LED display ------
Table:
Data 63 , 6 , 91 , 79 , 102 , 109 , 125 , 7 , 127 , 111 , 128
'     0    1   2    3    4     5     6     7   8     9     dp