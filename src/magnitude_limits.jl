# ----------------------------------------------------
# --- Limit managment 
# ---------------------------------------------------- 
mutable struct CurrLims
    center::Float64;        # Position of the center of the magnitude 
    range::Float64;         # Range between center and max (and min, respectively). Note that the total range is this 2range
end
# By default, spectrum is centered in 0 with 120dB dynamic
currLims = CurrLims(0,60)

limit(l::CurrLims)  = (l.center + l.range,l.center - l.range)
""" Zoom In (range is limited)
zoomIn(l::CurrLims)
"""
function zoomIn(l::CurrLims)
    l.range -= 10
end
""" Zoom Out (range is increased)
zoomOut(l::CurrLims)
"""
function zoomOut(l::CurrLims)
    l.range += 10
end
""" Shift limit upward (center magnitude is increased)
shiftUp(l::CurrLims)
"""
function shiftUp(l::CurrLims)
    l.center += 10
end
""" Shit limit down (center magnitude is decreased)
shiftDown(l::CurrLims)
"""
function shiftDown(l::CurrLims)
    l.center -= 10
end
""" Restore default limit values
reset(l::CurrLims)
"""
function reset(l::CurrLims)
    l.center = 0
    l.range  = 60
end
