using AbstractSDRs_rx_asci_art_dft
using Test

# @testset "AbstractSDRs_asci_art_dft.jl" begin
    # # Write your tests here.
# end



carrierFreq = 2400e6
samplingRate = 2e6
gain    = 12

f = 500e3
N = 4096*16

f = range(-samplingRate/2,samplingRate/2,length=N)

sig = 1*exp.(2im*π .* f ./ samplingRate .* (0:N-1))

AbstractSDRs_asci_art_dft.main(:radiosim,carrierFreq,samplingRate,gain;buffer=sig,avg=1,canvas=BlockCanvas)
