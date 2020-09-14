#!/bin/bash
# Copyright (C) 2020 ARM
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Author: Manoj Iyer <manoj.iyer@arm.com>
#


: <<'END'

How to use this script.
-----------------------
Lets assume you are generating data for thread count 1,2,4,8..96. And, you are
going to compare ycsb output on AWS Intel vs ARM instance. You have your raw
results in 2 directories named test_output_intel and test_output_arm. The
results of ycsb 'load' are in filenames like LoadData<threadcount>.txt and
'run' data are in filenames like RunData<threadcount>.txt. To generate the
.dat files you would invoke the script twice as follows:

./process_data.sh ./test_output_intel
./process_data.sh ./test_output_arm

End result the script generates data files of the following format.
[Thread Count] [Value for Intel ] [Value for ARM]

For example:

==== insert_rt.dat ====
1	415810	739866
2	295922	476954
4	162898	277419
8	93854	161961
16	64794	107116
32	69937	101941
64	75932	106037
96	80067	125404
=======================

Note: If you use the test_db.sh script it will generate raw files that can 
be easily processed by this script.
END

DIR=$1
calc(){ awk "BEGIN { print $* }"; }

# Process data from Load operation. This is where documents were inserted
# into mongodb. The input directory should contain raw files prefixed by
# LoadData[0-9].txt Where the number suffix is the thread count used in
# each load command in ycsb

[ -d plot ] || mkdir plot

# Generate data files *.dat for each matric we want to track like runtime,
# throughput, latency etc.
# From the raw data get the number of threads, and populate the datafiles
# with thread count information in column #1
insert_data=$(for f in $(ls -1v $DIR/LoadData*); do basename $f ; done)
for f in insert_rt.dat insert_tput.dat insert_99.dat insert_avg.dat; do
	if [ ! -f "plot/${f}" ]; then
		for file in ${insert_data}; do
			suffix="${file##*[0-9]}"
			t="${file%"$suffix"}"
			t_num="${t##*[!-0-9]}"
			echo "${t_num}" >> plot/${f}
		done
	fi
done


# Generate the Nth column of data in each *.dat file for the 
# given directory of raw results.
for file in $(ls -1v $DIR/LoadData*.txt); do
	OVERALL_RunTime+="$(grep -E "\[OVERALL\].*RunTime" $file | cut -f 3 -d,)"
	OVERALL_Throughput+="$(grep -E "\[OVERALL\].*Throughput" $file | cut -f 3 -d,)"
	INSERT_99thPercentileLatency+="$(grep -E "\[INSERT\].*99thPercentileLatency" $file | cut -f 3 -d,)"
	INSERT_AverageLatency+="$(grep -E "\[INSERT\].*AverageLatency" $file | cut -f 3 -d,)"
done

for f in $OVERALL_RunTime; do echo $f >> /tmp/f.tmp.$$; done
paste plot/insert_rt.dat /tmp/f.tmp.$$ > plot/insert_rt.dat.new && rm /tmp/f.tmp.$$
mv plot/insert_rt.dat.new plot/insert_rt.dat

for f in $OVERALL_Throughput; do printf "%.4f\n" ${f} >> /tmp/f.tmp.$$; done
paste plot/insert_tput.dat /tmp/f.tmp.$$ > plot/insert_tput.dat.new && rm /tmp/f.tmp.$$
mv plot/insert_tput.dat.new plot/insert_tput.dat

for f in $INSERT_99thPercentileLatency; do printf "%.4f\n" $(calc ${f}/ 1000) >> /tmp/f.tmp.$$; done
paste plot/insert_99.dat /tmp/f.tmp.$$ > plot/insert_99.dat.new && rm /tmp/f.tmp.$$
mv plot/insert_99.dat.new plot/insert_99.dat

for f in $INSERT_AverageLatency; do printf "%.4f\n" $(calc ${f}/ 1000) >> /tmp/f.tmp.$$; done
paste plot/insert_avg.dat /tmp/f.tmp.$$ > plot/insert_avg.dat.new && rm /tmp/f.tmp.$$
mv plot/insert_avg.dat.new plot/insert_avg.dat

# Process data from Run operation. This is where documents were 
# read/modify/write or updated in mongodb. 
# The input directory should contain raw files prefixed by
# RunData[0-9].txt Where the number suffix is the thread count used in
# each run command in ycsb

# Generate data files *.dat for each matric we want to track like runtime,
# throughput, latency etc.
# From the raw data get the number of threads, and populate the datafiles
# with thread count information in column #1
rmw_data=$(for f in $(ls -1v $DIR/RunData*.txt); do basename $f ; done)
for f in rmw_rt.dat rmw_tput.dat rmw_r99.dat rmw_ravg.dat rmw_rmw99.dat rmw_rmwavg.dat rmw_u99.dat rmw_uavg.dat; do
	if [ ! -f "plot/${f}" ]; then
		for file in ${rmw_data}; do
			suffix="${file##*[0-9]}"
			t="${file%"$suffix"}"
			t_num="${t##*[!-0-9]}"
			echo "${t_num}" >> plot/${f}
		done
	fi
