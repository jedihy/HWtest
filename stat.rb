#!/usr/bin/ruby -W0
SLEEP_TIME=1.0/4.0
nsecho=1 #enable redirecting the stdout to file or not e.g: 1= enable 0= disable
puts "This script is going to run TCL scrips and analyze the generated data then ouput the result into screen and save the records to log, trace and nsout folders respectively"
sleep(SLEEP_TIME)
puts "NS's stdout redirecting is enable" unless nsecho==0
sleep(SLEEP_TIME)
puts "NS's stdout redirecting is disable" unless nsecho==1
sleep(SLEEP_TIME)
puts "This script is runing TCL scripts!.......Please wait!!This may take a long while!"
Dir.mkdir("nsout") unless File.exist?("nsout")
for objt_var in [16000,64000,256000,1000000,4000000,16000000]
	for rtt_var in[10,20,50,100]
		for loss_var in [0.001,0.01]
        	#0.01 == 1%
                	for bdwth_var in [2,4,8] #no 256Kbps for some reasons
                	#Mbps
                        #ns file <rtt> <loss_rate> <bandwidth> <object_size>
               		system("ns newCA_v1.tcl #{rtt_var} #{loss_var} #{bdwth_var} #{objt_var} >/dev/nul 2>&1") unless nsecho==1
	    	        system("nsorg oldCA_v1.tcl #{rtt_var} #{loss_var} #{bdwth_var} #{objt_var} >/dev/nul 2>&1") unless nsecho==1
               		system("ns newCA_v1.tcl #{rtt_var} #{loss_var} #{bdwth_var} #{objt_var} >nsout/#{rtt_var}-#{loss_var}-#{bdwth_var}-#{objt_var}-newCA 2>&1") unless nsecho==0
			system("nsorg oldCA_v1.tcl #{rtt_var} #{loss_var} #{bdwth_var} #{objt_var} >nsout/#{rtt_var}-#{loss_var}-#{bdwth_var}-#{objt_var}-oldCA 2>&1") unless nsecho==0
			
			end
        	end
	end
end
puts "Running TCL scripts is done!............."
puts "Analyzing the data!..........."
Dir.mkdir("log") unless File.exist?("log")
out=File.new("log/log","w")
rtt=10
lossrate=0.001
count=0
sumratio=0
for objsize in [1000000,4000000,16000000 ]
	for bw in [2,4,8]
		out.puts "---------#{rtt}-#{lossrate}-#{bw}-#{objsize}-----------"
		a=`tail -1 #{rtt}-#{lossrate}-#{bw}-#{objsize}-littlecwnd.trace|gawk '{print $2}'`
		b=`tail -1 #{rtt}-#{lossrate}-#{bw}-#{objsize}-bigcwnd.trace|gawk '{print $2}'`
		out.puts a,b
		out.print "old ",((objsize/1000000)/a.to_f)*8,"\n"
		out.print "new ",((objsize/1000000)/b.to_f)*8,"\n"
		out.puts "----------Acc ratio is-------------"
		subratio = a.to_f/b.to_f
		count+= 1
		sumratio = sumratio + subratio
		out.puts subratio
	end
end
		out.puts "---------Avg of #{rtt}-#{lossrate}------- "
		puts "---------Avg of #{rtt}-#{lossrate}------- "
		out.print "Avg_ ",sumratio/count,"\n"
		print "Avg_ ",sumratio/count,"\n"


for lossrate in [0.001,0.01]
	for rtt in [20,50,100]
		sumratio=0
		count=0
		for objsize in [1000000,4000000,16000000 ]
			for bw in [2,4,8]
			out.puts "---------#{rtt}-#{lossrate}-#{bw}-#{objsize}-----------"
			a=`tail -1 #{rtt}-#{lossrate}-#{bw}-#{objsize}-littlecwnd.trace|gawk '{print $2}'`
			b=`tail -1 #{rtt}-#{lossrate}-#{bw}-#{objsize}-bigcwnd.trace|gawk '{print $2}'`
			out.puts a,b
			out.print "old ",((objsize/1000000)/a.to_f)*8,"\n"
	                out.print "new ",((objsize/1000000)/b.to_f)*8,"\n"
			out.puts "----------Acc ratio is-------------"
			subratio = a.to_f/b.to_f
			count+= 1
			sumratio = sumratio + subratio
			out.puts subratio
			end
		end
		out.puts "---------Avg of #{rtt}-#{lossrate}------- "
        	puts "---------Avg of #{rtt}-#{lossrate}------- "
         	out.print "Avg_ ",sumratio/count,"\n"
      		print "Avg_ ",sumratio/count,"\n"
	end
end
puts "Analyzing is done!..................."
puts "Now move temp files into folder respectively!................."
Dir.mkdir("trace") unless File.exist?("trace")
system("rm trace/*")
system("mv *.tr* trace/")
puts "Job Done!"
out.close
