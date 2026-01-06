# Niagara Flow System Setup Guide

## Issue: Missing Fountain System

**Error from UE log:**
```
LogTemp: Error: FlowParticleSystem not set - cannot spawn flow visualization. 
Make sure Niagara Fountain system is available.
```

**Root Cause:**
- PlaybackManager.cpp attempts to load `/Niagara/Systems/Fountain`
- This system does NOT exist in UE 5.7 installation
- FObjectFinder fails, FlowParticleSystem = nullptr

## Solution: Create Custom Niagara System

### Step 1: Run Python Script in Unreal Editor

1. **Open Unreal Editor** with SimpleHydraulics project
2. **Open Python Console**: Window → Developer Tools → Output Log → Python
3. **Run the script**:
   ```python
   exec(open(r'C:\0Work\Projects\LLM-MCP\UnrealProject\SimpleHydraulics\Content\Python\create_niagara_flow_system.py').read())
   ```
4. **Check Output Log** for success message and manual configuration steps

### Step 2: Manual Configuration in Niagara Editor

The script creates a basic template at `/Game/Niagara/NS_FlowParticles`. You must configure it manually:

1. **Open Content Browser** → Content → Niagara folder
2. **Double-click NS_FlowParticles** to open Niagara Editor

3. **Add User Parameters** (System Parameters panel on left):
   - Click '+' button → Add Parameter
   - **Parameter 1:**
     * Name: `SpawnRate`
     * Type: Float
     * Default Value: 10.0
   - **Parameter 2:**
     * Name: `Velocity` 
     * Type: Float
     * Default Value: 100.0

4. **Configure Emitter** (or add new GPU Sprite Emitter if empty):
   
   **Emitter Spawn Group:**
   - Find "Spawn Rate" module
   - Change value from constant to: `User.SpawnRate` (use dropdown)
   
   **Emitter Update Group:**
   - If "Add Velocity" module not present, click '+' and add it
   - Set Velocity: `User.Velocity`
   - Velocity Mode: From Simulation
   
   **Particle Spawn Group:**
   - Find "Initialize Particle" module
   - Set these properties:
     * **Lifetime**: 2.0 seconds
     * **Color**: Cyan (R=0.0, G=0.8, B=1.0, A=1.0)
     * **Sprite Size**: Uniform 7.0 cm (fits inside 30cm pipes)
     * **Sprite Rotation**: 0 (or random if desired)

5. **Compile** the system (green checkmark button)
6. **Save** (Ctrl+S)
7. **Close** Niagara Editor

### Step 3: Update PlaybackManager.cpp

Change the Niagara system path in the constructor:

**Find this code** (around line 40-50):
```cpp
static ConstructorHelpers::FObjectFinder<UNiagaraSystem> NiagaraSystemAsset(TEXT("/Niagara/Systems/Fountain"));
if (NiagaraSystemAsset.Succeeded()) {
    FlowParticleSystem = NiagaraSystemAsset.Object;
    UE_LOG(LogTemp, Log, TEXT("Loaded Niagara Fountain system for flow visualization"));
} else {
    UE_LOG(LogTemp, Warning, TEXT("Failed to load Niagara Fountain system - flow particles may not appear"));
}
```

**Replace with:**
```cpp
static ConstructorHelpers::FObjectFinder<UNiagaraSystem> NiagaraSystemAsset(TEXT("/Game/Niagara/NS_FlowParticles"));
if (NiagaraSystemAsset.Succeeded()) {
    FlowParticleSystem = NiagaraSystemAsset.Object;
    UE_LOG(LogTemp, Log, TEXT("Loaded custom Niagara flow system: NS_FlowParticles"));
} else {
    UE_LOG(LogTemp, Error, TEXT("Failed to load /Game/Niagara/NS_FlowParticles - flow particles will not appear!"));
}
```

### Step 4: Rebuild and Test

1. **Close Unreal Editor** (important for clean build)
2. **Rebuild Project:**
   ```powershell
   cd C:\0Work\Projects\LLM-MCP\SimscapeFluid
   & "C:\Program Files\Epic Games\UE_5.7\Engine\Build\BatchFiles\Build.bat" SimpleHydraulicsEditor Win64 Development "C:\0Work\Projects\LLM-MCP\UnrealProject\SimpleHydraulics\SimpleHydraulics.uproject" -waitmutex
   ```
3. **Launch Editor**
4. **Press Play** in PIE
5. **Check Output Log** for:
   ```
   LogTemp: Log: Loaded custom Niagara flow system: NS_FlowParticles
   LogTemp: Warning: ==== Spawning Niagara flow particles for 12 pipes ====
   LogTemp: Warning:   Pipe 0: SUCCESS - Spawned Niagara component, scale=0.1
   ...
   LogTemp: Warning:   Pipe 11: SUCCESS - Spawned Niagara component, scale=0.1
   ```
6. **Verify visually**: Cyan particles flowing inside pipes

### Expected Result

- 12 Niagara systems spawned (one per pipe)
- Particles spawn at rate matching flow data (0-100 particles/sec)
- Particle velocity changes with flow magnitude
- Small particles (7cm) fit inside 30cm diameter pipes
- Cyan color represents water
- Particles move along pipe splines
- Real-time updates during playback

### Troubleshooting

**If particles don't appear:**
- Check Output Log for "SUCCESS" messages per pipe
- Verify NS_FlowParticles exists in Content Browser
- Check User.SpawnRate and User.Velocity parameters are properly configured
- Try increasing SpawnRate default value in Niagara system
- Check particle size isn't too small to see

**If particles are outside pipes:**
- Verify SpawnFlowParticles() uses scale 0.1x
- Check attachment point is SplineComponent root
- Adjust particle spawn offset in Niagara system

**If performance is poor:**
- Reduce SpawnRate maximum value
- Decrease particle lifetime
- Use GPU sprites (not CPU)
- Check only 12 systems are spawned (one per pipe)

### Fallback Option

If Niagara proves too complex, revert to the working sphere mesh approach:

```bash
cd C:\0Work\Projects\LLM-MCP\SimscapeFluid
git checkout 8b72ee5
```

Commit 8b72ee5 has fully functional flow visualization with moving sphere actors.

## Parameter Details

### User.SpawnRate (Flow Visualization)
- **Range**: 0-100 particles/second
- **Calculation**: `FlowMagnitude × 100000.0`
- **Units**: Flow in m³/s → particles/sec
- **Example**: 0.001 m³/s = 100 particles/sec

### User.Velocity (Particle Movement)
- **Range**: Variable, based on flow
- **Calculation**: `FlowValue × FlowSpeedScale` (100,000 cm/s per m³/s)
- **Units**: cm/s
- **Example**: 0.001 m³/s = 100 cm/s

### Particle Lifetime
- **Value**: 2.0 seconds
- **Purpose**: Particles exist long enough to see movement but don't accumulate excessively

### Particle Size
- **Value**: 7.0 cm
- **Constraint**: Must fit inside 30cm diameter pipes (< 15cm)
- **Visibility**: Large enough to see clearly

### Color
- **Value**: Cyan (0.0, 0.8, 1.0)
- **Purpose**: Water-like appearance, contrasts with blue/red pressure colors
