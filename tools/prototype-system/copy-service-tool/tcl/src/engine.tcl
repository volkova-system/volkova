namespace eval copy_service {
namespace eval engine {
proc findRoot {} {
set dir [file dirname [info script]]
set limit [expr {$copy_service::setting::maxAscend}]
for {set i 0} {$i < $limit} {incr i} {
if {[file exists [file join $dir $copy_service::setting::projectMarker]]} {
return [file normalize $dir]
}
set dir [file dirname $dir]
}
error "Project root not found"
}
proc servicesRoot {} {
set root [findRoot]
set s [file join $root $copy_service::setting::projectMarker]
return [file normalize $s]
}
proc within {base path} {
set b [file normalize $base]
set p [file normalize $path]
return [expr {[string first $b $p] == 0}]
}
proc copyDir {srcRel dstRel} {
set services [servicesRoot]
set srcAbs [file normalize [file join $services $srcRel]]
set dstAbs [file normalize [file join $services $dstRel]]
if {![file exists $srcAbs]} {
error "Source not found"
}
if {![file isdirectory $srcAbs]} {
error "Source is not a directory"
}
if {![within $services $srcAbs]} {
error "Source outside services"
}
if {![within $services $dstAbs]} {
error "Target outside services"
}
if {$srcAbs eq $dstAbs} {
error "Source and target are the same"
}
if {[string first $srcAbs $dstAbs] == 0} {
error "Target inside source"
}
if {[file exists $dstAbs]} {
error "Target already exists"
}
set parent [file dirname $dstAbs]
if {![file exists $parent]} {
file mkdir $parent
}
file copy $srcAbs $dstAbs
return $dstAbs
}
}
}
