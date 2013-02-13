#大队列，所有包都不需要排队等待
#非瓶颈带宽设大，所有包发送没有延迟
#设定延时 丢包 带宽 启动窗口
set rtt [lindex $argv 0]
set loss_rate [lindex $argv 1]
set bandwidth [lindex $argv 2]
set object [lindex $argv 3]

puts "Usage: ns file <rtt> <loss_rate> <bandwidth> <object>"
puts "rtt: $rtt ms"
puts "loss_rate: $loss_rate 0.01 == 1%"
puts "bandwidth: $bandwidth Mbps"
puts "object: $object B"
puts "$rtt-$loss_rate-$bandwidth-$object-littlecwnd"
#Create a simulator object
set ns [new Simulator]

set rtype DropTail

#设定fin为大于522的值时，华为给定的最差场景才能按时跑完
set fin 10000
set num_btnk       1 ;# number of bottleneck(s)

set btnk_bw       $bandwidth ;# bottleneck capacity, Mbps
set rttp          $rtt ;# round trip propagation delay, ms

set num_ftp_flow   1 ;# num of long-lived flows, forward path
set num_rev_flow   0 ;# num of long-lived flows, reverse path
set sim_time       100 ;# simulation time, sec

set non_btnk_bw       [expr $btnk_bw * 2] ;# Mbps
set btnk_delay        [expr 2*$rttp * 0.5 * 0.8]
set non_btnk_delay    [expr 2*$rttp * 0.5 * 0.2 / 2.0]
set btnk_buf_bdp      1.0 ;# measured in bdp
set btnk_buf          [expr $btnk_buf_bdp * $btnk_bw * $rttp / 8.0] ;
# in 1KB pkt

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red

#Open the NAM trace file
#set nf [open $rtt-$loss_rate-$bandwidth-$object-littlecwnd.nam w]
#$ns namtrace-all $nf

#Open trace file
set f [open $rtt-$loss_rate-$bandwidth-$object-bigcwnd.trace w]
$ns trace-all $f

set pf [open $rtt-$loss_rate-$bandwidth-$object-bigcwnd.trace w]

#Define a 'finish' procedure
proc finish {} {
        global ns pf f rtt loss_rate bandwidth object
        $ns flush-trace
        #Close the NAM trace file
        close $pf
	close $f
        #Execute NAM on the trace file
       # exec nam $rtt-$loss_rate-$bandwidth-$object-littlecwnd.nam &
        exit 0
}

#Create four nodes
set node0 [$ns node]
set node1 [$ns node]
set node2 [$ns node]
set node3 [$ns node]

#Create links between the nodes
$ns duplex-link $node0 $node1 [expr $btnk_bw]Mb [expr $btnk_delay]ms DropTail
$ns duplex-link $node2 $node0 100Mb [expr $non_btnk_delay]ms DropTail
$ns duplex-link $node1 $node3 100Mb [expr $non_btnk_delay]ms DropTail


#$ns queue-limit $node0 $node1 [expr $btnk_buf]	#这里的btnk_buf是分组个数
$ns queue-limit $node0 $node1 500	
#btnk_buf > 10时，queue-limit设置为此值，否则设为10
#if {$btnk_buf > 10} {
#	$ns queue-limit $node0 $node1 [expr $btnk_buf]
#} else {
#	$ns queue-limit $node0 $node1 10
#}

set queue [[$ns link $node0 $node1] queue]

if {![catch "$queue attach $pf" ]} {
        #$queue trace pos_
}

set TCPtraceFile [open $rtt-$loss_rate-$bandwidth-$object-bigcwnd.tr w]

###############设定丢包率#####################
# 产生一个loss module
set em [new ErrorModel]
# 设定是以packet 为处理单位
$em unit pkt
# 设定error rate 为0.01
$em set rate_ [expr 2*$loss_rate]
# 设定发生错误为Uniform Distribution
$em ranvar [new RandomVariable/Uniform]
# 设定发生错误时的动作是丢弃封包
$em drop-target [new Agent/Null]

# 指定发生错误的Link 是在n1 到n2 之间
$ns lossmodel $em $node0 $node1
##############################################

#setup sender side	
###############设置启动窗口##################
###############韩瑞 2012-12-25 16：16########
set tcp [new Agent/TCP/Sack1]

############################################
$tcp set windowInit_ 1000	
$tcp set windowOption_ 1
############################################
$tcp set newCA_ 1
$tcp set packetSize_ 1460
#$tcp set trace_all_oneline_ 1
#$tcp tracevar rtt_
$tcp tracevar cwnd_ 
#$tcp tracevar ssthresh_

$tcp attach $TCPtraceFile
$ns attach-agent $node2 $tcp

#set up receiver side
set sink [new Agent/TCPSink/Sack1]
$sink set ts_echo_rfc1323_ true
$ns attach-agent $node3 $sink
#logical connection
$ns connect $tcp $sink

#Setup a FTP over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

#Start FTP 
#$ns at 0.2 "$ftp start"
$ns at 0 "$ftp send $object"
$ns at $fin "$ftp stop"
$ns at [expr $fin + 1] "finish"

$ns run
