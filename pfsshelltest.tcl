# Author : Bignaux Ronan

package require tcltest 2.0
namespace import ::tcltest::*

lappend auto_path "."
package require pfsshell 0.1

exp_version -exit 5.0
log_user 0
set timeout 5
set count 0
set pfsshell "pfsshell"         ;# full path to pfsshell if some unusual place.

test initialize { virtual disc initialize
} -setup { exec fallocate -l 8G test.img
} -body {
	pfsshell::init
 	pfsshell::pfsshell  "device" "test.img" "-re" "(.*)# "
	pfsshell::pfsshell  "initialize" "yes" "-exact" "# "
	pfsshell::pfsshell  "ls" "" "-exact" "
0x0001   128MB __mbr\r
0x0100   128MB __net\r
0x0100   128MB __system\r
0x0100   128MB __sysconf\r
0x0100   129MB __common\r
# "
	pfsshell::pfsshell "mkfs" "__net" "-exact" "
pfs: Format: log.number = 8224, log.count = 16\r
pfs: Format sub: sub = 0, sector start = 8208, sector end = 8211\r
# "
}

test createAndFormat { Create and format +OPL partition } -body {
	pfsshell::pfsshell "mkpart" "+OPL 128"  "-re" "(.*)# "
	pfsshell::pfsshell "mkfs" "+OPL" "-re" "(.*)# "
}

test fileManip { Test common file commands } -body {
	pfsshell::pfsshell "mount" "+OPL" "-exact" "+OPL:/# "
	pfsshell::pfsshell "mkdir" "directory" "-exact" "+OPL:/# "
	pfsshell::pfsshell "cd" "directory" "-exact" "+OPL:/directory# "
	pfsshell::pfsshell "put" "README.md" "-exact" "+OPL:/directory# "
	pfsshell::pfsshell "rename" "README.md pfsshell.md" "-exact" "+OPL:/directory# "
}

test exitProperly { Close pfsshell } -body { pfsshell::pfsshell "exit" "" eof "" }

#runAllTests
cleanupTests
