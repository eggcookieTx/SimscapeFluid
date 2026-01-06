"""
Create Custom Niagara Flow Particle System for Hydraulic Visualization

Purpose:
    Generate a Niagara particle system specifically designed for flow visualization
    inside hydraulic pipes. The system needs custom parameters that can be controlled
    from C++ to visualize flow rate and velocity based on simulation data.

System Requirements:
    - GPU sprite emitter for performance (12 pipes × particles)
    - User.SpawnRate parameter (0-100 particles/sec, controlled by flow data)
    - User.Velocity parameter (cm/s, controlled by flow magnitude)
    - Small particle size (5-10cm) to fit inside 30cm diameter pipes
    - Cyan color for water visualization
    - Particle lifetime ~2 seconds
    - Velocity inheritance from spawn location

Save Path: /Game/Niagara/NS_FlowParticles

Usage:
    1. Open Unreal Editor with SimpleHydraulics project
    2. Open Python console: Tools → Python
    3. Run: exec(open(r'C:\\path\\to\\create_niagara_flow_system.py').read())
    4. Check Output Log for success message
    5. Verify system exists in Content Browser: /Game/Niagara/NS_FlowParticles

Dependencies:
    - Unreal Engine 5.7
    - unreal module (built-in)

Author: AI Assistant
Date: January 6, 2026
"""

import unreal

def create_flow_particle_system():
    """
    Create a custom Niagara system with User.SpawnRate and User.Velocity parameters
    for hydraulic flow visualization.
    """
    
    # Asset paths
    system_path = "/Game/Niagara/NS_FlowParticles"
    emitter_path = "/Game/Niagara/NE_FlowEmitter"
    
    # Create directory if needed
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    
    try:
        # Create Niagara emitter first
        unreal.log("Creating Niagara emitter...")
        
        # Create emitter from GPU sprite template
        emitter_factory = unreal.NiagaraEmitterFactoryNew()
        emitter = asset_tools.create_asset(
            asset_name="NE_FlowEmitter",
            package_path="/Game/Niagara",
            asset_class=unreal.NiagaraEmitter,
            factory=emitter_factory
        )
        
        if not emitter:
            unreal.log_error("Failed to create Niagara emitter!")
            return False
            
        unreal.log("Emitter created successfully")
        
        # Create Niagara system
        unreal.log("Creating Niagara system...")
        
        system_factory = unreal.NiagaraSystemFactoryNew()
        system = asset_tools.create_asset(
            asset_name="NS_FlowParticles",
            package_path="/Game/Niagara",
            asset_class=unreal.NiagaraSystem,
            factory=system_factory
        )
        
        if not system:
            unreal.log_error("Failed to create Niagara system!")
            return False
            
        unreal.log("System created successfully")
        
        # Add emitter to system
        unreal.log("Adding emitter to system...")
        # Note: System API for adding emitters programmatically is limited in Python
        # The system is created but may need manual emitter addition in editor
        
        # Save assets
        unreal.EditorAssetLibrary.save_asset(emitter_path)
        unreal.EditorAssetLibrary.save_asset(system_path)
        
        unreal.log_warning("=" * 80)
        unreal.log_warning("Niagara system created at: " + system_path)
        unreal.log_warning("MANUAL STEPS REQUIRED:")
        unreal.log_warning("1. Open " + system_path + " in Niagara Editor")
        unreal.log_warning("2. Add emitter from template or create new GPU Sprite emitter")
        unreal.log_warning("3. Add User Parameters:")
        unreal.log_warning("   - User.SpawnRate (float, default 10.0)")
        unreal.log_warning("   - User.Velocity (float, default 100.0)")
        unreal.log_warning("4. In Emitter Stack:")
        unreal.log_warning("   - Spawn Rate: Set to User.SpawnRate parameter")
        unreal.log_warning("   - Add Velocity: Set to User.Velocity")
        unreal.log_warning("   - Sprite Size: 5-10 cm")
        unreal.log_warning("   - Color: Cyan (0, 0.8, 1.0)")
        unreal.log_warning("   - Lifetime: 2.0 seconds")
        unreal.log_warning("5. Save and close")
        unreal.log_warning("=" * 80)
        
        return True
        
    except Exception as e:
        unreal.log_error(f"Error creating Niagara system: {str(e)}")
        return False


