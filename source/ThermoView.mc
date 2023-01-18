//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/scratch_vhdl/blob/main/LICENCE.
//
//-----------------------------------------------------------------------------------
//
// ThermoNest is a Garmin IQ application written in Monkey C and routinely tested on
// a Venu 2 device. The source code is provided at:
//            https://github.com/house-of-abbey/GarminThermoNest.
//
// J D Abbey & P A Abbey, 28 December 2022
//
//
// Description:
//
// ThermoView provides the temperature settings drawing function.
//
//-----------------------------------------------------------------------------------

using Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;

class ThermoView extends WatchUi.View {
    // Between the full range arc and the outside of the watch face
    hidden const margin        = 14;
    // Line width of the full range arc
    hidden const full_arc_w    = 4;
    // Line width of the range arc (thicker than full_arc_w)
    hidden const range_arc_w   = 8;
    // Heat & cool line width of a tick mark
    hidden const hct_tick_w    = 4;
    // Ambient temperature line width of a tick mark
    hidden const at_tick_w     = 8;
    // Ticks start at: watch radius - tick_st_r
    hidden const tick_st_r     = 5;
    // Temperature range ends: watch radius - tick_ren_r
    hidden const tick_ren_r    = 30;
    // Ambient temperature: watch radius - tick_aen_r
    hidden const tick_aen_r    = 20;
    // Vertical space of top centre icon for connectivity/refresh icon
    hidden const statusHeight  = 30;
    // Additional colours over Globals
    hidden const darkGreyColor = 0xaaaaaa;

    hidden var mNestStatus as NestStatus;

    function initialize(ns as NestStatus) {
        View.initialize();
        mNestStatus = ns;
    }

    // Linear IntERPolatation
    //
    // Parameters:
    //  x - Temperature value to scale by linear interpolation
    //
    //            | Min | Max
    //      ------+-----+----
    //      Temp  |  a  | b
    //      Angle |  A  | B
    //
    function lerp(x, a, b, A, B) {
        return (x - a) / (b - a) * (B - A) + A;
    }

    // Draw a tick on ther arc of the watch face.
    // Parameters:
    //  * theta - angle of rotation in degrees from 6 o'clock
    //  * start - distance towards the circle centre from the watch circumference to start drawing the tick
    //  * end   - distance towards the circle centre from the watch circumference to end drawing the tick
    //
    function drawTick(dc as Graphics.Dc, theta as Lang.Number, start as Lang.Number, end as Lang.Number) {
        var crad = Math.toRadians(360 - theta);
        var ca   = Math.cos(crad);
        var cb   = Math.sin(crad);
        var hw   = dc.getWidth() / 2;
        var hh   = dc.getHeight() / 2;
        dc.drawLine(ca*(hw - end) + hw, cb*(hh - end) + hh, ca*(hw - start) + hw, cb*(hh - start) + hh);
    }

    function drawTempScale(dc as Graphics.Dc, ambientTemp, heatTemp, coolTemp) as Void {
        var hw = dc.getWidth() / 2;
        var hh = dc.getHeight() / 2;
        dc.setColor(darkGreyColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(full_arc_w);
        dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, 240f, -60f);
        if (ambientTemp != null) {
            var ambientArc = mNestStatus.getScale() == 'C'
                ? lerp(ambientTemp, Globals.minTempC, Globals.maxTempC, 240f, -60f)
                : lerp(ambientTemp, Globals.minTempF, Globals.maxTempF, 240f, -60f);
            var heatArc = (heatTemp == null)
                ? 0
                : mNestStatus.getScale() == 'C'
                    ? lerp(heatTemp, Globals.minTempC, Globals.maxTempC, 240f, -60f)
                    : lerp(heatTemp, Globals.minTempF, Globals.maxTempF, 240f, -60f);
            var coolArc = (coolTemp == null)
                ? 0
                : mNestStatus.getScale() == 'C'
                    ? lerp(coolTemp, Globals.minTempC, Globals.maxTempC, 240f, -60f)
                    : lerp(coolTemp, Globals.minTempF, Globals.maxTempF, 240f, -60f);

            if (heatTemp != null) {
                dc.setPenWidth(range_arc_w);
                if (ambientTemp < heatTemp) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                    dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, ambientArc, heatArc);
                } else {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    if (coolTemp != null) {
                        if (coolTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, heatArc, coolArc);
                        }
                    } else {
                        if (ambientTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, heatArc, ambientArc);
                        }
                    }
                }
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(hct_tick_w);
                drawTick(dc, heatArc, tick_st_r, tick_ren_r);
            }

            if (coolTemp != null) {
                dc.setPenWidth(range_arc_w);
                if (coolTemp < ambientTemp) {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, coolArc, ambientArc);
                } else {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    if (heatTemp != null) {
                        if (coolTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, heatArc, coolArc);
                        }
                    } else {
                        if (coolTemp > ambientTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, ambientArc, coolArc);
                        }
                    }
                }
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(hct_tick_w);
                drawTick(dc, coolArc, tick_st_r, tick_ren_r);
            }

            dc.setColor(darkGreyColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(at_tick_w);
            drawTick(dc, ambientArc, tick_st_r, tick_aen_r);
        }
    }

}