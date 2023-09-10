#!/usr/bin/wish
#
#NAME
#  Pings - run a set of pings in parallel
#
#SYNOPSIS
#  Pings [host]... &
#
#DESCRIPTION
#  This program manages a window that shows a list of  hosts,  and  starts  a
#  ping  subprocess  for  each of them.  The responses are shown, and you can
#  turn individual pings on and off.
#
#  Fill in one or more host names or IP addresses, press Return or the "ping"
#  button  at the left, and a ping process will be started for that host.  As
#  responses come in, the numbers at the right will be  updated.   Press  the
#  "stop" button to stop the pinging.
#
#  The entry widget labelled "Hosts:" is the number of rows in the table. You
#  can type a different number, press Return, and  the  table's  height  will
#  change.
#
#NEEDS
#  This program wants the following modules, which  should  be  in  the  same
#  place that you found this program:
#
#    Help.w     An interactive Help facility.
#    Verbose.w  Verbose/debug/log output control.
#
#  You can specify which programs to use:
#
#	set pinger "/bin/ping 2>&1"
	set pinger "unbuffer /bin/ping"
	set killer "/bin/kill -TERM 2>&1"
	set tracer "traceroute 2>&1"
#
#  If your ping needs any options to make it keep pinging forever,  add  them
#  to  the  above command.  Most versions of ping now do this by default, but
#  some just ping once and exit.
#
#  Create the default host lists here.  You can use any of these names on the
#  command line, and the obvious thing will happen.  The default list is used
#  if there are no names on the command line.  Note the +p option, which will
#  cause pinging to start automatically when a list is selected. You can also
#  use -p to disable automatic pinging for a set of hosts. Using {} creates a
#  row that is initially blank.
#
	set hosts(default) {localhost {} {} {} {}}
	set hosts(kendy) {jc.tzo.net}
	set hosts(world) {
		std1 vd kendy
		airport AP100 AP101 AP102 AP103
		66.92.73.1
		4.2.2.1
		trillian.mit.edu eddie.mit.edu www.mit.edu world.std.com
		sourceforge.net www.ceolas.org www.sun.org www.tullochgorm.com 
		home.swipnet.se medlem.spray.se termen.free.fr www.comhaltas.com www.leeds.ac.uk
		home.primus.com.au homepages.ihug.co.nz web.kyoto-inet.or.jp
	}
	set hosts(MIT) {+p www.mit.edu B24-RTR-2-BACKBONE.MIT.EDU B24-RTR-2-RLE-ETHER.MIT.EDU trillian.mit.edu eddie.mit.edu}
	set hosts(NTL) {ob1 ob2 ob3 ob4 ob5 ob6 ob-in linux6w nitro1 localhost jc.tzo.net +p}
	set hosts(apple) {www.apple.com}
	set hosts(search) {AllTheWeb.com AltaVista.com google.com teoma.com yahoo.com}
#
#  You can also specify the IP address of hosts:
#
# crcnet machines:
#
	set ipad(ob1) 64.28.81.46
	set ipad(ob2) 64.28.81.67
	set ipad(ob3) 64.28.81.70
	set ipad(ob4) 64.28.81.71
	set ipad(ob5) 64.28.81.68
	set ipad(ob6) 64.28.81.69
	set ipad(linux6w) 64.28.81.37
	set ipad(localhost) 127.0.0.1
	set ipad(nitro1) 64.28.81.39
#
#OPTIONS
#  Options start with '+' for "enable" and '-' for "disable".
#
#  +p Start by pinging all hosts on command line.  -p Start with  no  pinging
#  active.
#
#TraceRoute
#  The Cmds menu has a TraceRoute and a Trace+Ping entry. What these do is to
#  start  up a traceroute to the first host, and accumulate the list of hosts
#  along the path.  When the traceroute process exits,  this  information  is
#  used  to  build a new host table.  The Trace+Ping will also fire up a ping
#  for each of them.
#
#  At present, we can only do this for the first host, and the host table  is
#  overwritten with the new list.  Perhaps it would be more useful to fire up
#  a new Pings window for this.
#
#SEE ALSO
#  ping(8), traceroute(8)
#
#AUTHOR John Chambers <jc@trillian.mit.edu>
#  If you make any significant changes or extensions to this program, let  me
#  know,  and I'll consider adding them to my copy.  I've tested this only on
#  unix-like systems and it may not run on other systems.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

set msg {};		# Message displayed in .m widget
set msglim  60;	# Erase .m widget after this time
set msglines 0;	# Lines believed to be in .msg now
set msgtim   0;	# Time of last message
set me Pings;	# Our display name
if [info exists env(V_$me)] {set V $env(V_$me)} else {set V 1}
if {$V>1} {
	puts "$me: Started with V=$V."
}
set host [exec hostname]
wm title . "Pings from $host"


set path  [split $env(PATH) :]
foreach f {Help.w Verbose.w} {
	foreach d $path {
		if [file readable $d/$f] {
			if {$V>1} {puts "$me: source $d/$f"}
			source $d/$f
			break
}	}	}
if ![info exists pinger] {
	foreach d $path {
		if [file executable $d/ping] {
			if {$V>1} {puts "$me: Ping program is $d/ping"}
			set pinger $d/ping
			break
}	}	}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

proc Color {} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# The Color loop wakes up every 10 seconds, and colors various time values to #
# indicate how long it's been since the last response from that host.         #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V BG me time now pings T pid tod clohst chihst clotod chitod sta
	set id "$me/Color"
	if {$V>4} {Msg $V "$id: Called."}
	for {set r 1} {$r <= $pings} {incr r} {
		if {$V>3} {Msg $V "Color: Row $r pid=\"$pid($r)\" tod=\"$tod($r)\""}
		if {[info exists pid($r)] && ($pid($r) != {})} {
			set i [expr {$now-$T($r)}]
			set c [colorval $i $clotod $chitod]
			if {$V>3} {Msg $V "Color: Row $r Color $c ($i $clohst $chihst)"}
			if [winfo exists .d.tod$r] {.d.tod$r config -fg $c}
			if {$sta($r) == {}} {
				if [winfo exists .d.sta$r] {.d.sta$r config -fg $c}
				if {$i <= $clotod} {
					set sta($r) OK
				} elseif {$i >= $chitod} {
					if {$i > [expr ($chitod*0)]} {
						set sta($r) DEAD
					} else {
						set sta($r) SLOW
					}
				} else {
					set sta($r) slow
				}
			}
		} else {
			if [winfo exists .d.tod$r] {.d.tod$r config -fg cyan}
			set sta($r) {???}
			.d.tod$r config -fg cyan
		}
	}
	after 10000 Color
}

