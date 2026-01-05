"""
Create M_Pressure material in Unreal Engine using Python API
This script must be run from inside Unreal Editor's Python console or through MCP
"""

import unreal

def create_pressure_material():
    """Create a dynamic pressure visualization material with blue->red gradient"""
    
    # Create material asset
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    material_factory = unreal.MaterialFactoryNew()
    
    package_path = "/Game/Materials"
    asset_name = "M_Pressure"
    
    # Create the material asset
    material = asset_tools.create_asset(
        asset_name, 
        package_path, 
        unreal.Material, 
        material_factory
    )
    
    if not material:
        unreal.log_error("Failed to create material asset")
        return None
    
    # Create material expression nodes
    # 1. Scalar Parameter for Pressure
    pressure_param = unreal.MaterialEditingLibrary.create_material_expression(
        material, 
        unreal.MaterialExpressionScalarParameter, 
        -400, 
        0
    )
    pressure_param.set_editor_property('parameter_name', 'Pressure')
    pressure_param.set_editor_property('default_value', 0.5)
    
    # 2. Blue color constant (0, 0, 1)
    blue_color = unreal.MaterialEditingLibrary.create_material_expression(
        material, 
        unreal.MaterialExpressionConstant3Vector, 
        -400, 
        -200
    )
    blue_color.set_editor_property('constant', unreal.LinearColor(0.0, 0.0, 1.0, 1.0))
    
    # 3. Red color constant (1, 0, 0)
    red_color = unreal.MaterialEditingLibrary.create_material_expression(
        material, 
        unreal.MaterialExpressionConstant3Vector, 
        -400, 
        200
    )
    red_color.set_editor_property('constant', unreal.LinearColor(1.0, 0.0, 0.0, 1.0))
    
    # 4. Lerp node to blend between blue and red
    lerp_node = unreal.MaterialEditingLibrary.create_material_expression(
        material, 
        unreal.MaterialExpressionLinearInterpolate, 
        -200, 
        0
    )
    
    # Connect nodes
    # Blue -> Lerp.A
    unreal.MaterialEditingLibrary.connect_material_expressions(
        blue_color, '', lerp_node, 'A'
    )
    
    # Red -> Lerp.B
    unreal.MaterialEditingLibrary.connect_material_expressions(
        red_color, '', lerp_node, 'B'
    )
    
    # Pressure -> Lerp.Alpha
    unreal.MaterialEditingLibrary.connect_material_expressions(
        pressure_param, '', lerp_node, 'Alpha'
    )
    
    # Connect Lerp output to Base Color
    unreal.MaterialEditingLibrary.connect_material_property(
        lerp_node, '', unreal.MaterialProperty.MP_BASE_COLOR
    )
    
    # Also connect to Emissive Color for glow effect
    unreal.MaterialEditingLibrary.connect_material_property(
        lerp_node, '', unreal.MaterialProperty.MP_EMISSIVE_COLOR
    )
    
    # Recompile and save
    unreal.MaterialEditingLibrary.recompile_material(material)
    unreal.EditorAssetLibrary.save_asset(material.get_path_name())
    
    unreal.log("Created M_Pressure material at /Game/Materials/M_Pressure")
    return material

if __name__ == "__main__":
    create_pressure_material()
