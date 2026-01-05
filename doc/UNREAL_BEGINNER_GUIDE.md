# Unreal Engine Beginner's Guide: Testing APlaybackManager

This guide assumes you've never used Unreal Engine before. Follow these steps to see your Simscape data playing back in 3D.

## Step 1: Launch the Unreal Editor

1. **Open PowerShell** (press `Win+X`, then select "Windows PowerShell" or "Terminal")

2. **Run this command** (copy and paste):
   ```powershell
   & "C:\Program Files\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe" "C:\0Work\Projects\LLM-MCP\UnrealProject\SimpleHydraulics\SimpleHydraulics.uproject"
   ```

3. **Wait for the Editor to load** (takes 30-60 seconds on first launch)
   - You'll see a splash screen, then the main Editor window
   - The Editor has several panels (we'll explain each below)

## Step 2: Understanding the Unreal Editor Interface

Once the Editor opens, you'll see these main areas:

```
┌─────────────────────────────────────────────────────────────┐
│ Toolbar (top) - Play, Build, Save buttons                  │
├──────────────┬──────────────────────────┬───────────────────┤
│              │                          │                   │
│  Content     │    Viewport (center)     │  World Outliner   │
│  Browser     │  - 3D view of your world │  - List of actors │
│  (bottom     │  - Where you see actors  │  - Scene objects  │
│   left)      │                          │                   │
│              │                          │                   │
├──────────────┴──────────────────────────┤  Details Panel    │
│  Output Log (bottom)                    │  - Properties of  │
│  - Messages, warnings, errors           │    selected actor │
└─────────────────────────────────────────┴───────────────────┘
```

**Key panels for this task:**
- **Viewport** (center-large): The 3D world where you'll see your hydraulic simulation
- **Place Actors** (if visible on left): Panel to add objects to your scene
- **Content Browser** (bottom): File browser for your project assets
- **World Outliner** (right side, top): List of all objects in the current level
- **Details** (right side, bottom): Properties of the selected object
- **Output Log** (bottom): Console messages (important for debugging)

## Step 3: Open or Create a Level

A "Level" is like a scene or map in Unreal.

1. **Check if a level is already open**:
   - Look at the top tab bar - you might see something like "Untitled" or a level name
   - If you see "Select a level to begin", continue to step 2

2. **Create a new level** (if needed):
   - Click **File** → **New Level**
   - Choose **Empty Level** (simplest option)
   - Click **Create**

3. **Save the level**:
   - Press `Ctrl+S` or click **File** → **Save Current Level**
   - Name it `TestPlayback`
   - Location should be `Content/Maps/` (default)
   - Click **Save**

## Step 4: Add the PlaybackManager to Your Level

Now we'll place the C++ actor we created into the scene.

### Method 1: Using Place Actors Panel (Easier)

1. **Open the Place Actors panel** (if not visible):
   - Click **Window** → **Place Actors**
   - It appears on the left side

2. **Find PlaybackManager**:
   - In the Place Actors search box (top), type: `playback`
   - You should see **Playback Manager** appear in the list
   - **If you DON'T see it**: Use Method 2 below

3. **Drag it into the Viewport**:
   - Click and hold **Playback Manager** from the list
   - Drag your mouse into the center **Viewport** (the 3D view)
   - Release to drop it into the world
   - You'll see a small icon/sphere appear in the 3D view

### Method 2: Using Content Browser (Alternative)

1. **Open Content Browser** (bottom panel):
   - If not visible: **Window** → **Content Browser**

2. **Navigate to C++ Classes**:
   - In the Content Browser, look for the folder tree on the left
   - Click the folder icon dropdown (top-left of Content Browser)
   - Check the box: **Show C++ Classes**
   - You'll see a new folder appear: **C++ Classes**

3. **Find PlaybackManager**:
   - Click **C++ Classes** → **SimpleHydraulics**
   - You should see **PlaybackManager** as a blue-icon asset

4. **Drag into Viewport**:
   - Click and drag **PlaybackManager** into the center **Viewport**
   - Release to place it in the world

### Verify Placement

- Look in the **World Outliner** (right panel, top)
- You should see **PlaybackManager** listed
- Click on it to select it (it will highlight in the Viewport)

## Step 5: Configure PlaybackManager Properties

With the PlaybackManager selected (click it in World Outliner if not selected):

1. **Look at the Details Panel** (right side, bottom):
   - This shows all properties of the selected actor
   - Scroll down to find the **Playback** category

2. **Set the Data File Path**:
   - Find the property: **Data File Path**
   - Click in the text field
   - Clear any existing text and type exactly:
     ```
     Content/Data/unreal_playback.json
     ```
   - Press `Enter` to confirm

3. **Configure Playback Settings** (optional but recommended):
   - **Auto Spawn On Begin Play**: ✅ Check this (should be checked by default)
   - **Start Paused**: ❌ Uncheck this (we want auto-play)
   - **Playback Speed**: `1.0` (real-time speed)
   - **Num Pumps**: `6`
   - **Num Cylinders**: `1`
   - **Num Pipes**: `4`
   - **Actor Spacing**: `200.0`

4. **Save your changes**:
   - Press `Ctrl+S` to save the level

## Step 6: Enable the Output Log (Important!)

The Output Log shows debug messages from our PlaybackManager.

1. **Open Output Log** (if not visible):
   - Click **Window** → **Developer Tools** → **Output Log**
   - It opens in the bottom panel

2. **Clear existing messages** (optional):
   - Click the **Clear** button (trash icon) in the Output Log toolbar

## Step 7: Play the Scene

Now the exciting part - run the simulation!

1. **Click the Play button** in the top toolbar:
   - Look for the green **Play** ▶ button (top-center of Editor)
   - Or press `Alt+P` (keyboard shortcut)

2. **Watch what happens**:
   
   **In the Output Log**, you should see messages like:
   ```
   LogTemp: Warning: PlaybackManager: Loaded 31671 frames from C:/0Work/.../unreal_playback.json
   LogTemp: Log: Spawned: Pump_01 at X=200.000 Y=0.000 Z=50.000
   LogTemp: Log: Spawned: Pump_02 at X=400.000 Y=0.000 Z=50.000
   ...
   LogTemp: Warning: PlaybackManager: Spawned 11 placeholder actors
   LogTemp: Log: PlaybackManager: Playback started
   ```

   **In the Viewport**, you should see:
   - The camera view might change (you're now in "Play Mode")
   - If you're far from the spawned actors, you might not see them yet (that's okay - we'll fix this in the next step)

3. **Stop Play Mode**:
   - Press `Escape` or click the **Stop** ⏹ button (top toolbar)
   - This returns you to Edit Mode

## Step 8: Find and View the Spawned Actors

The actors were spawned, but you might not be looking at them. Let's navigate to them.

1. **Open World Outliner** (if not visible):
   - **Window** → **World Outliner**

2. **Search for spawned actors**:
   - In the World Outliner search box, type: `Pump`
   - You should now see: `Pump_01`, `Pump_02`, `Pump_03`, etc.

3. **Frame an actor in the Viewport**:
   - Click on `Pump_01` in the World Outliner
   - Press the `F` key (F = Frame Selected)
   - Your Viewport camera will move to show `Pump_01`
   - You should see a small sphere/icon representing the actor

4. **See all spawned actors**:
   - In the World Outliner, clear the search box
   - Scroll through the list - you should see:
     - `Pump_01` through `Pump_06`
     - `Cylinder_01`
     - `PipeSpline_01` through `PipeSpline_04`
     - `PlaybackManager` (the manager itself)

## Step 9: Watch the Playback Animation

Now let's see the actors animate based on your Simscape data.

1. **Select an actor to watch** (optional but helpful):
   - Click `Pump_01` in the World Outliner
   - Press `F` to frame it in the Viewport

2. **Click Play again** (`Alt+P` or green Play button)

3. **Watch the Output Log** for real-time updates:
   - You'll see messages every time a frame is applied
   - The playback is running based on the simulation time

4. **Observe the Viewport**:
   - The actors should **move up and down** (Z-axis) based on pressure values
   - This is a simple placeholder animation - higher pressure = higher Z position
   - With 31,671 frames and real-time playback, it will run for ~30 seconds

5. **Press Escape to stop** when you're done watching

## Step 10: Manual Frame Control (Advanced)

You can also control playback manually using Blueprints or the console.

### Using the Console (for testing):

1. **While in Play Mode** (after clicking Play):
   - Press the **`** (backtick/grave) key to open the console
   - Type: `ke * PlaybackManager.Pause`
   - Press Enter (pauses playback)

2. **Apply a specific frame**:
   - Type: `ke * PlaybackManager.ApplyFrame 1000`
   - Press Enter (jumps to frame 1000)

3. **Resume playback**:
   - Type: `ke * PlaybackManager.Play`
   - Press Enter

## Troubleshooting

### "I don't see PlaybackManager in Place Actors"
- Make sure the project compiled successfully (check the Build step earlier)
- Try Method 2 (Content Browser → C++ Classes)
- Restart the Editor and try again

### "PlaybackManager: Failed to load JSON file"
- Check the Output Log for the exact error message
- Verify the file exists at: `C:\0Work\Projects\LLM-MCP\UnrealProject\SimpleHydraulics\Content\Data\unreal_playback.json`
- Make sure DataFilePath is set to exactly: `Content/Data/unreal_playback.json`

### "I don't see any actors spawning"
- Check the Output Log for error messages
- Make sure "Auto Spawn On Begin Play" is checked
- Try manually calling `SpawnPlaceholderActors()`:
  - Select PlaybackManager in World Outliner
  - In Details panel, scroll to find "Call Function" or events section

### "The actors are too small / I can't see them"
- The actors spawn as simple collision primitives (invisible by default)
- Select an actor in World Outliner, press `F` to frame it
- Look for small wireframe spheres in the Viewport
- Next step: assign visible static meshes (covered in advanced guide)

### "Output Log shows errors about missing modules"
- The Editor needs to be recompiled - exit and run the Build.bat command again
- Check that Json and JsonUtilities were added to SimpleHydraulics.Build.cs

## Next Steps (After Successful Playback)

Once you see the basic playback working:

1. **Add visible meshes** to the spawned actors:
   - Select a Pump actor
   - In Details → Static Mesh Component → Static Mesh
   - Choose a mesh like "Cube" or "Sphere" from Starter Content

2. **Create dynamic materials** for pressure visualization:
   - Create a Material asset with a color parameter
   - Create Material Instance Dynamic in PlaybackManager
   - Set color based on pressure value

3. **Add Niagara particle systems** for flow visualization

4. **Integrate UDP streaming** (Phase 2C) for real-time updates from MATLAB

## Summary: Quick Test Checklist

✅ Editor opened successfully  
✅ New level created and saved  
✅ PlaybackManager placed in level  
✅ DataFilePath set to `Content/Data/unreal_playback.json`  
✅ Auto Spawn enabled  
✅ Output Log opened  
✅ Clicked Play  
✅ Saw "Loaded 31671 frames" message  
✅ Saw "Spawned 11 actors" message  
✅ Found actors in World Outliner  
✅ Observed Z-position animation during playback  

---

**Questions?** Check the Output Log first - it shows most errors and success messages with detailed paths and values.
