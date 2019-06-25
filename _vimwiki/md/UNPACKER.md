# Unpacker

#### List of flags:
		/path/to/unpacker --help

Ex(debug): Print data:
		/path/to/unpacker stream://r4-11  --print --debug --data --max-events=10

#### Streaming:

		/path/to/unpacker stream://r4-11 --ntuple=/path/to/rootfile.root

		/path/to/unpacker stream://r4-49 --output=/d/land2/tmp/actar.lmd

#### Empty unpacker:

	 ~/proxy_server/unpacker/empty/empty --file=teststruck0014.lmd --print --data --max-events=1 | head -n20

	../../unpacker/empty/empty stream://r4-49 --output=excl=type=10,excl=trigger=13,excl=trigger=12,- --max-events=1 | ./unpack_sis3316 --print --debug --file=- --ntuple=RAW,AUTOSAVE,/data/land/actar/at_stream.root | less -r

	../../unpacker/empty/empty stream://r4-49 --output=incl=type=88,incl=trigger=1,incl=trigger=2,- | ../sis3316_mfi/unpack_sis3316  --debug --file=- --ntuple=RAW,AUTOSAVE,/data/land/actar/at_stream.root

#### Read scalers from raw data:

	BL: To 'unpack' single scaler values using a combination of ucesb, grep and awk, do the followingx.
	
	Read the file and filter out the triggers, you want to look at trigger=13 means end of spillx:
		./proxy_server/unpacker/empty/empty <lmd-file> --output=incl=trigger=13,- \
		./proxy_server/unpacker/empty/empty --file=- --print --data \
	 
	 Grep for the begin of the event and print the next 9 lines assuming, that the scaler values you are hunting for, are contained in these lines:
		grep -A 9 "Trigger" \
	
	Cut away the first couple of lines (event header):
		awk '(NR%11)>4' \
	
	Treat the data as blocks of '6' lines, and look at the first line of each block. Then read the column 8 from this block and divide by the number of seconds spent in the interval (here: 2) 
	
	Example: 
		awk 'NR%6==1{print strtonum("0x"$7)/2}' \
	gives the first raw trigger of the trigger logic
	
	Average the value over all input:
		awk '{sum+=$1}END{print sum/NR}'


#### SCALLERS STUFF ?? ======

	~/proxy_server/unpacker/empty/empty /hera/land/actar/lmd/s438at_000_0012.lmd --output=incl=trigger=13,- | ~/proxy_server/unpacker/empty/empty --file=- --print --data | grep -A 9 "Trigger" | awk '(NR%11)>4' | awk 'NR%6==1{print strtonum("0x"$7)/2}' | awk '{sum+=$1}END{print sum/NR}'

	~/proxy_server/unpacker/empty/empty /hera/land/actar/lmd/s438at_000_0013.lmd --output=incl=trigger=13,- | ~/proxy_server/unpacker/empty/empty --file=- --print --data --max-events=200 | grep -A 9 "Trigger" | awk '(NR%11)>4' | awk 'NR%6==1{printf("%3d %3d", strtonum("0x"$7)/2 , strtonum("0x"$8)/2)}NR%6==2{printf("%3d %3d", strtonum("0x"$1)/2 , strtonum("0x"$2)/2); printf("\n")}' | awk '{sum1+=$1}{sum2+=$2}{sum3+=$3}{sum4+=$4}END{printf("%3d %3d %3d %3d\n", sum1/NR, sum2/NR, sum3/NR, sum4/NR)}'
