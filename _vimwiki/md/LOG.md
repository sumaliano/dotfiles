# LOG



2014 Apr 3 
	(Block readout implemented)
	(No tridi implemented in the ucesb -> "../../unpacker/empty/empty stream://r4-49 --output=excl=type=10,excl=trigger=13,- | ./unpack_sis3316 --debug --file=- --ntuple=RAW,AUTOSAVE,/lustre/land/tmp/at_stream.root")
	
	=> electronic calibration was done by the ikar people the to a precision of 0.5%
	=> the amplitudes must mach within witch ADC/amplifier	(but does not have necessarilly to mach between ADCs, due to different capacitances in the input test signal from the pulser?)
	
	
	at_140403_test_002.lmd		|		pulser signal												|		at_a4c15 and at_a4c16 are empty(the FADC was replaced afterwards)
	at_140403_test_003.lmd		|		alpha and pulser connected to the ADCs 2,3,4 and 5			|		HV=24kv P=10bar (thresholds set very close to the noise baseline)  
	at_140403_test_004.lmd		|		alpha														|		HV=24kv P=10bar (thresholds=18000, p_val=30)  
	at_140403_test_005.lmd		|		alpha and pulser connected to the ADCs 2,3,4 and 5			|		HV=24kv P=10bar (thresholds=18000, p_val=30)  
								|   |
2014 Apr 4						|																	|
	(the unpacker has changed - it now knows from the data how many channels per ADC are enabled)
	at_006.lmd					|		alpha and pulser connected to the ADCs 2,3,4 and 5			|		HV=24kv P=10bar (thresholds=18000, p_val=30) (sent to Ralf as a model for the land02)  
	at_0007-0010.lmd			|		alpha														|		HV=24kv P=10bar (thresholds=18000, p_val=30)  
								|																	|
2014 Apr 7						|																	|
	at_0011-0014.lmd			|		alpha and pulser connected to the ADCs 1,2,3,4 and 5		|		HV=24kv P=10bar (thresholds=18000, p_val=30) (pulser=100kHz, source ~10Hz)
								|																	|
2014 Apr 11						|																	|
	s438at_000_0001-0011.lmd	|		alpha														|	   HV=24kV P=10bar (thresholds=18000, p_val=30)
	s438at_000_0012-0013.lmd	|		beam														|	   HV=24kV P=10bar (thresholds=18000, p_val=30) (trace length set to 1600 and pretrigger length set to 1250)
	
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	  
   
	Time:					
						
2014 Apr 11						
						
start				| s438at_000_0001.lmd			| alpha source/HV=24kV/P=10bar				| (thresholds=18000, p_val=30)	(trace length set to 1600 and pretrigger length set to 1250)
-stop				| S438at_000_0011.lmd			|											| 
start				| S438at_000_0012.lmd			| beam(600MeV)								| onspill rate=?45kHz/HV=24kV/P=10bar (thresholds=18000, p_val=30)	
-stop				| S438at_000_0013.lmd			| offspill rate=?25kHz						| 
					|								|							  
2014 Apr 14			|								|							  
					| S438at_000_0014.lmd			| generator									| no HV	
					| S438at_000_0015.lmd			| generator									| no HV	
					| S438at_000_0016.lmd			| generator									| no HV	
					| S438at_000_0017.lmd			| Generator & alpha							| HV=24kV HVgrid=1.2	
					| S438at_000_0018.lmd			| Generator & alpha							| HV=24kV HVgrid=1.2	
					| S438at_000_0019.lmd			| alpha source								| HV=24kV HVgrid=1.2	
					| S438at_000_0020.lmd			| alpha source								| HV=24kV HVgrid=1.2	
					|								|							  
2014 Apr 15			|								|							  
					| S438at_000_0021.lmd			| generator w random coinci tridi pulser	| no HV	
					| S438at_000_0022.lmd			| generator w random coinci tridi pulser	| no HV	(trace length set to 1850 and pretrigger length set to 1700. signal gate  50u)
					| S438at_000_0023.lmd			| generator w random coinci tridi pulser	| no HV	(trace length set to 2050 and pretrigger length set to 1700, signal gate 60u)
					|								|											| 
					| S438at_000_0025.lmd			| beam(600MeV) Rate=13k?					| tridii setup actar_los.trlo
					| local036.lmd					|											| 
	~21h			| 30?	local037.lmd			|											| 
					| Local038-047.lmd				|											| thresholds high all channels but 1st per ADC(1/2/3/4)
					| Local048.lmd					|											| tridii setup actar_los_derad.trlo; thresholds back to 18000
					| Local049-051.lmd				| (no triggers)								| tridii setup actar_pulser.trlo (no data)
					|								|											| 