proc Host {r h a} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Set up a new host in row r.  We expect the host name  and  possibly #
# its IP address.  The rest of the fields are blanked.                #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me adr hst ipad pid pinging pings rows tim seq ttl av sta
	global lsn lsr
	set id "$me/Host"
	if {$V>4} {Msg $V "$id: Called."}
	if {$a == {}} {
		if {$V>1} {Msg $V "$id: No address"}
		if [info exists ipad($h)] {
			if {$V>1} {Msg $V "$id: Use ipad($h)=\"$ipad($h)\""}
			set a $ipad($h)
		}
	}
	if {$V>1} {Msg $V "$id: Create row $r of $rows for host \"$h\" address \"$a\""}
	if [info exists pid($r)] {if {$pid($r) > 0} {PingStop $r}}
	if {$r > $pings} {set pings $r; Resize}
	set hst($r) [string tolower $h]
	set adr($r) $a
	set tim($r) [hhmmss $r]
	set seq($r) {}
	set ttl($r) {}
	set lsn($r)   0;	# Lost-packet count
	set lsr($r) 100;	# Lost-packet rate
	set av(0,$r) {}
	set av(1,$r) {}
	set av(2,$r) {}
	set av(3,$r) {}
	set sta($r) {}
	if {$V>1} {Msg 2 "Host \"$h\" addr \"$a\" put in row $r."}
#	update idletasks
	if {$pinging && $a != "?"} {PingInit $r}
}

proc Resize {} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Here we resize the window so that $pings rows are showing.  We  use #
# $rows  to  hold the actual number of rows on the screen, and $pings #
# to hold the highest row number that we are pinging.  This Msg $V  the #
# two numbers in sync.                                                #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V BB BE BG BL me fil pid hst adr seq ttl rsp sta tod pings rows
	set id "$me/Resize"
	if {$V>4} {Msg $V "$id: Called."}
	if {$V>1} {Msg $V "$me/Resize: Change row count from $rows to $pings ..."}
	while {$rows < $pings} {
		set r [incr rows]
		if ![winfo exists .d.lbl$r] {
			if {$V>1} {Msg $V "$me/Resize: Row $rows must be created.."} 
			RowCreate $r
		} else {
			if {$V>1} {Msg $V "$me/Resize: Row $rows exists."} 
		}
	}
	while {$rows > $pings} {
		if {$V>1} {Msg $V "$me/Resize: Erase row $rows > pings $pings."}
		PingStop $rows
		RowDestroy $rows
		incr rows -1
	}
	wm geometry . {}
}

proc RowCreate {r} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V BB BE BG BL me fil pid hst adr seq ttl av rsp sta tod pings rows
	global lsn lsr
	set id "$me/RowCreate"
	if {$V>4} {Msg $V "$id: Called for row $r."}
	if ![info exists adr($r)] {set adr($r) {}}
	if ![info exists fil($r)] {set fil($r) {}}
	if ![info exists hst($r)] {set hst($r) {}}
	if ![info exists pid($r)] {set pid($r) {}}
	if ![info exists seq($r)] {set seq($r) {}}
	if ![info exists ttl($r)] {set ttl($r) {}}
	if ![info exists av(0,$r)] {set av(0,$r) {}}
	if ![info exists av(1,$r)] {set av(1,$r) {}}
	if ![info exists av(2,$r)] {set av(2,$r) {}}
	if ![info exists av(3,$r)] {set av(3,$r) {}}
	if ![info exists sta($r)] {set sta($r) {}}
	if ![info exists lsn($r)] {set lsn($r) 0}
	if ![info exists lsr($r)] {set lsr($r) 100}
	if ![info exists rsp($r)] {set rsp($r) {}}
	if ![info exists tod($r)] {set tod($r) {}}
	if {$V>1} {Msg $V "$id: r=$r hst=\"$hst($r)\" adr=\"$adr($r)\""}
	eval label  .d.lbl$r $BL -text $r -relief flat
	eval button .d.cmd$r $BB -text ping -width 4 -command {"PingInit $r"}
	eval entry  .d.hst$r $BE -textvariable hst($r) -width 0
	eval entry  .d.adr$r $BE -textvariable adr($r) -width 0 -fg white
	eval label  .d.pid$r $BL -textvariable pid($r) -relief flat
	eval label  .d.tod$r $BL -textvariable tod($r) -fg white -bg $BG
	eval label  .d.seq$r $BL -textvariable seq($r) -relief flat
	eval label  .d.lsn$r $BL -textvariable lsn($r) -relief ridge -bd 2
	eval label  .d.lsr$r $BL -textvariable lsr($r) -relief ridge -bd 2
	eval label  .d.av0$r $BL -textvariable av(0,$r) -relief ridge -bd 2
	eval label  .d.av1$r $BL -textvariable av(1,$r) -relief ridge -bd 2
	eval label  .d.av2$r $BL -textvariable av(2,$r) -relief ridge -bd 2
	eval label  .d.av3$r $BL -textvariable av(3,$r) -relief ridge -bd 2
	eval label  .d.rsp$r $BL -textvariable rsp($r) -relief flat
	eval label  .d.sta$r $BL -textvariable sta($r) -relief ridge -bd 2
	grid .d.lbl$r -in .d -row $r -column  0 -sticky  e
	grid .d.cmd$r -in .d -row $r -column  1
	grid .d.hst$r -in .d -row $r -column  2 -sticky we
	grid .d.adr$r -in .d -row $r -column  3 -sticky we
	grid .d.pid$r -in .d -row $r -column  4 -sticky  e
	grid .d.tod$r -in .d -row $r -column  5 -sticky we
	grid .d.seq$r -in .d -row $r -column  6 -sticky  e
	grid .d.lsn$r -in .d -row $r -column  7 -sticky  e
	grid .d.lsr$r -in .d -row $r -column  8 -sticky  e
	grid .d.av0$r -in .d -row $r -column  9 -sticky  e
	grid .d.av1$r -in .d -row $r -column 10 -sticky  e
	grid .d.av2$r -in .d -row $r -column 11 -sticky  e
	grid .d.av3$r -in .d -row $r -column 12 -sticky  e
	grid .d.rsp$r -in .d -row $r -column 13 -sticky  w
	grid .d.sta$r -in .d -row $r -column 14 -sticky  w
	bind .d.hst$r <Return> "set adr($r) {}; Host $r \$hst($r) \$adr($r)"
	bind .d.adr$r <Return> "Host $r \$adr($r) \$adr($r); PingInit $r"
#	update idletasks
}

proc RowDestroy {r} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V BB BE BG BL me fil pid hst adr seq ttl rsp sta tod pings rows
	set id "$me/RowDestroy"
	if {$V>1} {Msg $V "$id: Called for row $r."}
	if [winfo exists .d.lbl$r] {destroy .d.lbl$r}
	if [winfo exists .d.cmd$r] {destroy .d.cmd$r}
	if [winfo exists .d.hst$r] {destroy .d.hst$r}
	if [winfo exists .d.adr$r] {destroy .d.adr$r}
	if [winfo exists .d.pid$r] {destroy .d.pid$r}
	if [winfo exists .d.tod$r] {destroy .d.tod$r}
	if [winfo exists .d.seq$r] {destroy .d.seq$r}
	if [winfo exists .d.lsn$r] {destroy .d.lsn$r}
	if [winfo exists .d.lsr$r] {destroy .d.lsr$r}
	if [winfo exists .d.av0$r] {destroy .d.av0$r}
	if [winfo exists .d.av1$r] {destroy .d.av1$r}
	if [winfo exists .d.av2$r] {destroy .d.av2$r}
	if [winfo exists .d.av3$r] {destroy .d.av3$r}
	if [winfo exists .d.rsp$r] {destroy .d.rsp$r}
	if [winfo exists .d.sta$r] {destroy .d.sta$r}
