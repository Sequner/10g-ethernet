### MUST BE INVOKED USING make
### IN */example/custom_kintex7_board DIRECTORY

set part_name [lindex $argv 0]

set_part $part_name
#set_part xc7k325tffg676-2
set xci_folders [glob ./ip/*]
foreach xci_folder $xci_folders {
    set xci [glob ./$xci_folder/*.xci]
    puts "Processing $xci ..."
    read_ip $xci
    generate_target all [get_ips [file rootname [file tail $xci]]]
}

exit