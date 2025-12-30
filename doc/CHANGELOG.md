# Changelog

All notable changes to this project will be documented in this file.

## Version History

### [Unreleased]

#### [2025-12-30] Phase 1 Progress - Model Generation & Library Automation

**Added - New Scripts:**
- ✅ `scripts/matlab/generate_simple_hydraulic_model.m` - Programmatically generates Simulink model
  - Creates .slx file with 13 blocks (9 component blocks + 4 pipe connectors)
  - Automatically adds blocks to model using MATLAB library paths
  - Configures Simscape solver (ode15s, 10-second simulation)
  - Status: WORKING - successfully generates SimpleHydraulicSystem.slx

- ✅ `scripts/matlab/explore_simscape_domain.m` - Generalized domain-aware library explorer
  - Consolidated 3 ad-hoc discovery scripts into 1 reusable tool
  - Supports ANY Simscape domain via domain parameter
  - Supports Foundation Library (fl_lib) blocks
  - Uses recursive find_system() for automatic block discovery
  - Status: WORKING - tested with Isothermal Liquid and Foundation Library domains

**Added - Documentation:**
- ✅ `doc/improvements.md` - Complete "Library Block Discovery Automation Process" section
  - Documents find_system() recursive search methodology
  - Explains domain-driven library structure
  - Records critical discoveries:
    * Ampersand in category names: "Pumps & Motors" (not "and")
    * Domain suffixes mandatory: "Pressure Relief Valve (IL)" is exact block name
    * Subcategory nesting structure (Valves → Pressure Control → blocks)
    * Foundation Library uses fl_lib root or nesl_utility/Simscape/Foundation Library
  - Provides usage examples
  - Outlines future improvements (automated domain detection, parameter suggestions)

**Generated Artifacts:**
- ✅ `models/simscape/SimpleHydraulicSystem.slx`
  - Created by generate_simple_hydraulic_model.m
  - Contains 13 blocks total:
    * 2x Fixed-Displacement Pump (Motor_Pump, Main_Pump)
    * 1x Pressure Relief Valve
    * 1x 2-Way Directional Valve (vent)
    * 1x Needle Valve (flow control)
    * 1x Check Valve
    * 1x Local Resistance (filter)
    * 1x Double-Acting Actuator (cylinder)
    * 1x Tank
    * 1x Isothermal Liquid Predefined Properties (fluid model)
    * 4x Pipe blocks
  - Status: Blocks added but NOT YET CONNECTED per schematic

#### Research Completed
- ✅ Isothermal Liquid Library structure fully mapped
- ✅ Foundation Library (fl_lib) block inventory discovered
- ✅ Library path syntax rules documented (ampersand, domain suffixes)
- ✅ All 9 schematic components → Simscape blocks confirmed to exist
- ✅ Example projects found: Hydrostatic transmission, front-loader, power steering

#### In Progress
- ⏳ Phase 1 Task 1: Block connection in .slx per schematic topology
  - Generated model exists, blocks added
  - NEXT: Manually open SimpleHydraulicSystem.slx and connect 13 blocks
  - Connection must follow SimpleHydraulicSchematics.jpg flow paths
- ⏳ Library explorer: Foundation Library fl_lib block names (working, may need refinement)

#### Fixed/Resolved
- ✅ Library path errors: "Pumps and Motors" → "Pumps & Motors" (ampersand required)
- ✅ Solver Configuration block path doesn't exist (removed, used set_param instead)
- ✅ Sensor blocks paths corrected (Foundation Library path structure)
- ✅ Domain suffix discovery: All blocks include (IL), (TL), etc. in actual names
- ✅ MATLAB function compatibility: Changed startswith() to strncmp() for R2025b

#### Known Issues
- Foundation Library block display in explore script shows structure but blocks may need deeper recursion
- Linear wrapping in explore script output (minor display formatting)

#### Research Completed (Original)

#### Changed
[To be updated]

#### Fixed
[To be updated]

#### Removed
[To be updated]

---

## Version Format
Following [Keep a Changelog](https://keepachangelog.com/) format.
