# Improvements & Enhancements

Track feature requests, performance optimizations, and code improvements.

## Library Block Discovery Automation Process

### Overview
Rather than manually referencing MATLAB documentation or guessing library paths, this project uses automated discovery of Simscape library structures. The `explore_simscape_domain.m` script consolidates the library search methodology into a generalized, reusable tool that works for any Simscape domain.

### Why Automation Matters
**Problem**: MATLAB documentation paths don't always match actual internal library structure.
- Documentation states "Pumps and Motors" but library uses "Pumps & Motors" (ampersand)
- Exact block names include domain suffixes: "Pressure Relief Valve (IL)" not just "Pressure Relief Valve"
- Library organization can change between MATLAB versions

**Solution**: Query the library directly using MATLAB's `find_system()` function rather than relying on static documentation.

### Core Methodology: Recursive find_system() Exploration

#### Key Function
```matlab
blocks = find_system(library_path, 'SearchDepth', 1, 'BlockType', 'SubSystem');
```

#### How It Works
1. **Library Root Identification**: Simscape Fluids uses root path `SimscapeFluids_lib/{DomainName}`
   - Example: `SimscapeFluids_lib/Isothermal Liquid`
   - Foundation Library uses: `nesl_utility/Simscape/Foundation Library`

2. **Category Discovery**: Search depth 1 finds immediate child subsystems (categories)
   - For Isothermal Liquid domain: Pumps & Motors, Valves & Orifices, Actuators, etc.
   - Returns full paths: `SimscapeFluids_lib/Isothermal Liquid/Pumps & Motors`

3. **Block Discovery**: Second-level search finds actual component blocks
   - Each category contains: `SimscapeFluids_lib/Isothermal Liquid/Pumps & Motors/Fixed-Displacement Pump (IL)`
   - Block paths include domain suffix (IL, TL, etc.) - **must match exactly for add_block()**

4. **Foundation Library Path**: Foundation blocks follow different structure
   - Path: `nesl_utility/Simscape/Foundation Library/{Category}/{SubCategory}/{Block}`
   - Examples: Sensors (Pressure, Flow Rate), Physical Signal Converters

#### Why SearchDepth=1
- `SearchDepth=1`: Returns only immediate children (faster, cleaner hierarchy)
- `SearchDepth=inf`: Returns ALL descendants (too much output, harder to navigate)
- Multiple calls with SearchDepth=1 provide controlled, hierarchical exploration

### Supported Simscape Domains
The discovery process works for:

**Simscape Fluids Domains**:
- Isothermal Liquid (IL)
- Thermal Liquid (TL)
- Pneumatics (PN)
- Two-Phase Fluid (2PH)
- Moist Air (MA)
- Gas (G)

**Foundation Library**:
- Physical Signals
- Sensors (all domains)
- Converters (Physical Signal ↔ Simulink)

### Workflow: From Schematic to Block Discovery

#### Step 1: Identify Domain from Schematic
- **Hydraulic schematics** (pumps, cylinders, relief valves) → Use "Isothermal Liquid" domain
- **Pneumatic schematics** (air compressors, air cylinders) → Use "Pneumatics" domain
- **Thermal schematics** (heat exchangers, temperature control) → Use "Thermal Liquid" domain
- **Electrical schematics** → Use "Electrical" domain (requires Simscape Electrical toolbox)

Example decision logic:
```
IF schematic contains: hydraulic fluid, pump, pressure relief → Isothermal Liquid
IF schematic contains: compressed air, pneumatic cylinder → Pneumatics
IF schematic contains: heat/temperature, thermal liquid → Thermal Liquid
```

#### Step 2: Run Library Explorer
```matlab
explore_simscape_domain('Isothermal Liquid')
```
Or interactively:
```matlab
explore_simscape_domain()  % Prompts user to select domain
```

#### Step 3: Extract Block Paths
Script displays all available blocks with library paths:
```
[CATEGORY] Pumps & Motors
------------------------------------------------------------
  • Fixed-Displacement Pump (IL)
    Path: SimscapeFluids_lib/Isothermal Liquid/Pumps & Motors/Fixed-Displacement Pump (IL)
  • Variable-Displacement Pump (IL)
    Path: SimscapeFluids_lib/Isothermal Liquid/Pumps & Motors/Variable-Displacement Pump (IL)
```

