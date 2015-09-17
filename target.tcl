# This is not an absolute step by step to get a sample system up and running!
# The purpose of this is to show how to connect up the key pieces.
# Note PS configuration not included. For inspiration, see
# https://github.com/analogdevicesinc/hdl/tree/master/projects/common.
# You may build a project that uses the AXI DMAC IP to see how ADI uses it
# The difference is that the setup bellow uses AXIS instead of FIFO's
# This assumes you know how to build ADI's IP and add it to your repo list

# 1) Confiure 200 MHz clock and reset from PS
# 2) reset for 200 MHz FCLK1 on Zynq for example
set sys_rstgen_200m [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 sys_rstgen_200m]
set_property -dict [list CONFIG.C_EXT_RST_WIDTH {1}] $sys_rstgen_200m

# 3) ADI AXI DMAC
set axi_iio_tx_dma [create_bd_cell -type ip -vlnv analog.com:user:axi_dmac:1.0 axi_iio_tx_dma]
set_property -dict [list CONFIG.C_DMA_TYPE_SRC {0}] $axi_iio_tx_dma
set_property -dict [list CONFIG.C_DMA_TYPE_DEST {1}] $axi_iio_tx_dma
set_property -dict [list CONFIG.C_FIFO_SIZE {16}] $axi_iio_tx_dma
set_property -dict [list CONFIG.C_2D_TRANSFER {0}] $axi_iio_tx_dma
set_property -dict [list CONFIG.C_CYCLIC {0}] $axi_iio_tx_dma
set_property -dict [list CONFIG.C_AXI_SLICE_DEST {1}] $axi_iio_tx_dma
set_property -dict [list CONFIG.C_AXI_SLICE_SRC {1}]  $axi_iio_tx_dma
set_property -dict [list CONFIG.C_DMA_DATA_WIDTH_DEST {64}] $axi_iio_tx_dma

set axi_iio_rx_dma [create_bd_cell -type ip -vlnv analog.com:user:axi_dmac:1.0 axi_iio_rx_dma]
set_property -dict [list CONFIG.C_DMA_TYPE_SRC {1}] $axi_iio_rx_dma
set_property -dict [list CONFIG.C_DMA_TYPE_DEST {0}] $axi_iio_rx_dma
set_property -dict [list CONFIG.C_FIFO_SIZE {16}] $axi_iio_rx_dma
set_property -dict [list CONFIG.C_2D_TRANSFER {0}] $axi_iio_rx_dma
set_property -dict [list CONFIG.C_CYCLIC {0}] $axi_iio_rx_dma
set_property -dict [list CONFIG.C_AXI_SLICE_DEST {1}] $axi_iio_rx_dma
set_property -dict [list CONFIG.C_AXI_SLICE_SRC {1}]  $axi_iio_rx_dma
set_property -dict [list CONFIG.C_DMA_DATA_WIDTH_DEST {64}] $axi_iio_rx_dma

# 4) interface connections
ad_connect  sys_200m_clk sys_ps7/FCLK_CLK1
ad_connect  sys_200m_clk sys_rstgen_200m/slowest_sync_clk
ad_connect  sys_200mx_resetn sys_ps7/FCLK_RESET1_N
ad_connect  sys_200mx_resetn sys_rstgen_200m/ext_reset_in
ad_connect  sys_200m_resetn sys_rstgen_200m/peripheral_aresetn

# NOTE: for higher throughput connect to separate HP's
ad_mem_hp1_interconnect sys_200m_clk sys_ps7/S_AXI_HP1
ad_mem_hp1_interconnect sys_200m_clk axi_iio_tx_dma/m_dest_axi
ad_mem_hp1_interconnect sys_200m_clk axi_iio_rx_dma/m_src_axi

# 6) address
ad_cpu_interconnect 0x7c400000  axi_iio_tx_dma
ad_cpu_interconnect 0x7c420000  axi_iio_rx_dma

# 7) Remember to connect the interrupts to a concat block to PS

