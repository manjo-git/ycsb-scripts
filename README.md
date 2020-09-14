# Run ycsb benchmark and process data. 
Please note these are helper scripts I use to generate some performance data for comparing mongodb on various AWS instances. 
The code quality is just so-so, and you are welcome to use it as you like, modify as you need. Just don't expect me to support it. 

# Generate benchmark data.
## test_db.sh
You may modify this script if you are running ycsb against any other database like cassandra etc to use the right commands. In
this example I am using mongodb. 

Copy the script test_db.sh to your client AWS instance, and run it against the mongodb server on the target. Say you ran ycsb
against mongodb on r5.16Xlarge (Intel) r5a.16Xlarge (AMD) and r6g.16Xlarge, and you want to compare the performance matrics on 
each of those. 

After you run the test_db script you will end up with 3 directories with raw data
```
test_output_r6g test_output_r5 and test_output_r5a
```
Each containing data in the following files
```
LoadData16.txt  LoadData4.txt   RunData16.txt  RunData4.txt
LoadData1.txt   LoadData64.txt  RunData1.txt   RunData64.txt
LoadData2.txt   LoadData8.txt   RunData2.txt   RunData8.txt
LoadData32.txt  LoadData96.txt  RunData32.txt  RunData96.txt
```
# Process raw data
## process_data.sh

The process_data.sh script will take data from raw files for each of the directories and put them in a table, 1st column is the
number of threads, the 2nd, 3rd etc will be output corresponding to each of the directories provided. 

```
$ ../scripts/process_data.sh ./test_output_r5
$ ../scripts/process_data.sh ./test_output_r5a/
$ ../scripts/process_data.sh ./test_output_r6g/
```
Remember the order r5 (Intel) r5a (AMD) and r6g (ARM)
```
$ ls plot
insert_99.dat   insert_tput.dat  rmw_rmw99.dat   rmw_tput.dat
insert_avg.dat  rmw_r99.dat      rmw_rmwavg.dat  rmw_u99.dat
insert_rt.dat   rmw_ravg.dat     rmw_rt.dat      rmw_uavg.dat
```
# Generate Graphs
## gen_plot.sh

This script needs to be run from the directory that has the .dat files. The script will generate graphs in the form, on X axis number
of threads, and Y axis the matric you are graphing like throughput, runtime, latency etc.

```
$ cd plot
$ ../../scripts/gen_plot.sh r5.16Xlarge r5a.16Xlarge r6g.16Xlarge

plot$ ls
insert_99.dat        plot_insert_rt.png    plot_rmw_rt.png    rmw_rmw99.dat
insert_avg.dat       plot_insert_tput.png  plot_rmw_tput.png  rmw_rmwavg.dat
insert_rt.dat        plot_rmw_r99.png      plot_rmw_u99.png   rmw_rt.dat
insert_tput.dat      plot_rmw_ravg.png     plot_rmw_uavg.png  rmw_tput.dat
plot_insert_99.png   plot_rmw_rmw99.png    rmw_r99.dat        rmw_u99.dat
plot_insert_avg.png  plot_rmw_rmwavg.png   rmw_ravg.dat       rmw_uavg.dat
```
# Generate Table csv file
# gen_table_csv.sh

We also want to have tables of the matrics, like thread count vs given matric. This script will put all of the data into a csv file
so that you can import it into a spreadsheet. You could cut and past them easily from here on to word as tables or do other 
processing with them.

```
$ cd ../
$ ../scripts/gen_table_csv.sh 
$ ls -la table_data.csv 
-rw-rw-r-- 1 manjo manjo 2826 Sep 14 13:53 table_data.csv
```