#	update idletasks
}

proc PingAll s {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me pings
	set id "$me/PingAll"
	if {$V>4} {Msg $V "$id: Called."}
	for {set i 1} {$i <= $pings} {incr i} {
		if {$V>1} {Msg $V "$id: \"$s\""}
		eval "Ping$s $i"
		update
	}
}

proc PingInit r {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Start pinging for the host in row r, if possible.  
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V msg me adr hst
	set id "$me/PingInit"
	if {$V>4} {Msg $V "$id: Called for r=$r."}
	if ![info exists adr($r)] {set adr($r) {}}
	if ![info exists hst($r)] {set hst($r) {}}
	if {$V>1} {Msg $V "$id: row $r hst=\"$hst($r)\" adr=\"$adr($r)\""}
	if {"$hst($r)$adr($r)" == {} } {
		if {$V>1} {Msg 2 "$id: Row $r is empty"}
	} else {
		if {$V>1} {Msg 2 "$id: Row $r '$hst($r)' '$adr($r)'"}
		PingHost $r $hst($r) $adr($r)
	}
}

proc PingHost {r h a} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Ping the host in row n. The host name and address are compared with #
# the values in row n, and if they differ, we re-create the row.      #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V msg me adr cmd fil hst int killer pid rsp seq T ttl tod pinger
	global lsn lsr
	if {$V>1} {Msg $V "$me/PingHost $r ..."}
	if [info exists pid($r)] {
		if {$V>1} {Msg $V "$me: PID pid($r)=\"$pid($r)\" fil($r)=\"$fil($r)\"."}
#		if {$pid($r) != {}} {
#			set killcmd "$killer $pid($r)"
#			if [catch {exec $killcmd} m] {Msg 2 "\"$killcmd\" gave \"$m\""}
#			set pid($r) {}
#		}
		if {$fil($r) != {}} {
			if [catch {close $fil($r)} m] {if {$V>1} {Msg $V "$me: \"close $fil($r)\" gave \"$m\""}}
			set fil($r) {}
		}
	}
	if {![info exists hst($r)] || ($hst($r) != $h)} {Host $r $h $a}
	if {$a == {}} {
		set cmd($r) "$pinger -n -i $int $hst($r)"
	} else {
		set cmd($r) "$pinger -n -i $int $a"
	}
	if {$V>1} {Msg $V "$me: cmd($r) \"$cmd($r)\""}
#	set rsp($r) $cmd($r)
	if [catch {open "| $cmd($r)"} file] {
		Msg 2 $file
		set cmd($r) "$pinger -i $int $adr($r)"
		if [catch {open "| $cmd($r)"} file] {
			Msg 2 $file; return
		}
	}
	if [catch {fconfigure $file -blocking off} err] {
		Msg 1 "Can't fconfigure $file -blocking off ($err)"
	}
#	set adr($r) {}
	set fil($r) $file
	set pid($r) [pid $file]
#	set tod($r) [hhmmss [set T($r) [clock seconds]]]
	set tod($r) 00:00:00
	set T($r)     0
	set lsn($r)   0
	set lsr($r) 100
	if {$V>1} {Msg $V "$me: fil($r)=\"$fil($r)\" pid($r)=$pid($r)."}
#	update idletasks
	if [winfo exists .d.cmd$r] {
		.d.cmd$r config -text stop -command "PingStop $r"
		if {$V>2} {Msg $V "$me: .d.cmd$r changed to \"stop\""}
	} else {
		Msg 2 "### .d.cmd$r doesn't exist ###"
		update idletasks
	}
	fileevent $file readable "pingrsp $r $file"
}

proc PingStop {n} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Terminate the ping process in row n.  If there isn't one, this proc #
# should do nothing.                                                  #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me adr fil hst int killer pid pinger pingopts rsp seq tod ttl
	if {$V>1} {Msg $V "$me/PingStop: Called for ping n=$n."}
	if [info exists pid($n)] {
		if {$pid($n) != {}} {
			if {$V>1} {Msg $V "$me: PID pid($n) is $pid($n)."}
			catch "exec $killer $pid($n)"
			set pid($n) {}
			if [winfo exists .d.cmd$n] {
				.d.cmd$n config -text ping -command "$pinger -n -i $int $n {}"
			}
		}
	}
}

proc hhmmss n {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global T
	return [clock format [set T($n) [clock seconds]] -format %H:%M:%S]
}

proc Restart {} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Kill off all running ping processes and restart them.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me hst pid pings
	set id "$me/Restart"
	if {$V>4} {Msg $V "$id: Called."}
	set id "$me/Restart"
	for {set r 1} {$r <= $pings} {incr r} {
		if {$pid($r) > 0} {
			if {$V>1} {Msg $V "$id: Pinging hst($r)=$hst($r)."}
			PingStop $r
			PingInit $r
		} else {
			if {$V>1} {Msg $V "$id: Not pinging hst($r)=$hst($r)."}
		}
	}
}

proc OnTop w {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Do whatever we know to make sure that a window is  visible  on  the #
# screen.  We do assume that the window exists.                       #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V
	if {$V>2} {Msg $V "OnTop $w"}
	wm deiconify $w
	raise $w
}

proc Open w {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Open up a window that might be closed.  Note that we don't try to #
# create the window.  We just try to make sure that it's open.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V
	if {$V>1} {Msg $V "Open $w"}
	wm deiconify $w
}

proc Raise w {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Raise a window to the top of the stack.  Actually, all we really want is to #
# make sure that it's visible, and this is the simplest way to do that.  Note #
# that we might also want to call "Open $w",  because  raising  an  iconified #
# window may not be sufficient.                                               #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V
	if {$V>1} {Msg $V "Raise $w"}
	raise $w
}

proc byebye x {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me
	if {$V>0} {Msg 1 {Closing all pings ...}}
	PingAll Stop
	if {$V>0} {Msg 1 {Good-bye!}}
	update idletasks
	after $V
	exit $x
}

