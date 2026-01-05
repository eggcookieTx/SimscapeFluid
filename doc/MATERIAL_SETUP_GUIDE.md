# Material Setup Guide - Pressure Visualization

## Overview
This guide shows how to create a dynamic material that changes color based on pressure values (blue = low pressure, red = high pressure).

## Step 1: Create the Base Material

1. **Open Unreal Editor**
2. **Open Content Browser** (bottom panel)
3. **Create new folder:**
   - Right-click in Content Browser → New Folder → name it `Materials`
4. **Create Material:**
   - Right-click in Materials folder → Material → name it `M_Pressure`
   - Double-click to open Material Editor

## Step 2: Build the Material Graph

**In the Material Editor:**

1. **Create Scalar Parameter:**
   - Right-click in graph → Search "Scalar Parameter"
   - Name it: `Pressure` (EXACT name - case sensitive!)
   - Set Default Value: `0.5`

2. **Create Color Lerp (Blue to Red):**
   - Right-click → Search "Constant3Vector" → create TWO of them
   - First one (Blue): Set RGB to `(0, 0, 1)` - pure blue
   - Second one (Red): Set RGB to `(1, 0, 0)` - pure red
   - Right-click → Search "Lerp"
   - Connect Blue to Lerp's **A** input
   - Connect Red to Lerp's **B** input
   - Connect **Pressure parameter** to Lerp's **Alpha** input

3. **Connect to Material Output:**
   - Connect Lerp output → **Base Color** on the main material node

4. **Optional - Make it glow:**
   - Connect Lerp output → **Emissive Color** as well
   - This makes low pressure blue glow and high pressure red glow

5. **Save and Close:**
   - Click **Save** button (top left)
   - Close Material Editor

## Step 3: Configure PlaybackManager

1. **In the main Editor viewport:**
   - Find your PlaybackManager actor in the Outliner (left panel)
   - Select it

2. **In Details panel (right side):**
   - Scroll to "Playback | Visualization" section
   - **Pressure Material:** Click dropdown → select `M_Pressure`
   - **Pump Mesh:** Should already be set to `Cube` (Engine content)
   - **Cylinder Mesh:** Should already be set to `Cylinder` (Engine content)

## Step 4: Test the Visualization

1. **Make sure PlaybackManager is configured:**
   - DataFilePath = `Content/Data/unreal_playback.json`
   - Auto Spawn On Begin Play = ✓ (checked)

2. **Press Alt+P (or click Play button)**

3. **What you should see:**
   - 6 cube actors (pumps) spawn in a row
   - 1 cylinder actor spawns to the side
   - Actors have meshes now (visible!)
   - Colors change from blue → red as pressure changes
   - Actors move up and down based on pressure
   - Smooth playback of 31,671 frames

4. **Test controls:**
   - Press **Escape** to stop PIE
   - Press **Alt+P** again → should NOT crash (bug fixed!)

## Troubleshooting

**"Actors are still invisible"**
- Check that Pump Mesh and Cylinder Mesh are set in Details panel
- Should default to `/Engine/BasicShapes/Cube` and `/Engine/BasicShapes/Cylinder`

**"No color changes"**
- Check that Pressure Material is assigned in PlaybackManager
- Make sure material parameter is named exactly "Pressure" (case sensitive)
- Check Message Log for any errors

**"Material is all one color"**
- Open M_Pressure material, verify the Lerp is connected correctly
- Make sure Pressure parameter connects to Alpha input of Lerp

**"Editor crashes on second Play"**
- This should be fixed now! If it still crashes, report the error message

## Next Steps

Once this is working:
1. Add Niagara particle systems for fluid flow visualization
2. Implement cylinder rod extension/retraction animation
3. Add UI overlay showing pressure/flow values
4. Connect real-time UDP streaming from MATLAB

## Material Graph Reference

```
[Blue Color (0,0,1)] ─┐
                       ├─→ [Lerp] ─→ [Base Color / Emissive Color]
[Red Color (1,0,0)]  ─┘      ↑
                              │
                    [Pressure Parameter]
```

When Pressure = 0.0 → Blue (low pressure)
When Pressure = 0.5 → Purple (medium)
When Pressure = 1.0 → Red (high pressure)