2014 Apr 16			|								|											| 
					| Local052-054					| beam (800MeV) Rate=45k					| tridii setup actar_pulser.trlo 
					| Local055-60					|											| tridii setup actar_beam_los.trlo / lead target implemented
	03h14			|								|							  
					| Local061						| beam (700MeV)								| lead target removed (HV ramping)
					| Local062-063					|											| HV ramping finished
					| local064						|											| HV of the 4th sector set very high due to noise triggering (13/14/25/26/33 has small negative pulses in coincidence with LOS)
					| Local065-0001-0002			|											| HV ramping 
					| Local065-0003					|											| HV ramping finished
	05:17:00 AM		| ~local065-000?				|											| HV ramping, 5kV
	05:34:00 AM		| Local065-0005					|											| HV=24kV
	05:37:00 AM		| local066						|											| colleagues discovered beam drift, fixed
	06:34:00 AM		| run065_local068_0001.lmd		|											| RIO stuck, hardware reboot
	07:09:00 AM		| run065_local068_0003			|											| beam is off
	06:48:00 PM		| local74						| beam (700MeV)								| tridii setup actar_beam_los.trlo / HV ramping
	06:53:00 PM		|								|											| following runs not useful due to no HV
	07:56:00 PM		| run075_local078				| HV=24kV									| 
					| run076_local079-0001-0002		|											| pulser in tridii (to test deadtime)
					| run076_local079-0003			|											| tridii setup actar_beam_los.trlo
					| run079_local083				|											| load tridi logic - DAQ MT in coincidence with ACTAR (actar_beam_mt.trlo)
					| run079_local084				|											| trying different tridi setups
					| run079_local085				|											| got killed
					| run079_local086				|											| load tridi logic - DAQ MT in coincidence with ACTAR (actar_beam_mt.trlo)
					| run080_local087				|											| end of testing – begin of long run
					|								|								  
2014 Apr 17			|								|								  
					| run081_local088				|											| run started after French people needed to go inside 
					| run081_local089				|											| 4th sector disabled due to high noise 
					| run082_local090				|											| actar people went inside to check the electronics → the problem remained 
	01:15:00 AM		| run082_local091				|											| 4th sector disabled again ( channels 5/6/13/14/25/26	show negative pulses)
	12:05:00 PM		| run092_local101_0001			|											| small changes in tridi logic in the beginning, then old setup (actar_beam_mt.trlo)
	12:15:00 PM		|								|											| no beam
					| run093-local102				|											| tridi_standalone.trlo (only tridi pulser), sector 4 enabled
					| run094-local103				| P=5bar/HVgrid=600V/HV=12kV				| tridi_alpha.trlo / alpha data 
					| run097-local106				| beam(1500MeV)								| testing tridi_los_derand_lu.trlo (no events accepted)
					| run098-local107				| beam(700MeV)								| tridi_beam_mt.trlo (this run got killed due to high noise)
					| run099-local10?				|											| testing new thresholds 
	05:05:00 PM		| run100-local110				|											| ACTAR seems stable, sector 4 active but with ch#60 masked, thresholds in all channels set from 18000 to 5000 
					| run103-local113				|											| run sweep ALADIN → beam difocused
					| run103-local114				|											| 7th channal of adc 5 was enabled to read LOS!ROLU
					|								|								  
2014 Apr 18			|								|								  
	12:30:00 AM		| run106-local118				|											| first file of the day, same as before
					|								|											| strange signal shape on ROLU may be due to lack of 50Ohm terminator
					| run109-local121				|											| after controlled access, actar rates (2,3) increased 
					|								|											| 
					| run111_local123				|											| tridisetup_beam_mt_w_offspill.trlo / we start saving alpha data during offspill
	03:18:00 PM		| run114_local126_0001			| 5kV - 250V, 2 atm							| alpha data
	04:29:00 PM		|								|											| tridi setup fixed to include gate_delay(4) = beam_gate
					| run124_local138				|											| sweep run over pixel mask
					| run125_local139				|											| sweep run finished 
					| run127_local141				|											| beam after preparation for high energies
					| run128_local142				| beam(500AMeV)								| tridi setup = actar_los_derend_lu.trlo
					| run128_local143				|											| tridi setup = actar_beam_mt_w_offspill.trlo (main daq run stop shortly after)
					| run129_local144				|											| tridi setup = actar_beam_mt_w_offspill.trlo
					| run130_local135				|											| dumb data(daq left running but high voltage switched off)