proc cfgwin {} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me BB BG
	if [winfo exists .cfg] {
		OnTop .cfg
	} else {
		if {$V>1} {Msg $V "Create .cfg window."}
		toplevel .cfg
		wm title .cfg "$me cfg"
		set X [winfo pointerx .]
		set Y [winfo pointery .]
		wm geometry .cfg +[incr X 5]+[incr Y 5]
#	
		frame .cfg.rows -bg $BG -bd 3 -relief ridge
		pack .cfg.rows -in .cfg -side top -fill x -expand 1
		eval menubutton .cfg.rows.lbl -text Rows $BB -menu .cfg.rows.lbl.menu
		pack  .cfg.rows.lbl -in .cfg.rows -side left
		entry .cfg.rows.val -textvariable pings -bd 2 -relief ridge -fg cyan -bg $BG -width 5 -justify right -highlightthickness 0
		bind  .cfg.rows.val <Return> {Resize}
		pack  .cfg.rows.val -in .cfg.rows -side right
		menu .cfg.rows.lbl.menu
		.cfg.rows.lbl.menu add command -label incr -command {incr pings; Resize}
		.cfg.rows.lbl.menu add command -label decr -command {incr pings -1; Resize}
		BindHelp .cfg.rows \
	{Edit the number and hit Return to change the number of visible rows.
	Use the Rows menu to increment or decrement the row count. }
#	
		frame .cfg.int -bg $BG -bd 3 -relief ridge
		label .cfg.int.lbl -text Delay -fg white -bg $BG -pady 0
		pack  .cfg.int.lbl -in .cfg.int -side left
		label .cfg.int.unit -text sec -fg white -bg $BG -pady 0
		pack  .cfg.int.unit -in .cfg.int -side right
		entry .cfg.int.val -textvariable int -bd 2 -relief ridge -fg cyan -bg $BG -width 5 -justify right -highlightthickness 0
		bind  .cfg.int.val <Return> Restart
		pack  .cfg.int.val -in .cfg.int -side right
		pack  .cfg.int -in .cfg -side top -fill x -expand 1
		BindHelp .cfg.int \
	{The Delay is the time between pings to each host.
	Change the Delay and press Return to change the ping rate.}
#	
		frame .cfg.msclr -bg $BG -bd 0 -relief ridge
		label .cfg.msclr.lbl -text {response speed (ms)} -fg white -bg $BG -pady 0
		pack  .cfg.msclr.lbl -in .cfg.msclr -side left
		label .cfg.msclr.unit -text ms -fg white -bg $BG -pady 0
		pack  .cfg.msclr.unit -in .cfg.msclr -side right
		entry .cfg.msclr.vhi -textvariable chihst -bd 2 -relief ridge -fg #F06  -bg $BG -width 5 -justify right -highlightthickness 0
		bind  .cfg.msclr.vhi <Return> Restart
		pack  .cfg.msclr.vhi -in .cfg.msclr -side right
		entry .cfg.msclr.vlo -textvariable clohst -bd 2 -relief ridge -fg #0F0 -bg $BG -width 5 -justify right -highlightthickness 0
		bind  .cfg.msclr.vlo <Return> Restart
		pack  .cfg.msclr.vlo -in .cfg.msclr -side right
		pack  .cfg.msclr     -in .cfg -side top -fill x -expand 1
		BindHelp .cfg.msclr \
	{The "ms" column is the response time for each host.
	The numbers control the color change from green to red.
	Responses faster than the first time will be green.
	Responses slower than the second time will be red.
	Response times between will be shades of yellow.}
#	
		frame .cfg.tmclr -bg $BG -bd 0 -relief ridge
		label .cfg.tmclr.lbl -text {last response (when)} -fg white -bg $BG -pady 0
		pack  .cfg.tmclr.lbl -in .cfg.tmclr -side left
		label .cfg.tmclr.unit -text sec -fg white -bg $BG -pady 0
		pack  .cfg.tmclr.unit -in .cfg.tmclr -side right
		entry .cfg.tmclr.vhi -textvariable chitod -bd 2 -relief ridge -fg #F06  -bg $BG -width 5 -justify right -highlightthickness 0
		bind  .cfg.tmclr.vhi <Return> Restart
		pack  .cfg.tmclr.vhi -in .cfg.tmclr -side right
		entry .cfg.tmclr.vlo -textvariable clotod -bd 2 -relief ridge -fg #0F0 -bg $BG -width 5 -justify right -highlightthickness 0
		bind  .cfg.tmclr.vlo <Return> Restart
		pack  .cfg.tmclr.vlo -in .cfg.tmclr -side right
		pack  .cfg.tmclr     -in .cfg -side top -fill x -expand 1
		BindHelp .cfg.tmclr \
{The "when" column is when we last heard about each host.
The range is in seconds, and the two numbers control
the color change from green through yellow to red.}
#	
		Raise .cfg
	}
}

proc colorval {c l h} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Calculate a color value in the green-yellow-red spectrum.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V BG me B
	set id "$me/colorval"
	if {$V>4} {Msg $V "$id: Called."}
	set m [expr {($h-$l)/2.0}]
	if {$c <= $l} {
		set G 15
		set R 0
#		set B 8
		if {$V>3} {Msg $V "colorval: R=$R G=$G (val=$c <= $l < $m < $h)"}
	} elseif {$c >= $h} {
		set R 15
		set G 0
#		set B 8
		if {$V>3} {Msg $V "colorval: R=$R G=$G ($l < $m < $h <= val=$c)"}
	} elseif {$c < $m} {
		set G 15
		set num [expr {$c-$l}]
		set den [expr {$m-$l}]
		set R [expr {int(15*$num/$den)}]
#		set B 8
		if {$V>3} {Msg $V "colorval: R=$R G=$G num=$num den=$den ($l < val=$c < $m < $h)"}
	} else {
		set G [expr {int((15*($h-$c))/($h-$m))}]
		set R 15
#		set B 8
		if {$V>3} {Msg $V "colorval: R=$R G=$G ($l < $m < val=$c < $h)"}
	}
	return [format {#%X%X%X} $R $G $B]
}

proc setColors {r} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V BG me adr d fil time hst msg msgtim now pid seq ttl av clohst chihst chitod rsp sta T tod
	set id "$me/setColors"
	if {$V>4} {Msg $V "$id: Called."}
	if [winfo exists .d.av0$r] {
		set d $av(0,$r)
		set col [colorval $d $clohst $chihst]
		if {$V>2} {Msg $V "Row $r color $col"}
		.d.hst$r config -fg $col
		.d.av0$r config -fg $col
		.d.sta$r config -fg $col
		if {$d <= $clohst} {
			set sta($r) OK
		} elseif {$d >= $chihst} {
			if {[expr {$now-$T($r)-$chitod}] > 0} {
				set sta($r) DEAD
			} else {
				set sta($r) SLOW
			}
		} else {
			set sta($r) slow
		}
	} else {
		Msg 1 "Row $r missing."
	}
}