#### Step 4: Use Paths in Model Generation
Copy exact paths into MATLAB model generation scripts:
```matlab
add_block('SimscapeFluids_lib/Isothermal Liquid/Pumps & Motors/Fixed-Displacement Pump (IL)', ...
    [modelName '/Main_Pump'], ...
    'Position', [100 100 200 150]);
```

### Critical Details Discovered

#### 1. Ampersand in Category Names
- Category folders use `&` character: "Pumps & Motors", "Valves & Orifices"
- Documentation sometimes shows "and" but library uses "&"
- **Always use `&` in actual add_block() paths**

#### 2. Domain Suffixes on Block Names
Blocks display with domain codes:
- (IL) = Isothermal Liquid
- (TL) = Thermal Liquid
- (PN) = Pneumatics
- (2PH) = Two-Phase Fluid

Example: "Pressure Relief Valve (IL)" not "Pressure Relief Valve"
- **Must include suffix in add_block() path - it's part of the actual block name**

#### 3. Subcategories Within Categories
Some categories have subcategories (Valves & Orifices subdivides into Pressure Control, Flow Control, Directional Control):
```
Valves & Orifices
  ├─ Pressure Control
  │   └─ Pressure Relief Valve (IL)
  ├─ Flow Control
  │   └─ Needle Valve (IL)
  └─ Directional Control
      └─ 2-Way Directional Valve (IL)
```

Paths must include subcategory: `SimscapeFluids_lib/Isothermal Liquid/Valves & Orifices/Pressure Control/Pressure Relief Valve (IL)`

#### 4. Foundation Library Paths Are Different
Foundation blocks use `nesl_utility` root, not `SimscapeFluids_lib`:
```matlab
add_block('nesl_utility/Simscape/Foundation Library/Physical Signals/Sensors/Pressure Sensor', ...
    [modelName '/P_Sensor'], ...
    'Position', [100 100 150 150]);
```

### Executable Script Details

**Script**: `explore_simscape_domain.m`
**Location**: `scripts/matlab/explore_simscape_domain.m`
**Size**: ~300 lines with full documentation
**Dependencies**: MATLAB with Simscape Fluids (or any Simscape domain toolbox)

**Features**:
- Interactive mode: User selects from menu of available domains
- Direct mode: Pass domain name as argument
- Automatic path discovery: No hardcoded paths
- Hierarchical display: Shows categories and blocks organized logically
- No file output: All results printed to command window
- Reusable: Works for any domain, version-agnostic

**Usage Examples**:
```matlab
% Interactive mode - prompts user
explore_simscape_domain()

% Direct mode - specify domain
explore_simscape_domain('Isothermal Liquid')

% Foundation Library discovery
explore_simscape_domain('Foundation Library')

% Store results for reference
diary('library_inventory.txt')
explore_simscape_domain('Thermal Liquid')
diary off
```

### Lessons Learned

1. **MATLAB library browser is more reliable than documentation** for discovering exact paths and names
2. **Programmatic queries are version-agnostic** - find_system() works across MATLAB versions without hardcoding paths
3. **Domain suffix is mandatory** in block names - `(IL)` is not optional formatting, it's part of the actual block identifier
4. **Subcategory nesting matters** - shallow searches miss blocks, deep searches return too much clutter; SearchDepth=1 with iteration is optimal
5. **Special characters in paths** - Documentation uses "and" but library uses "&"; must test actual library structure

### Future Improvements

1. **Automated domain detection from P&ID**: Add image analysis to automatically detect domain from schematic
2. **Block parameter suggestions**: Link discovered blocks to parameter ranges and recommended values
3. **Quick-add function**: `add_blocks_from_schematic(P&ID_image)` that auto-generates model from image
4. **Comparison across domains**: Show how components differ between Isothermal and Thermal Liquid versions
5. **Performance data**: Display typical operating ranges for each block to aid configuration

### Project Integration

This discovery methodology is now the foundation for:
- **Phase 1**: Schematic → Block discovery → Model generation
- **Phase 2**: Model configuration and data logging
- **Phase 3**: UDP streaming to Unreal
- **Phase 4**: Unreal visualization

**Reusability**: Future projects with different schematics can use `explore_simscape_domain()` without modification - just change the domain parameter.

---

## High Priority Improvements
[To be defined]

## Medium Priority Improvements
[To be defined]

## Low Priority Improvements
[To be defined]

## Implemented
- ✅ Library Block Discovery Automation (consolidate list_all_components.m, list_block_names.m, find_block_paths.m → explore_simscape_domain.m)
