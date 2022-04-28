module AbstractSDRs_asci_art_dft

# ----------------------------------------------------
# --- Dependencies 
# ---------------------------------------------------- 
using AbstractSDRs
using FFTW
using UnicodePlots
import REPL
# ----------------------------------------------------
# --- Methods exportation 
# ---------------------------------------------------- 
# Exporting UnicodePlots canvas to be able to use them in command line
export AsciiCanvas, DotCanvas, BlockCanvas, HeatmapCanvas, DensityCanvas, BrailleCanvas

# ----------------------------------------------------
# --- Limits for magnitude 
# ---------------------------------------------------- 
include("./magnitude_limits.jl")

# ----------------------------------------------------
# --- Core methods
# ---------------------------------------------------- 

""" 
Display the DFT with ACII art in the terminal, for a given SDR.
Parameters are the one required to configure a SDR with AbstractSDRs. kwargs are `nFFT` the size of the FFT used and `kwargs...` all the keywords parameters required to configure the radio (see `openSDR` from AbstractSDRs for the supported keywords
AbstractSDRs_asci_art_dft.main(sdr,carrierFreq,samplingRate,gain;nFFT=1024,avg,canvas,kwargs...)
# Input parameters 
- sdr : SDR type supported by AbstractSDRs (for instance :uhd). A symbol is expected 
- carrierFreq : Carrier Freq in Hz (e.g 2400e6)
- samplingRate : Radio sampling rate in Hz (e.g 2e6)
- gain          : gain in normalized scale (e.g 20)
# Keywords 
- nFFT : Size of the FFT/DFT as an `Int` (e.g 1024)
- averaging factor for PSD computation  as an `Int` (e.g 12)
- canvas : Canvas used to display. Can be AsciiCanvas, DotCanvas or BlockCanvas (see UnicodePlots.jl documentation)
- kwargs... : All arguments supported by AbstractSDRs to open configure and monitor radio devices
# Controls 
It is possible to change the magnitude axis during acquisition to zoom in/out and to shift the center magnitude. By default the plot is centered around 0dB and have 120dB dynamic.
By pressing different keys we can:
- UP arrow to shit  the center limit up 
- DOWN arrow to shift the center  down
- LEFT arrow to zoom out (increase range)
- RIGHT arrow to decrease range of ylims (zoom in)
"""
function main(sdr,carrierFreq::Number,samplingRate::Number,gain::Number;nFFT=1024,avg=1,heigth=120,width=60,canvas=BlockCanvas,kwargs...)

    # ----------------------------------------------------
    # --- Open the radio 
    # ---------------------------------------------------- 
    @info "Configure SDR"
    radio = openSDR(sdr,carrierFreq,samplingRate,gain;kwargs...)
    carrierFreq = getCarrierFreq(radio)

    # ----------------------------------------------------
    # --- Init REPL to have user control 
    # ---------------------------------------------------- 
    term = REPL.Terminals.TTYTerminal("xterm",stdin,stdout,stderr)
    REPL.Terminals.raw!(term,true)
    Base.start_reading(stdin)

    # ----------------------------------------------------
    # --- Internal variables 
    # ---------------------------------------------------- 
    # Data from radio 
    buff    = zeros(ComplexF32,nFFT)
    # Output in log scale 
    out     = zeros(Float32,nFFT)
    # Core processing unit
    processing! = clojure_processing(nFFT,avg)
    doPlot      = clojure_doPlot(samplingRate,nFFT,heigth,width,canvas,carrierFreq)
    global currLims
    reset(currLims)


    # ----------------------------------------------------
    # --- Canvas 
    # ---------------------------------------------------- 

    # --- Into to user
    run(`clear`)
    @info "Compute ASCII DFT use <c-c> to interrupt"

    try 
        while(true)
            # Get samples 
            recv!(buff,radio)
            # Processing 
            processing!(out,buff)
            # Plot 
            global OUT = out
            plt = doPlot(out)
            # User control 
            userControl()
            # Allow scheduling
            sleep(0.1)
        end
    catch exception 
        println("\33[H")
        close(radio)
        @info "Done"
        rethrow(exception)
    end
end


""" Function for user control to update the ylims and exit
"""
function userControl()
    b = bytesavailable(stdin)
    if b > 0
        data = read(stdin, b)
        if data[1] == UInt(3)
            # --- Interruption
            println("Ctrl+C - exiting")
            throw(InterruptException())
        elseif length(data) == 3 
            global currLims
            # --- Arrow keys
            if data == [0x1b;0x5b;0x41] 
                # UP is pressed 
                shiftUp(currLims)
            elseif data == [0x1b;0x5b;0x42]
                # DOWN in pressed
                shiftDown(currLims)
            elseif data == [0x1b,0x5b,0x44]
                # LEFT is pressed Zoom out
                zoomOut(currLims)
            elseif data == [0x1b,0x5b,0x43]
                # RIGHT is pressed Zoom in
                zoomIn(currLims)
            end
        end
    end
end


""" Apply the core processing (here the square modulus of the FFT
"""
function clojure_processing(nFFT,avg)
    # Container to estimate PSD 
    sF    = zeros(Float32,nFFT)
    sFM   = zeros(Float32,nFFT)
    α     = 1/avg
    function processing!(y,sig)
        # --- Apply | FFT(.) | ^2
        sF  .= abs2.(fftshift(fft(sig)));
        # --- Averaging
        sFM .= (1-α) .* sFM .+ α .* sF; 
        # --- Log scale
        y .= 10*log10.(1e-12 .+ sFM);
    end
    return processing!
end

""" Function for plot rendering
"""
function clojure_doPlot(samplingRate,nFFT,heigth,width,canvas,carrierFreq)
    xAx = ((0:nFFT-1)/nFFT .- 0.5) .* samplingRate ./1e6
    function doPlot(out)
        # --- Get current y axis 
        global currLims 
        lims = limit(currLims)
        # Clear figure 
        println("\33[H")
        # New figure
        plt = lineplot(xAx,out,label="",symbols="|",ylim=lims,heigth=heigth,width=width,canvas=canvas,xlabel="Frequency [MHz]",ylabel="Magnitude [dB]",title="Spectrum @ $(carrierFreq/1e6) MHz" )
        display(plt)
        # @show lims
    end
    return doPlot
end

end