proc pingrsp {r f} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# This routine handles a single response from a ping process.  We  only  read #
# one  line  and process it, so if a response has more than one line, we must #
# cache its data and set enough global state that we can recognize  where  we #
# are when the second line arrives.                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V BG me adr av avcnt clohst chihst fil hst lsn lsr \
		msg msglim msgtim pid rsp seq sta T time tod ttl
	set id "$me/pingrsp"
	if {$V>4} {Msg $V "$id: Called."}
	if {$V>3} {Msg $V "$id: r=$r f=$f"}
	if {$V>2} {Msg $V "$id: Read a line <===================="}
	if {[gets $f line] >= 0} {
		if {$V>3} {Msg $V "$id: GOT \"$line\""}
		regsub {^[0-9]+ bytes.*: icmp_} $line {} line
#		set rsp($r) $line
#		set tod($r) [hhmmss 0]
		set tod($r) $time
		if {$adr($r) == {}} {
			Msg 4 $line
			if [regexp {^PING[ 	]+.*[ 	]+\(([0-9.]+)\):} $line {} addr] {
				set adr($r) $addr
			} elseif [regexp {^PING[ 	]+.*[ 	]+\(([0-9.]+)\) from} $line {} addr] {
				set adr($r) $addr
			}
		}
		if [regexp {seq=([0-9]*) ttl=([0-9]*) time=([0-9.]*) ms} $line {} sq tl dl] {
			if {[set loss [expr $sq-$seq($r)-1]] > 0} {
				incr lsn($r) $loss
				Msg 2 "Row $r lost $loss packets (seq($r)=$seq($r) sq=$sq)"
			}
			set lsr($r) [expr int(($lsn($r)*100)/($sq+1))]
			set seq($r) $sq;	# Remember the last packet sequence number received
			set ttl($r) $tl;	# Do we use the TTL value?
			set av(0,$r) $dl;	# Average "zero" is the last value
			set sta($r) OK;		# Status becomes OK whenever we get an echo
			# Here we implement an "exponential decay" series of averages:
			set rat 10;				# Delay ratio
			set mul [expr $rat-1];	# Multiply previous value by this much
			set div [set rat]0.0;	# and divide by this much
			for {set i 0} {$i < $avcnt} {incr i} {
				set j [expr $i+1]
				if {[set av($j,$r)] == {}} {
					set av($j,$r) $dl;	# No average yet; set it to first value
				} else {;			# Calculate the decaying averages:
					set av($j,$r) [expr {int((([set av($i,$r)] + $mul * [set av($j,$r)] + 1) * 10.0) / $div)}]
				}
			}
			setColors $r
			.d.av1$r config -fg [colorval $av(1,$r) $clohst $chihst]
			.d.av2$r config -fg [colorval $av(2,$r) $clohst $chihst]
			.d.av3$r config -fg [colorval $av(3,$r) $clohst $chihst]
			set T($r) [clock seconds]
			set TT [expr {$T($r) - $msgtim}]
			if {$TT > $msglim} {set msg "Point at something and press Help or F1 for help."}
		} elseif [regexp {Destination Host Unreachable} $line] {
			Msg 1 "Unreachable: $r $hst($r) $adr($r)"
#			PingStop $r
			set sta($r) unreachable
			.d.sta$r config -fg cyan
		} else {
			set seq($r) ---
			set ttl($r) ---
			set av(0,$r) ---
			set av(1,$r) {}; .d.av2$r config -fg cyan
			set av(2,$r) {}; .d.av2$r config -fg cyan
			set av(3,$r) {}; .d.av3$r config -fg cyan
			set sta($r) {???}
			.d.sta$r config -fg cyan
		}
	} else {
		if {$V>1} {Msg $V "$id: EOF."}
		if [catch {close $fil($r)} m] {
			if {$V>1} {Msg $V "$id: \"close $fil($r)\" gave \"$m\""; Msg 1 $m}
			set sta($r) killed
		}
		set fil($r) {}
		set pid($r) {}
		if [winfo exists .d.cmd$r] {.d.cmd$r config -text ping -command "PingInit $r"}
	}
}

proc Msg {l m} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Put message into .msg widget.  At verbose level l and higher, we also write #
# it to our log output. We also note the time, so we can clear stale messages #
# out of the message widget.                                                  #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me msg msgtim msglines
	if {$V>1} {puts "Msg: l=$l m={$m}"}
# Level-1 messages go to main window's msg widget
	if {$l <= $V} {
#		puts "Msg: $m"
		set msg $m
		set msgtim [clock seconds]
	}
# Everything goes to either the .msg window or to stdout
	if [winfo exists .msg] {
		update idletasks; set y1 [.msg.t.vscr get]; if {$V>2} {puts "Msg: get y1={$y1}"}
		if {$msglines != 0} {
			.msg.t.text insert end "\n"
		}
		.msg.t.text insert end $m
		incr msglines
#		update idletasks; set y2 [.msg.t.vscr get]; if {$V>2} {puts "Msg: get y2={$y2}"}
#		set xx [.msg.t.vscr get]
#		if {$V>1} {puts "Msg: xx={$xx} (get)"}
		if {[lindex $y1 1] == 1.0} {
#			if {$V>2} {puts "Msg: see end because y1={$y1}"}
			.msg.t.text see end
		}
#		update idletasks; set y3 [.msg.t.vscr get]; if {$V>2} {puts "Msg: get y3={$y3}"}
	} elseif {$V>1} {
		puts $m
	}
}

proc msgclear {} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Clear out the .msg text window. Note that we also zero out our line counter #
# for this box.                                                               #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global msglines
	.msg.t.text delete 1.0 end
	set msglines 0
}

proc msgwin {} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Create the message window.  If it already exists, we just raise it to the #
# top to make it visible.  If it doesn't exist, we have to create it.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me BB BG BL
	if ![winfo exists .msg] {
		if {$V>1} {Msg $V "Create .msg window."}
		toplevel .msg
		wm title .msg "$me messages"
		set X [winfo pointerx .]
		set Y [winfo pointery .]
		wm geometry .msg +[incr X 5]+[incr Y 5]
#	Message window created; create its widgets
		eval frame  .msg.b -bg $BG; # Button bar
		eval button .msg.b.clear -text clear $BB -command msgclear
#
		eval frame .msg.t -bg $BG; # Text + scrollbar
		eval text  .msg.t.text $BL -height 15 -width 90 -yscrollcommand {{.msg.t.vscr set}}
		scrollbar  .msg.t.vscr -command {.msg.t.text yview} -width 8
#
		pack .msg.b.clear -in .msg.b 
		pack .msg.b       -in .msg   -fill x    
		pack .msg.t.vscr  -in .msg.t -fill y    -side right
		pack .msg.t.text  -in .msg.t -fill both -side left   -expand 1
		pack .msg.t       -in .msg   -fill both -side bottom -expand 1
		Msg 1 "Message log for '$me'"
	}
	OnTop .msg
}

