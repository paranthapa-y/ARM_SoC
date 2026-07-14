onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_fpga_shield/BAUDTICK0
add wave -noupdate /tb_fpga_shield/BAUDTICK
add wave -noupdate /tb_fpga_shield/BAUD_CLK
add wave -noupdate /tb_fpga_shield/BAUD_COUNTER
add wave -noupdate /tb_fpga_shield/u_fpga_top/u_fpga_system/u_user_partition/u_mps2_peripherals_wrapper/u_beetle_peripherals_fpga_subsystem/u_cmsdk_apb_uart_0/TXD
add wave -noupdate /tb_fpga_shield/u_fpga_top/u_fpga_system/u_user_partition/u_mps2_peripherals_wrapper/u_beetle_peripherals_fpga_subsystem/u_cmsdk_apb_uart_0/tx_tick_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {35880000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {222606311 ps} {229118937 ps}
