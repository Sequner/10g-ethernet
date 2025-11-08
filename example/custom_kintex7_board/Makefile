PROJECT := ethernet_10g
PART := xc7k325tffg676-2

gen_ip: 
	vivado -mode tcl -source tcl/generate_ips.tcl -tclargs $PART

	# There is a bug that vivado generates GTX transceiver
	# with RXSLIDE_MODE set to "PCS", even if xci file
	# specifies it as "OFF".
	# However, sliding is implemented in our PCS core,
	# so, the feature should be turned off(set to "OFF").
	sed -i 's/\"PCS\"/\"OFF\"/g' \
			rtl/gtwizard_pma/gtwizard_pma_gt.v

clean:
	rm -rf *.log
	rm -rf *.jou
	rm -rf .Xil
