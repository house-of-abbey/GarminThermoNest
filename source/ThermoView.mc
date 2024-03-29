//-----------------------------------------------------------------------------------
//
// Distributed under MIT Licence
//   See https://github.com/house-of-abbey/GarminThermoNest/blob/main/LICENSE.
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
using Toybox.Math;

class ThermoView extends ScalableView {
    private const cMargin        = 3f;
    private const cFull_arc_w    = 1.5f;
    private const cRange_arc_w   = 3f;
    private const cHct_tick_w    = 2f;
    private const cAt_tick_w     = 2f;
    private const cTick_st_r     = 1f;
    private const cTick_ren_r    = 7f;
    private const cTick_aen_r    = 5f;
    private const cTick_major_r  = 6f;
    private const cTick_half_r   = 4f;
    private const cTick_minor_r  = 3f;
    private const cTick_major_w  = 3f;
    private const cTick_half_w   = 1f;
    private const cTick_minor_w  = 0.5f;
    private const cDiamondwidth  = 2f;
    private const cDiamondHeight = 7f;
    // Between the full range arc and the outside of the watch face
    private var margin        = 3f;
    // Line width of the full range arc
    private var full_arc_w    = 1.5f;
    // Line width of the range arc (thicker than full_arc_w)
    private var range_arc_w   = 3f;
    // Heat & cool line width of a tick mark
    private var hct_tick_w    = 1f;
    // Ambient temperature line width of a tick mark
    private var at_tick_w     = 2f;
    // Ticks start at: watch radius - tick_st_r
    private var tick_st_r     = 1f;
    // Temperature range ends: watch radius - tick_ren_r
    private var tick_ren_r    = 7f;
    // Ambient temperature: watch radius - tick_aen_r
    private var tick_aen_r    = 5f;
    // Temperature major tick (10s): watch radius - tick_deep_r
    private var tick_major_r  = 6f;
    // Temperature half tick (5s): watch radius - tick_half_r
    private var tick_half_r   = 4f;
    // Temperature minor tick (1s): watch radius - tick_minor_r
    private var tick_minor_r  = 2f;
    // Temperature major tick width (10s)
    private var tick_major_w  = 3f;
    // Temperature half tick width (5s)
    private var tick_half_w   = 1f;
    // Temperature minor tick width (1s)
    private var tick_minor_w  = 0.5f;
    // Diamond dimensions
    private var diamondwidth  = 2f;
    private var diamondHeight = 7f;
    // Additional colours over Globals
    protected const darkGreyColor = 0xaaaaaa;
    protected var mNestStatus as NestStatus;

