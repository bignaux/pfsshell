# -------------------------- future package pfsshell
# we could also extend interactive mode with clever expect feature.

package require Expect
package provide pfsshell 0.1

namespace eval ::pfsshell {
    # Export commands
    namespace export init pfsshell ls rm_f copy
}

proc ::pfsshell::init {} {

	#TODO; use a specific spawn_id or namespace ?
	global expect_out spawn_id pfsshell

	spawn $pfsshell
	match_max 100000
	expect -exact "pfsshell for POSIX systems\r
https://github.com/uyjulian/pfsshell\r
\r
This program uses pfs, apa, iomanX, \r
code from ps2sdk (https://github.com/ps2dev/ps2sdk)\r
\r
Type \"help\" for a list of commands.\r
\r
> "
}

proc ::pfsshell::pfsshell { cmd {params ""} {arg "-re"} {expect "(.*)# "} } {

	global expect_out spawn_id
	send -- "$cmd $params\r"
	expect {
		$arg $expect {
			#send_user "\[\033\[01;32mpassed\033\[0m]"
		}
		timeout {
			send_user "\[\033\[01;31mtimeout\033\[0m]"
			return 1
		}
		-re "(.*)# " {
			#send_user "\[\033\[01;31mfailed\033\[0m]"
			return 1
		}
		#eof {
		#	send_user "eof"
		#}
	}
}

### drwxrwxrwx        512 2020-12-04 02:54 APPS
proc ::pfsshell::is_directory { path } {

	if { [string index $path 0] eq "d" } {
		 return 1 } else { return 0 }
}

# get a true ls
proc ::pfsshell::ls { path } {

	global expect_out
	set directories [list]
	set filenames [list]

	pfsshell "ls"
	set files [split $expect_out(0,string) "\n"]
	set files [lrange $files 1 end-1] ;# ignore ls & prompt

	foreach file $files {
		if { [lindex $file 4] ne "" } {
			if { [is_directory $file] } {
				lappend directories [lindex $file 4] } else {
					lappend filenames [lindex $file 4]
				}
			}
		}
	return [list $filenames $directories]
}

#TODO: not recurssive + don't expect directory
#TODO: cd to $path
proc ::pfsshell::rm_f {{path "."}} {
	global expect_out
	lassign [ pfsshell_ls $path] filenames directories
	foreach file $filenames {
		pfsshell "rm" $file
	}
}

# pfsshell put doesnt support directory copy
# This is a bit confused between source on host path and dest on pfs path ?
# mimic scp
proc ::pfsshell::copy { sources dest } {

  global expect_out
  pfsshell "cd" $dest
  foreach filename $sources {
    if { [file isdirectory $filename] } {

      #TODO : manage existing directory
      pfsshell "mkdir" $filename
      # hard to synchro pwd between pfsshell local and disk path, the tcl context
      cd $filename
      pfsshell "lcd" $filename

      set files [glob *]
      puts "FILES: $files"
      copy $files $filename
      cd ..
      pfsshell "lcd" ".."
      pfsshell "cd" ".."

      } else {
        pfsshell "put" $filename
      }
    }
}