proc Trace {} { set id "$me/Trace"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# The "Trace" menu item merely creates a new line at the bottom where #
# you can enter a host or address to trace. You can use Return or the #
# little menu to trigger the traceroute command,  and  then,  as  the #
# responses come in, we will build the table of intermediate hosts.   #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V BG me hst killer tracehost
	if {$V>4} {Msg $V "$id: Called."}
	if [winfo exists .trace] {
		OnTop .trace
	} else {
		if {$V>1} {Msg $V "$id: Create .trace window."}
		toplevel .trace
		frame .trace.h -bg $BG
		menubutton .trace.h.cmds -text Host: -menu .trace.h.cmds.menu -fg yellow -bg $BG -bd 0 -pady 0
		menu  .trace.h.cmds.menu
		entry .trace.h.host -textvariable tracehost
		pack  .trace.h.cmds -in .trace.h -side left
		pack  .trace.h.host -in .trace.h -side left -fill x -expand 1
		pack  .trace.h -in .trace -side top -fill x -expand 1
		frame .trace.b -bg $BG
		button .trace.b.tr -text {trace}      -command {TraceRoute 0 $tracehost}
		button .trace.b.tp -text {trace+ping} -command {TraceRoute 1 $tracehost}
		button .trace.b.cl -text {dismiss}    -command {destroy .trace}
		pack   .trace.b.tr .trace.b.tp .trace.b.cl -in .trace.b -side left -expand 1
		pack  .trace.b -in .trace -side bottom -fill x -expand 1
		.trace.h.cmds.menu add command -label {trace only} -command {TraceRoute 0 $tracehost}
		.trace.h.cmds.menu add command -label {trace+ping} -command {TraceRoute 1 $tracehost}
		.trace.h.cmds.menu add command -label {trace stop} -command {exec $killer $TRpid}
	}
	if {![info exists tracehost] || ($tracehost == {})} {
		if [info exists hst(1)] {set tracehost $hst(1)}
	}
}

proc TraceRoute {P H} { set id "$me/TraceRoute"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Here we fire up a traceroute process. The H arg is the host.  H may #
# be  null,  in  which case we use the host in the first row.  P is a #
# flag saying whether to start pinging for each new host.             #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me buf dnshost dnsaddr hst pinging tracer TRcmd TRfil TRhop TRhst TRlin TRpid TRrow tracehost
	if {$V>4} {Msg $V "$id: Called."}
	set pinging $P
	if [winfo exists .tr] {
		OnTop .tr
		.tr.t delete 1.0 end
	} else {
		if {$V>1} {Msg $V "$id: Create .tr window."}
		toplevel .tr
		wm title .tr "$tracer to $tracehost"
		text .tr.t -height 15 -width 90
		pack .tr.t -in .tr -fill both -expand 1
	}
	set TRhop 0
	set TRlin 0
	set TRrow 1
	if {$H == {}} {set tracehost $hst(1)} else {set tracehost $H}
	if {$tracehost == {}} {Msg 1 "Host 1 not defined."; return}
	set TRcmd "sh -c \"$tracer $tracehost \""
	Msg 2 "TRcmd=\"$TRcmd\""
	if [catch {open "| $TRcmd"} TRfil] {
		Msg 2 $TRfil
		return
	}
	set TRpid [pid $TRfil]
	set buf($TRfil) {}
	set dnshost {?}
	set dnsaddr {?}
	if {$V>1} {Msg $V "$me: TRfil=\"$TRfil\" TRpid=$TRpid."}
	if [catch {fconfigure $TRfil -blocking off} err] {
		Msg 1 "Can't fconfigure $TRfil -blocking off ($err)"
	}
	fconfigure $TRfil -buffering line
	fileevent $TRfil readable "TRrsp $P $TRfil"
}

proc TRrsp {P f} { set id "$me/TRrsp"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# This routine handles a response line from the traceroute process. #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me dnshost dnsaddr hst msg TRadr TRcmd TRfil TRhop TRhst TRlin TRpid TRrow tracehost
	if {$V>5} {Msg $V "$id: Called."}
	if {$f != $TRfil} {
		Msg 1 "TRrsp: File $f not TRfil=$TRfil."
		if [catch {close $f} m] {Msg 1 "$id: \[close $f\] gave \"$m\""}
		return
	}
	if {$V>2} {Msg $V "$id: Read a line <===================="}
	if {[gets $f line] < 0} {
		Msg 2 "Gets failed at hop $TRhop."
		if {[fblocked $f]} {
			Msg 2 "$id: Gets would have blocked, but didn't."
		} elseif {[eof $f]} {
			Msg 2 "Done."
			if [catch {close $f} err] {
				Msg 1 "Err \"$err\" from close $f."
			}
			set TRpid {}
			if ![info exists TRhst($TRhop)] {set TRhst($TRhop) {}}
			if {$TRhst($TRhop) == $tracehost} {
				if {$V>2} {Msg $V "$id: Reached tracehost $TRhst($TRhop) at hop $TRhop."}
			} elseif {$TRhst($TRhop) == $dnshost} {
				if {$V>2} {Msg $V "$id: Reached dnshost $TRhst($TRhop) at hop $TRhop."}
			} elseif {$TRadr($TRhop) == $dnsaddr} {
				if {$V>2} {Msg $V "$id: Reached dnsaddr $TRadr($TRhop) at hop $TRhop."}
			} else {
				Msg 1 "Didn't reach $tracehost; last is $TRhst($TRhop)."
				Host [incr TRhop] $tracehost {}
			}
		} else {
			Msg 1 "$id: Gets returned -1 for no known reason."
		}
		return
	}
	if {$V>1} {Msg $V "$id: Got \"$line\""}
	if {[incr TRlin] > 1} {.tr.t insert end \n}
	.tr.t insert end $line
	.tr.t see end
	if [regexp {^ *([0-9]+)[ *]+([-A-Za-z0-9_.]+) *\(([0-9.]+)\) } $line {} hop nam adr] {
		if {$V>1} {Msg $V "$id: TR hop $hop is $nam ($adr)"}
		set TRhst($hop) [string tolower $nam]
		set TRadr($hop) $adr
		Host [incr TRhop] $nam $adr
	} elseif [regexp {^ *([0-9]+)[ 	]\*}  $line {} hop] {
		if {$V>1} {Msg $V "$id: TR hop $hop no reply."}
		set TRhst($hop) {?}
		set TRadr($hop) {?}
		Host [incr TRhop] ? ?
	} elseif [regexp {^ *([0-9]+) (.*)}  $line {} hop tail] {
		if {$V>1} {Msg $V "$id: TR hop $hop found \"$tail\""}
		set TRhst($hop) {?}
		set TRadr($hop) {?}
		Host [incr TRhop] ? ?
	} elseif [regexp {^traceroute to *([-A-Za-z._]+) *\(([0-9.]+)\),(.*)}  $line {} dnshost dnsaddr tail] {
		if {$V>1} {Msg $V "$id: Traceroute gave $dnshost ($dnsaddr) as target."}
	} else {
		if {$V>2} {Msg $V "$id: Line not matched."}
	}
}