    function initialize(ns as NestStatus) {
        ScalableView.initialize();
        mNestStatus   = ns;
        margin        = pixelsForScreen(cMargin       );
        full_arc_w    = pixelsForScreen(cFull_arc_w   );
        range_arc_w   = pixelsForScreen(cRange_arc_w  );
        hct_tick_w    = pixelsForScreen(cHct_tick_w   );
        at_tick_w     = pixelsForScreen(cAt_tick_w    );
        tick_st_r     = pixelsForScreen(cTick_st_r    );
        tick_ren_r    = pixelsForScreen(cTick_ren_r   );
        tick_aen_r    = pixelsForScreen(cTick_aen_r   );
        tick_major_r  = pixelsForScreen(cTick_major_r );
        tick_half_r   = pixelsForScreen(cTick_half_r  );
        tick_minor_r  = pixelsForScreen(cTick_minor_r );
        tick_major_w  = pixelsForScreen(cTick_major_w );
        tick_half_w   = pixelsForScreen(cTick_half_w  );
        tick_minor_w  = pixelsForScreen(cTick_minor_w );
        diamondwidth  = pixelsForScreen(cDiamondwidth );
        diamondHeight = pixelsForScreen(cDiamondHeight);
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
        // Rectangular faces need to use the largest square area.
        var hs = (hh < hw) ? hh : hw;
        if (str != null) {
            // dc.getTextDimensions(str, Graphics.FONT_XTINY) returns the same as
            // [dc.getTextWidthInPixels(str, Graphics.FONT_XTINY), dc.getFontHeight(Graphics.FONT_XTINY)] only the
            // text height seems to include line spacing and is too large.
            dc.drawText(
                ca * (hs - start - dc.getTextWidthInPixels(str, Graphics.FONT_XTINY)/2) + hw,
                cb * (hs - start - dc.getFontHeight(Graphics.FONT_XTINY)/4) + hh,
                Graphics.FONT_XTINY,
                str,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            dc.drawLine(ca * (hs - end) + hw, cb * (hs - end) + hh, ca * (hs - start) + hw, cb * (hs - start) + hh);
        }
    }

    // Draw a diamond shape at various angles of rotation.
    //
    function drawDiamond(dc as Graphics.Dc, theta as Lang.Number, start as Lang.Number) {
        var end  = start + diamondHeight;
        var crad = Math.toRadians(360 - theta);
        var ca   = Math.cos(crad); // Width component
        var cb   = Math.sin(crad); // Height component
        var hw   = dc.getWidth() / 2;
        var hh   = dc.getHeight() / 2;
        // Rectangular faces need to use the largest square area.
        var hs = (hh < hw) ? hh : hw;
        dc.fillPolygon([
            [ca * (hs -          end   )                       + hw, cb * (hs -          end   )                       + hh],
            [ca * (hs - (start + end)/2) + (cb * diamondwidth) + hw, cb * (hs - (start + end)/2) - (ca * diamondwidth) + hh],
            [ca * (hs -  start         )                       + hw, cb * (hs -  start         )                       + hh],
            [ca * (hs - (start + end)/2) - (cb * diamondwidth) + hw, cb * (hs - (start + end)/2) + (ca * diamondwidth) + hh]
        ]);
    }

    // Decide which temperature scale to draw on the face based on the application settings.
    //
    function drawTempScale(dc as Graphics.Dc, ambientTemp as Lang.Float, heatTemp as Lang.Float, coolTemp as Lang.Float) as Void {
        if (Properties.getValue("faceSelect") == 0) {
            drawTempScaleTicks(dc, ambientTemp, heatTemp, coolTemp);
        } else {
            drawTempScaleMinimal(dc, ambientTemp, heatTemp, coolTemp);
        }
    }

    // Draw the "Ticks" version of the temperature scale.
    //
    function drawTempScaleTicks(dc as Graphics.Dc, ambientTemp as Lang.Float, heatTemp as Lang.Float, coolTemp as Lang.Float) as Void {
        var hw = dc.getWidth() / 2;
        var hh = dc.getHeight() / 2;
        // Rectangular faces need to use the largest square area.
        var hs = (hh < hw) ? hh : hw;

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
                    dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, ambientArc, heatArc);
                } else {
                    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                    if (coolTemp != null) {
                        if (coolTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, heatArc, coolArc);
                        }
                    } else {
                        if (ambientTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, heatArc, ambientArc);
                        }
                    }
                }
            }

            if (coolTemp != null) {
                dc.setPenWidth(range_arc_w);
                if (coolTemp < ambientTemp) {
                    dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                    dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, coolArc, ambientArc);
                } else {
                    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                    if (heatTemp != null) {
                        if (coolTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, heatArc, coolArc);
                        }
                    } else {
                        if (coolTemp > ambientTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, ambientArc, coolArc);
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
            dc.setColor(darkGreyColor, Graphics.COLOR_TRANSPARENT);
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

    // Draw the "Minimal" version of the temperature scale.
    //
    function drawTempScaleMinimal(dc as Graphics.Dc, ambientTemp as Lang.Float, heatTemp as Lang.Float, coolTemp as Lang.Float) {
        var hw = dc.getWidth() / 2;
        var hh = dc.getHeight() / 2;
        // Rectangular faces need to use the largest square area.
        var hs = (hh < hw) ? hh : hw;
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
                    dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, ambientArc, heatArc);
                } else {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    if (coolTemp != null) {
                        if (coolTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, heatArc, coolArc);
                        }
                    } else {
                        if (ambientTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, heatArc, ambientArc);
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
                    dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, coolArc, ambientArc);
                } else {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                    if (heatTemp != null) {
                        if (coolTemp > heatTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, heatArc, coolArc);
                        }
                    } else {
                        if (coolTemp > ambientTemp) {
                            // Test prevents full circle arc being drawn
                            dc.drawArc(hw, hh, hs - margin, Graphics.ARC_CLOCKWISE, ambientArc, coolArc);
                        }
                    }
                }
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(hct_tick_w);
                drawTick(dc, coolArc, tick_st_r, tick_ren_r, null);
            }

            dc.setColor(darkGreyColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(at_tick_w);
            drawTick(dc, ambientArc, tick_st_r, tick_aen_r, null);
        }
    }

    function getNestStatus() as NestStatus {
        return mNestStatus;
    }
}
