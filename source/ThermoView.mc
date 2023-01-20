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
using Toybox.Application.Properties;

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
    hidden const statusHeight  = 40;
    // Additional colours over Globals
    hidden const darkGreyColor = 0xaaaaaa;
    // Temperature major tick (10s): watch radius - tick_deep_r
    hidden const tick_major_r  = 25;
    // Temperature major tick (5s): watch radius - tick_half_r
    hidden const tick_half_r   = 20;
    // Temperature minor tick (1s): watch radius - tick_minor_r
    hidden const tick_minor_r  = 15;
    // Temperature major tick width (10s)
    hidden const tick_major_w  = 4;
    // Temperature major tick width (10s)
    hidden const tick_half_w   = 2;
    // Temperature minor tick width (1s)
    hidden const tick_minor_w  = 2;
    // Diamond dimensions
    hidden const diamondwidth  = 10;
    hidden const diamondHeight = 30;

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
    function drawTick(dc as Graphics.Dc, theta as Lang.Number, start as Lang.Number, end as Lang.Number, str as Lang.String or Null) {
        var crad = Math.toRadians(360 - theta);
        var ca   = Math.cos(crad); // Width component
        var cb   = Math.sin(crad); // Height component
        var hw   = dc.getWidth() / 2;
        var hh   = dc.getHeight() / 2;
        if (str != null) {
            // dc.getTextDimensions(str, Graphics.FONT_XTINY) returns the same as
            // [dc.getTextWidthInPixels(str, Graphics.FONT_XTINY), dc.getFontHeight(Graphics.FONT_XTINY)] only the
            // text height seems to include line spacing and is too large.
            dc.drawText(
                ca * (hw - start - dc.getTextWidthInPixels(str, Graphics.FONT_XTINY)/2) + hw,
                cb * (hh - start - dc.getFontHeight(Graphics.FONT_XTINY)/4) + hh,
                Graphics.FONT_XTINY,
                str,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            dc.drawLine(ca * (hw - end) + hw, cb * (hh - end) + hh, ca * (hw - start) + hw, cb * (hh - start) + hh);
        }
    }

    function drawDiamond(dc as Graphics.Dc, theta as Lang.Number, start as Lang.Number) {
        var end  = start + diamondHeight;
        var crad = Math.toRadians(360 - theta);
        var ca   = Math.cos(crad); // Width component
        var cb   = Math.sin(crad); // Height component
        var hw   = dc.getWidth() / 2;
        var hh   = dc.getHeight() / 2;
        dc.fillPolygon([
            [ca * (hw -          end   )                       + hw, cb * (hh -          end   )                       + hh],
            [ca * (hw - (start + end)/2) + (cb * diamondwidth) + hw, cb * (hh - (start + end)/2) - (ca * diamondwidth) + hh],
            [ca * (hw -  start         )                       + hw, cb * (hh -  start         )                       + hh],
            [ca * (hw - (start + end)/2) - (cb * diamondwidth) + hw, cb * (hh - (start + end)/2) + (ca * diamondwidth) + hh]
        ]);
    }

    function drawTempScale(dc as Graphics.Dc, ambientTemp as Lang.Float, heatTemp as Lang.Float, coolTemp as Lang.Float) as Void {
        if (Properties.getValue("faceSelect") == 0) {
            drawTempScaleTicks(dc, ambientTemp, heatTemp, coolTemp);
        } else {
            drawTempScaleMinimal(dc, ambientTemp, heatTemp, coolTemp);
        }
    }

    function drawTempScaleTicks(dc as Graphics.Dc, ambientTemp as Lang.Float, heatTemp as Lang.Float, coolTemp as Lang.Float) as Void {
        var hw = dc.getWidth() / 2;
        var hh = dc.getHeight() / 2;

        var ambientArc = (ambientTemp == null)
            ? 0
            : mNestStatus.getScale() == 'C'
                ? lerp(ambientTemp, Globals.minTempC, Globals.maxTempC, Globals.minTempArc, Globals.maxTempArc)
                : lerp(ambientTemp, Globals.minTempF, Globals.maxTempF, Globals.minTempArc, Globals.maxTempArc);
        var heatArc = (heatTemp == null)
            ? 0
            : mNestStatus.getScale() == 'C'
                ? lerp(heatTemp, Globals.minTempC, Globals.maxTempC, Globals.minTempArc, Globals.maxTempArc)
                : lerp(heatTemp, Globals.minTempF, Globals.maxTempF, Globals.minTempArc, Globals.maxTempArc);
        var coolArc = (coolTemp == null)
            ? 0
            : mNestStatus.getScale() == 'C'
                ? lerp(coolTemp, Globals.minTempC, Globals.maxTempC, Globals.minTempArc, Globals.maxTempArc)
                : lerp(coolTemp, Globals.minTempF, Globals.maxTempF, Globals.minTempArc, Globals.maxTempArc);

        if (ambientTemp != null) {
            if (heatTemp != null) {
                dc.setPenWidth(range_arc_w);
                if (ambientTemp < heatTemp) {
                    dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                    dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, ambientArc, heatArc);
                } else {
                    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
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
            }

            if (coolTemp != null) {
                dc.setPenWidth(range_arc_w);
                if (coolTemp < ambientTemp) {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, coolArc, ambientArc);
                } else {
                    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
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
            }
        }

        var minTemp = mNestStatus.getScale() == 'C' ? Globals.minTempC : Globals.minTempF;
        var maxTemp = mNestStatus.getScale() == 'C' ? Globals.maxTempC : Globals.maxTempF;
        var incTemp = mNestStatus.getScale() == 'C' ? Globals.incTempC : Globals.incTempF;

        for (var i = minTemp; i <= maxTemp; i += incTemp) {
            var theta = mNestStatus.getScale() == 'C'
                ? lerp(i, Globals.minTempC, Globals.maxTempC, Globals.minTempArc, Globals.maxTempArc)
                : lerp(i, Globals.minTempF, Globals.maxTempF, Globals.minTempArc, Globals.maxTempArc);
            if (abs(i - (mNestStatus.round(i/10f, 1f) * 10f)) < 0.001f) {
                dc.setPenWidth(tick_major_w);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                drawTick(dc, theta, tick_st_r, tick_major_r, i.format("%2.0f"));
            } else if (abs(i - (mNestStatus.round(i/5f, 1f) * 5f)) < 0.001f) {
                dc.setPenWidth(tick_half_w);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                drawTick(dc, theta, tick_st_r, tick_half_r, null);
            } else {
                dc.setPenWidth(tick_minor_w);
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                drawTick(dc, theta, tick_st_r, tick_minor_r, null);
            }
        }

        // Make sure these ticks are drawn on top
        if (ambientTemp != null) {
            if (heatTemp != null) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(hct_tick_w);
                drawTick(dc, heatArc, tick_st_r, tick_ren_r, null);
            }
            if (coolTemp != null) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(hct_tick_w);
                drawTick(dc, coolArc, tick_st_r, tick_ren_r, null);
            }
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            drawDiamond(dc, ambientArc, tick_st_r);
        }
    }

    function abs(x as Lang.Float) {
        if (x < 0f) {
            return -x;
        } else {
            return x;
        }
    }

    function drawTempScaleMinimal(dc as Graphics.Dc, ambientTemp as Lang.Float, heatTemp as Lang.Float, coolTemp as Lang.Float) {
        var hw = dc.getWidth() / 2;
        var hh = dc.getHeight() / 2;
        dc.setColor(darkGreyColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(full_arc_w);
        dc.drawArc(hw, hh, hw - margin, Graphics.ARC_CLOCKWISE, Globals.minTempArc, Globals.maxTempArc);
        if (ambientTemp != null) {
            var ambientArc = mNestStatus.getScale() == 'C'
                ? lerp(ambientTemp, Globals.minTempC, Globals.maxTempC, Globals.minTempArc, Globals.maxTempArc)
                : lerp(ambientTemp, Globals.minTempF, Globals.maxTempF, Globals.minTempArc, Globals.maxTempArc);
            var heatArc = (heatTemp == null)
                ? 0
                : mNestStatus.getScale() == 'C'
                    ? lerp(heatTemp, Globals.minTempC, Globals.maxTempC, Globals.minTempArc, Globals.maxTempArc)
                    : lerp(heatTemp, Globals.minTempF, Globals.maxTempF, Globals.minTempArc, Globals.maxTempArc);
            var coolArc = (coolTemp == null)
                ? 0
                : mNestStatus.getScale() == 'C'
                    ? lerp(coolTemp, Globals.minTempC, Globals.maxTempC, Globals.minTempArc, Globals.maxTempArc)
                    : lerp(coolTemp, Globals.minTempF, Globals.maxTempF, Globals.minTempArc, Globals.maxTempArc);

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
                drawTick(dc, heatArc, tick_st_r, tick_ren_r, null);
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
                drawTick(dc, coolArc, tick_st_r, tick_ren_r, null);
            }

            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(at_tick_w);
            drawTick(dc, ambientArc, tick_st_r, tick_aen_r, null);
        }
    }
}