proc TRhosts P {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# This routine is now obsolete, but kept in case we want  to  use  it #
# again.   It  takes  the TR* arrays and builds a host table with the #
# target host at the top.   This  is  the  reverse  order  from  what #
# traceroute gives us.                                                #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me adr hst pid pings TRadr TRcmd TRfil TRhop TRhst TRpid TRrow tracehost
	set id "$me/TRhosts"
	if {$V>4} {Msg $V "$id: Called."}
	if {$V>1} {Msg $V "$id: We have $TRhop traceroute hosts."}
	if ![info exists TRhst($TRhop)] {
		if {$V>0} {Msg $V "$id: TRhst($TRhop) not defined."}
		return
	}
	if {$TRhst($TRhop) == $tracehost} {
		if {$V>1} {Msg $V "$id: We reached $tracehost at hop $TRhop."}
		incr TRhop -1;	# Ignore the last hop.
	} else {
		if {$V>1} {Msg $V "$id: We didn't reach $hst(1) in $TRhop hops."}
	}
	set r 2
	set h [set maxhop $TRhop]
	while {$h > 0} {
		if {$r > $pings} {set pings $r; Resize}
		if ![info exists TRhst($h)] {set TRhst($h) {?}}
		if ![info exists TRadr($h)] {set TRadr($h) {?}}
		if {$V>1} {Msg $V "$id: Row $r, hop $h of $maxhop, host \"$TRhst($h)\"."}
		set hst($r) $TRhst($h)
		set adr($r) $TRadr($h)
		incr h -1
		incr r
	}
	if {$P} {
		for {set r 1} {$r <= $pings} {incr r} {
			if {$pid($r) > 0} {
				if {$V>1} {Msg $V "$id: Already pinging hst($r)=$hst($r)."}
			} else {
				if {$V>1} {Msg $V "$id: Start   pinging hst($r)=$hst($r)."}
				PingInit $r
			}
		}
	}
}

proc SetTime {} {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global now time
	set time [clock format [set now [clock seconds]] -format %H:%M:%S]
	after 1000 SetTime
}
SetTime;		# Start 1-sec timer

