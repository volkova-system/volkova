namespace eval copy_service {
namespace eval handler {
proc execute {cmd args} {
if {$cmd ne $copy_service::setting::commandName} {
copy_service::help::printUsage
exit 1
}
if {[llength $args] != 2} {
copy_service::help::printUsage
exit 1
}
set srcRel [lindex $args 0]
set dstRel [lindex $args 1]
set dst [copy_service::engine::copyDir $srcRel $dstRel]
puts "Copied to $dst"
exit 0
}
}
}
