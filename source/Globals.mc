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

(:glance)
class Globals {
    // Multi-dot navigation drawable on each View
    static const navRadius    = 5;
    static const navMarginX   = 30;
    static const navPanes     = 3;
    static const navDelay     = 1000; // ms
    static const navPeriod    = 0.5;  // s
}
