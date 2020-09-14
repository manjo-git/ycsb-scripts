#!/bin/bash
#
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
This script will generate the gnuplot script for you to generate graphs.
If you have collected data for say r5.xlarge r5a.xlarge r6g.xlarge you
would pass those as labels to this script in the order corresponding to
the columns in  the data file. 

Usage:
./genplot <label1> <label2> 
or
./genplot r5.xlarge r5a.xlarge r6g.xlarge
END

INST="$@"
colors=([2]="red" [3]="blue" [4]="green")

dc=$(ls -1 *.dat 2>/dev/null | wc -l)
if [ $dc -eq 0 ]; then
	cat <<-EOF
	Please run this script from the 'plot' directory 
	where the datafiles *.dat are located.
	EOF
	exit
fi

if [ $# -eq 0 ]; then
	cat <<-EOF
	Please provide the label names
	Usage:
		echo "$0 <label1> <label2>
	EOF
	exit
fi

genplot() {
	local plot_cmd
	local op="$1"
	local title_name="$2"
	local ylabel="$3"
	local count=2

	for i in $INST; do
		plot_cmd+="\"${op}.dat\" using 1:${count} w linesp title \"${i}\" lc rgb \"${colors[${count}]}\","
		count=$((count+1))
	done

	gnuplot <<-EOF
	set terminal png size 720,480
	set output "plot_${op}.png"
	set key outside
	set xlabel "Number of Threads"
	set ylabel "${ylabel}"
	set title "${title_name}: ${ylabel}"
	plot ${plot_cmd::-1}
	EOF
}

# 99 Percentile Latency
genplot "insert_99" "INSERT" "99thPercentileLatency(ms)"
genplot "rmw_r99" "READ" "99thPercentileLatency(ms)"
genplot "rmw_rmw99" "READ-MODIFY_WRITE" "99thPercentileLatency(ms)"
genplot "rmw_u99" "UPDATE" "99thPercentileLatency(ms)"

# Average Latency
genplot "insert_avg" "INSERT" "average Latency (ms)"
genplot "rmw_ravg" "READ" "average Latency (ms)"
genplot "rmw_rmwavg" "READ-MODIFY-WRITE" "average Latency (ms)"
genplot "rmw_uavg" "UPDATE" "average Latency (ms)"

# Throughput
genplot "insert_tput" "INSERT" "Throughput(ops/sec)"
genplot "rmw_tput" "READ/READ-MODIFY-WRITE/UPDATE" "Throughput(ops/sec)"

# Runtime
genplot "insert_rt" "INSERT" "RunTime(ms)"
genplot "rmw_rt" "READ/READ-MODIFY-WRITE/UPDATE" "RunTime(ms)"