proc HostList lst {
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
	global V me hosts host pingflg pings
	set id "$me/HostList"
	if {$V>4} {Msg $V "$id: Called."}
	PingAll Stop
	set r 0
	foreach hst $hosts($lst) {
		if {$V>1} {Msg $V "hst: \"$hst\""}
		if [regexp {^([-+])(.*)$} $hst {} flg opts] {
			if [regexp -nocase p $hst] {set pingflg $flg}
		} else {
			if {$V>1} {Msg $V "Ping \"$hst\""}
			Host [incr r] $hst {}
		}
	}
	set pings $r
	Resize
	wm title . "Ping $lst list from $host"
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #

set host [exec hostname]
wm title . "Pings from $host"
wm protocol . WM_DELETE_WINDOW  {byebye 0}

set B 6;		# Blue bias in green-yellow-red color spectrum
set BG black;	# Background color
set P0 {-padx 0 -pady 0} 

set BB "-bg $BG -fg yellow -bd 3 -relief raised -padx 2 -pady 0 -highlightthickness 0"
set BE "-bg $BG -fg cyan   -bd 3 -relief ridge -highlightthickness 0"
set BL "-bg $BG -fg green  -bd 3 -relief ridge  $P0"

if {$V>1} {
	puts "$me: Open .msg window because V=$V."
	msgwin;		# Open the message window for debugging
}

set int   60;	# Delay between pings
set pings  0;	# Highest host number being pinged
set rows   0;	# Highest row number showing
set dnshost {?}
set dnsaddr {?}

frame .b      -bg $BG; # -bd 5 -relief ridge

# Color ranges:
set clohst 100;	# host green response time (millisec)
set chihst 800;	# host  red  response time (millisec)
set clotod  60;	# time green no-response time (sec)
set chitod 300;	# time  red  no-response time (sec)

#frame .b.rows -bg $BG -bd 0 -relief ridge
#eval menubutton .b.rows.lbl -text rows: $BB -menu .b.rows.lbl.menu
#pack  .b.rows.lbl -in .b.rows -side left
#entry .b.rows.val -textvariable pings -bd 2 -relief ridge -fg cyan -bg $BG -width 0 -highlightthickness 0
#bind  .b.rows.val <Return> {Resize}
#pack  .b.rows.val -in .b.rows -side right
#menu .b.rows.lbl.menu
#.b.rows.lbl.menu add command -label incr -command {incr pings; Resize}
#.b.rows.lbl.menu add command -label decr -command {incr pings -1; Resize}

frame .b.dly -bg $BG -bd 0 -relief ridge
label .b.dly.lbl -text delay: -fg white -bg $BG -pady 0
pack  .b.dly.lbl -in .b.dly -side left
entry .b.dly.val -textvariable int -bd 2 -relief ridge -fg cyan -bg $BG -width 0 -highlightthickness 0
bind  .b.dly.val <Return> Restart
pack  .b.dly.val -in .b.dly -side right

frame .b.time -bg $BG -bd 0 -relief ridge
label .b.time.lbl -text time -fg white -bg $BG -pady 0
pack  .b.time.lbl -in .b.time -side left
entry .b.time.val -textvariable time -bd 2 -relief ridge -fg cyan -bg $BG -width 0 -highlightthickness 0
bind  .b.time.val <Return> Restart
pack  .b.time.val -in .b.time -side right

#frame .b.msclr -bg $BG -bd 0 -relief ridge
#label .b.msclr.lbl -text msRange: -fg white -bg $BG -pady 0
#pack  .b.msclr.lbl -in .b.msclr -side left
#entry .b.msclr.vhi -textvariable chihst -bd 2 -relief ridge -fg #F06  -bg $BG -width 0 -highlightthickness 0
#bind  .b.msclr.vhi <Return> Restart
#pack  .b.msclr.vhi -in .b.msclr -side right
#entry .b.msclr.vlo -textvariable clohst -bd 2 -relief ridge -fg #0F0 -bg $BG -width 0 -highlightthickness 0
#bind  .b.msclr.vlo <Return> Restart
#pack  .b.msclr.vlo -in .b.msclr -side right
#
#frame .b.tmclr -bg $BG -bd 0 -relief ridge
#label .b.tmclr.lbl -text Range: -fg white -bg $BG -pady 0
#pack  .b.tmclr.lbl -in .b.tmclr -side left
#entry .b.tmclr.vhi -textvariable chitod -bd 2 -relief ridge -fg #F06  -bg $BG -width 0 -highlightthickness 0
#bind  .b.tmclr.vhi <Return> Restart
#pack  .b.tmclr.vhi -in .b.tmclr -side right
#entry .b.tmclr.vlo -textvariable clotod -bd 2 -relief ridge -fg #0F0 -bg $BG -width 0 -highlightthickness 0
#bind  .b.tmclr.vlo <Return> Restart
#pack  .b.tmclr.vlo -in .b.tmclr -side right

#frame .b.valB -bg $BG -bd 0 -relief ridge
#label .b.valB.lbl -text B: -fg white -bg $BG
#pack  .b.valB.lbl -in .b.valB -side left
#entry .b.valB.val -textvariable B -bd 2 -relief ridge -fg cyan -bg $BG -width 0 -highlightthickness 0
#bind  .b.valB.val <Return> Restart
#pack  .b.valB.val -in .b.valB -side right
#pack  .b.valB -in .b -side right

Verbose .b

eval menubutton  .b.cmds -text Cmds -menu .b.cmds.menu $BB
menu .b.cmds.menu
.b.cmds.menu add command -label "New $me window"  -command "exec $me &"
.b.cmds.menu add command -label "Start all pings" -command {PingAll Init}
.b.cmds.menu add command -label "Stop  all pings" -command {PingAll Stop}
.b.cmds.menu add command -label "Show messages"   -command {msgwin}
.b.cmds.menu add command -label TraceRoute -command {Trace}
#b.cmds.menu add command -label TraceRoute -command {TraceRoute 0 $hst(1)}
#b.cmds.menu add command -label Trace+Ping -command {TraceRoute 1 $hst(1)}
.b.cmds.menu add command -label Quit -command exit

eval menubutton  .b.hsts -text Hosts -menu .b.hsts.menu $BB
menu .b.hsts.menu
foreach l [lsort [array names hosts]] {
	if {$V>1} {Msg $V "Host list $l"}
	.b.hsts.menu add command -label $l -command "HostList $l"
}

eval button .b.cfg -text config $BB -command cfgwin

#eval button .b.quit -text QUIT -command exit $BB -fg red2 -bg $BG

pack .b.cmds  -in .b -side left
pack .b.hsts  -in .b -side left
pack .b.cfg   -in .b -side left
#ack .b.rows  -in .b -side left -expand 1
pack .b.time  -in .b -side left -expand 1
pack .b.dly   -in .b -side left -expand 1
#ack .b.tmclr -in .b -side left -expand 1
#ack .b.msclr -in .b -side left -expand 1
#ack .b.quit  -in .b -side right -fill x
pack .b -side top -fill x

frame .d -bd 3 -bg $BG -relief ridge
pack  .d -side bottom -expand 1 -fill both

eval entry .m -textvariable msg $BE -bd 3 -relief ridge -fg yellow -bg $BG
pack .m -side bottom -fill x

# Trace;	# Create the trace widget

set adr(0) addr
set fil(0) file
set hst(0) target
set pid(0) pid
set seq(0) seq
set ttl(0) ttl
set avcnt 3;	# How man averages to calculate
set av(0,0) ms
set av(1,0) A1
set av(2,0) A2
set av(3,0) A3
set rsp(0) { }
set sta(0) state
set lsn(0) loss
set lsr(0) %
set tod(0) when

eval label .d.lbl0 $BL -text {{}} -relief flat
eval label .d.cmd0 $BL -text {cmd} -width 4 -relief flat
eval label .d.hst0 $BL -textvariable hst(0) -fg white -relief flat
eval label .d.adr0 $BL -textvariable adr(0) -fg white -relief flat
eval label .d.pid0 $BL -textvariable pid(0) -fg white -relief flat
eval label .d.tod0 $BL -textvariable tod(0) -fg white -relief flat
eval label .d.seq0 $BL -textvariable seq(0) -fg white -relief flat
eval label .d.lsn0 $BL -textvariable lsn(0) -fg white -relief flat
eval label .d.lsr0 $BL -textvariable lsr(0) -fg white -relief flat
eval label .d.av00 $BL -textvariable av(0,0) -fg white -relief flat
eval label .d.av10 $BL -textvariable av(1,0) -fg white -relief flat
eval label .d.av20 $BL -textvariable av(2,0) -fg white -relief flat
eval label .d.av30 $BL -textvariable av(3,0) -fg white -relief flat
eval label .d.rsp0 $BL -textvariable rsp(0) -fg white -relief flat
eval label .d.sta0 $BL -textvariable sta(0) -fg white -relief flat

BindHelp .d.lbl0 \
{}
BindHelp .d.cmd0 \
{The "cmd" column contains buttons to start/stop pinging for one host.}
BindHelp .d.hst0 \
{The "target" may be a host name or IP address. Press <Return>
after changing the name to (re)start pinging a new target.}
BindHelp .d.adr0 \
{The "addr" column is an IP address. Press <Return> after changing
the address to (re)start pinging this address. The "target" column
will also change to show that we know only the address.}
BindHelp .d.pid0 \
{The "pid" column is the Process ID number of the ping to this host.}
BindHelp .d.tod0 \
{The "when" column is the time of the last response
for this host. If it's red, the host isn't responding;
check the "state column for a possible reason.}
BindHelp .d.seq0 \
{The "seq" column is the sequence number of the last response.}
BindHelp .d.lsn0 \
{The "loss" column is the number of pings that received no response.}
BindHelp .d.lsr0 \
{The "%%" column is the percent of pings that received no response.}
BindHelp .d.av00 \
{The "ms" column is the mean response time in milliseconds.}
BindHelp .d.av10 \
{The "A1" column is a fast average of response times.}
BindHelp .d.av20 \
{The "A2" column is a medium average of response times.}
BindHelp .d.av30 \
{The "A3" column is a slow average of response times.}
BindHelp .d.rsp0 \
{The "response" column isn't being shown right now.}
BindHelp .d.sta0 \
{The "state" column is a brief explantion of the host's status.}

grid .d.lbl0 -in .d -row 0 -column  1 -sticky  e
grid .d.cmd0 -in .d -row 0 -column  1 -sticky we
grid .d.hst0 -in .d -row 0 -column  2 -sticky we
grid .d.adr0 -in .d -row 0 -column  3 -sticky we
grid .d.pid0 -in .d -row 0 -column  4 -sticky  e
grid .d.tod0 -in .d -row 0 -column  5 -sticky we
grid .d.seq0 -in .d -row 0 -column  6 -sticky w
grid .d.lsn0 -in .d -row 0 -column  7 -sticky e
grid .d.lsr0 -in .d -row 0 -column  8 -sticky e
grid .d.av00 -in .d -row 0 -column  9 -sticky we
grid .d.av10 -in .d -row 0 -column 10 -sticky we
grid .d.av20 -in .d -row 0 -column 11 -sticky we
grid .d.av30 -in .d -row 0 -column 12 -sticky we
grid .d.rsp0 -in .d -row 0 -column 13 -sticky w
grid .d.sta0 -in .d -row 0 -column 14 -sticky w

# Process the command-line args:
set pingflg 0
set pinging 0
if {$argv == {}} {
	set argv $hosts(default)
}
set r 0
foreach arg $argv {
	if {$V>1} {Msg $V "arg: \"$arg\""}
	if [regexp {^([-+])(.*)$} $arg {} flg opts] {
		if [regexp -nocase p $arg] {set pingflg $flg}
	} elseif [info exists hosts($arg)] {
		foreach arg $hosts($arg) {
			if {$V>1} {Msg $V "arg: \"$arg\""}
			if [regexp {^([-+])(.*)$} $arg {} flg opts] {
				if [regexp -nocase p $arg] {set pingflg $flg}
			} else {
				if {$V>1} {Msg $V "Ping \"$arg\""}
				Host [incr r] $arg {}
			}
		}
	} else {
		if {$V>1} {Msg $V "Ping \"$arg\""}
		Host [incr r] $arg {}
	}
}
if {$pingflg == {-}} {set pinging 0} else {set pinging 1}
if {$pinging} {PingAll Init}

if {$msg == {}} {Msg 1 "Point at something and press Help or F1 for help."}

after 10000 Color
