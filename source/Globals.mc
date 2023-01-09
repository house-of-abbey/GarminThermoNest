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
// Globals contains constants used throughout the application, typically related to
// layout positions.
//
//-----------------------------------------------------------------------------------

using Toybox.Graphics;

(:glance)
class Globals {
    // Enable printing of messages to the debug console (don't make this a Property
    // as the messages can't be read from a watch!)
    static const debug        = false;
    // Multi-dot navigation drawable on each View
    static const navRadius    = 8;
    static const navMarginX   = 40;
    static const navPanes     = 3;
    static const navDelay     = 1000; // ms
    static const navPeriod    = 0.5;  // s

    static const heatingColor  = 0xEC7800;
    static const coolingColor  = 0x285DF7;
    static const offColor      = Graphics.COLOR_BLACK;
}