def create_simple_niagara_system():
    """
    Alternative approach: Create a basic Niagara system that can be modified manually.
    This bypasses the complex Python API limitations.
    """
    
    try:
        unreal.log("=" * 80)
        unreal.log("CREATING SIMPLE NIAGARA SYSTEM TEMPLATE")
        unreal.log("=" * 80)
        
        asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
        
        # Create from Simple Sprite Burst template
        factory = unreal.NiagaraSystemFactoryNew()
        
        system = asset_tools.create_asset(
            asset_name="NS_FlowParticles",
            package_path="/Game/Niagara",
            asset_class=unreal.NiagaraSystem,
            factory=factory
        )
        
        if system:
            unreal.EditorAssetLibrary.save_asset("/Game/Niagara/NS_FlowParticles")
            
            unreal.log_warning("=" * 80)
            unreal.log_warning("SUCCESS: Niagara system created!")
            unreal.log_warning("Path: /Game/Niagara/NS_FlowParticles")
            unreal.log_warning("")
            unreal.log_warning("REQUIRED MANUAL CONFIGURATION:")
            unreal.log_warning("")
            unreal.log_warning("1. Open Content Browser → Niagara → NS_FlowParticles")
            unreal.log_warning("2. Double-click to open Niagara Editor")
            unreal.log_warning("")
            unreal.log_warning("3. ADD USER PARAMETERS (System User Parameters panel):")
            unreal.log_warning("   Click '+' → Add Parameter:")
            unreal.log_warning("   - Name: SpawnRate, Type: Float, Default: 10.0")
            unreal.log_warning("   - Name: Velocity, Type: Float, Default: 100.0")
            unreal.log_warning("")
            unreal.log_warning("4. CONFIGURE EMITTER (if needed, or add GPU Sprite emitter):")
            unreal.log_warning("   Emitter Spawn Group:")
            unreal.log_warning("   - Set 'Spawn Rate' module:")
            unreal.log_warning("     * Change from constant to: User.SpawnRate")
            unreal.log_warning("")
            unreal.log_warning("   Emitter Update Group:")
            unreal.log_warning("   - Add 'Add Velocity' module (if not present)")
            unreal.log_warning("     * Velocity: User.Velocity")
            unreal.log_warning("     * Velocity Mode: From Simulation")
            unreal.log_warning("")
            unreal.log_warning("   Particle Spawn Group:")
            unreal.log_warning("   - Set 'Initialize Particle' module:")
            unreal.log_warning("     * Lifetime: 2.0 seconds")
            unreal.log_warning("     * Color: Cyan (0.0, 0.8, 1.0)")
            unreal.log_warning("     * Sprite Size: Uniform 7.0 (fits in 30cm pipe)")
            unreal.log_warning("")
            unreal.log_warning("5. COMPILE and SAVE")
            unreal.log_warning("=" * 80)
            
            return True
        else:
            unreal.log_error("Failed to create Niagara system")
            return False
            
    except Exception as e:
        unreal.log_error(f"Error: {str(e)}")
        import traceback
        unreal.log_error(traceback.format_exc())
        return False


# Run the creation function
if __name__ == "__main__":
    unreal.log("Starting Niagara Flow System creation...")
    result = create_simple_niagara_system()
    
    if result:
        unreal.log("Script completed successfully!")
        unreal.log("Next step: Configure the system manually, then update PlaybackManager.cpp")
    else:
        unreal.log_error("Script failed. Check errors above.")
