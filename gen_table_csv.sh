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


# This script will generate a csv file with data that can be imported 
# into libre cal (excel) and can then be easily cut and pasted into
# a libre writer (word) document as tables. 

[ -f table_data.csv ] && rm -f table_data.csv

for i in ./plot/*.dat ; do
	echo $(basename ${i::-4}) >> table_data.csv
	cat $i >> table_data.csv 
	echo " " >> table_data.csv
done

sed -i 's/\>/,/g;s/,$//;s/,\./\./g' table_data.csv