done

unset OVERALL_RunTime
unset OVERALL_Throughput

# Generate the Nth column of data in each *.dat file for the 
# given directory of raw results.
for file in $(ls -1v $DIR/RunData*.txt); do
	OVERALL_RunTime+="$(grep -E "\[OVERALL\].*RunTime" $file | cut -f 3 -d,)"
	OVERALL_Throughput+="$(grep -E "\[OVERALL\].*Throughput" $file | cut -f 3 -d,)"
	READ_99thPercentileLatency+="$(grep -E "\[READ\].*99thPercentileLatency" $file | cut -f 3 -d,)"
	READ_AverageLatency+="$(grep -E "\[READ\].*AverageLatency" $file | cut -f 3 -d,)"
	READMODIFYWRITE_99thPercentileLatency+="$(grep -E "\[READ-MODIFY-WRITE\].*99thPercentileLatency" $file | cut -f 3 -d,)"
	READMODIFYWRITE_AverageLatency+="$(grep -E "\[READ-MODIFY-WRITE\].*AverageLatency" $file | cut -f 3 -d,)"
	UPDATE_99thPercentileLatency+="$(grep -E "\[UPDATE\].*99thPercentileLatency" $file | cut -f 3 -d,)"
	UPDATE_AverageLatency+="$(grep -E "\[UPDATE\].*AverageLatency" $file | cut -f 3 -d,)"
done

for f in $OVERALL_RunTime; do echo $f >> /tmp/f.tmp.$$; done
paste plot/rmw_rt.dat /tmp/f.tmp.$$ > plot/rmw_rt.dat.new && rm /tmp/f.tmp.$$
mv plot/rmw_rt.dat.new plot/rmw_rt.dat

for f in $OVERALL_Throughput; do printf "%.4f\n" ${f} >> /tmp/f.tmp.$$; done
paste plot/rmw_tput.dat /tmp/f.tmp.$$ > plot/rmw_tput.dat.new && rm /tmp/f.tmp.$$
mv plot/rmw_tput.dat.new plot/rmw_tput.dat

for f in $READ_99thPercentileLatency; do printf "%.4f\n" $(calc ${f}/ 1000) >> /tmp/f.tmp.$$; done
paste plot/rmw_r99.dat /tmp/f.tmp.$$ > plot/rmw_r99.dat.new && rm /tmp/f.tmp.$$
mv plot/rmw_r99.dat.new plot/rmw_r99.dat

for f in $READ_AverageLatency; do printf "%.4f\n" $(calc ${f}/ 1000) >> /tmp/f.tmp.$$; done
paste plot/rmw_ravg.dat /tmp/f.tmp.$$ > plot/rmw_ravg.dat.new && rm /tmp/f.tmp.$$
mv plot/rmw_ravg.dat.new plot/rmw_ravg.dat

for f in $READMODIFYWRITE_99thPercentileLatency; do printf "%.4f\n" $(calc ${f}/ 1000) >> /tmp/f.tmp.$$; done
paste plot/rmw_rmw99.dat /tmp/f.tmp.$$ > plot/rmw_rmw99.dat.new && rm /tmp/f.tmp.$$
mv plot/rmw_rmw99.dat.new plot/rmw_rmw99.dat

for f in $READMODIFYWRITE_AverageLatency; do printf "%.4f\n" $(calc ${f}/ 1000) >> /tmp/f.tmp.$$; done
paste plot/rmw_rmwavg.dat /tmp/f.tmp.$$ > plot/rmw_rmwavg.dat.new && rm /tmp/f.tmp.$$
mv plot/rmw_rmwavg.dat.new plot/rmw_rmwavg.dat

for f in $UPDATE_99thPercentileLatency; do printf "%.4f\n" $(calc ${f}/ 1000) >> /tmp/f.tmp.$$; done
paste plot/rmw_u99.dat /tmp/f.tmp.$$ > plot/rmw_u99.dat.new && rm /tmp/f.tmp.$$
mv plot/rmw_u99.dat.new plot/rmw_u99.dat

for f in $UPDATE_AverageLatency; do printf "%.4f\n" $(calc ${f}/ 1000) >> /tmp/f.tmp.$$; done
paste plot/rmw_uavg.dat /tmp/f.tmp.$$ > plot/rmw_uavg.dat.new && rm /tmp/f.tmp.$$
mv plot/rmw_uavg.dat.new plot/rmw_uavg.dat

