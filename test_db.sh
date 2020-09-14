#!/usr/bin/bash
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

# This script will run the ycsb benchmark test on mongodb 
# you can change the 'server' and 'target' variables to run test on 
# local db or different target. 'target' names can be arch or instance type
# it is just an indentifier in case you are comparing multiple instance/server
# types. 

server="ec2-3-135-240-240.us-east-2.compute.amazonaws.com"
target="arm"
dburl="mongodb://${server}:27017/ycsb?w=0"

mongo ${server}/ycsb --eval "db.dropDatabase()"

mkdir test_data_${target}

for t in 1 2 4 8 16 32 64 96 ; do
        ./bin/ycsb load mongodb -s -P workloads/workloadf -p recordcount=10000000 -p mongodb.url=${dburl} -threads ${t}  > ./test_data_${target}/LoadData${t}.txt
        sync;sync
	mongo ${server}/ycsb --eval "db.dropDatabase()"
done

./bin/ycsb load mongodb -s -P workloads/workloadf -p recordcount=10000000 -p mongodb.url=${dburl} -threads 100 > /tmp/test_data_${target}/Loadfinal.txt

sync;sync

for t in 1 2 4 8 16 32 64 96; do
        ./bin/ycsb run mongodb -s -P workloads/workloadf -p recordcount=10000000 -p mongodb.url=${dburl}  -threads ${t}  > ./test_data_${target}/RunData${t}.txt
        sync;sync
done

tar zcf test_data_${target}.tgz ./test_data_${target}/

echo "yscb raw data available in $PWD/test_data_${target}.tgz"
