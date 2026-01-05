"""
Simple test to verify Unreal Python console works
"""
import unreal

unreal.log("Python is working in Unreal Editor!")
unreal.log("Creating M_Pressure material...")

# Try creating the material
try:
    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    material_factory = unreal.MaterialFactoryNew()
    
    material = asset_tools.create_asset(
        "M_Pressure", 
        "/Game/Materials", 
        unreal.Material, 
        material_factory
    )
    
    if material:
        unreal.log("SUCCESS: Material created at /Game/Materials/M_Pressure")
        unreal.log("Now adding material nodes...")
        
        # Add scalar parameter
        pressure_param = unreal.MaterialEditingLibrary.create_material_expression(
            material, unreal.MaterialExpressionScalarParameter, -400, 0
        )
        pressure_param.set_editor_property('parameter_name', 'Pressure')
        pressure_param.set_editor_property('default_value', 0.5)
        
        # Blue color
        blue = unreal.MaterialEditingLibrary.create_material_expression(
            material, unreal.MaterialExpressionConstant3Vector, -400, -200
        )
        blue.set_editor_property('constant', unreal.LinearColor(0.0, 0.0, 1.0, 1.0))
        
        # Red color
        red = unreal.MaterialEditingLibrary.create_material_expression(
            material, unreal.MaterialExpressionConstant3Vector, -400, 200
        )
        red.set_editor_property('constant', unreal.LinearColor(1.0, 0.0, 0.0, 1.0))
        
        # Lerp
        lerp = unreal.MaterialEditingLibrary.create_material_expression(
            material, unreal.MaterialExpressionLinearInterpolate, -200, 0
        )
        
        # Connect everything
        unreal.MaterialEditingLibrary.connect_material_expressions(blue, '', lerp, 'A')
        unreal.MaterialEditingLibrary.connect_material_expressions(red, '', lerp, 'B')
        unreal.MaterialEditingLibrary.connect_material_expressions(pressure_param, '', lerp, 'Alpha')
        unreal.MaterialEditingLibrary.connect_material_property(lerp, '', unreal.MaterialProperty.MP_BASE_COLOR)
        unreal.MaterialEditingLibrary.connect_material_property(lerp, '', unreal.MaterialProperty.MP_EMISSIVE_COLOR)
        
        # Save
        unreal.MaterialEditingLibrary.recompile_material(material)
        unreal.EditorAssetLibrary.save_asset(material.get_path_name())
        
        unreal.log("SUCCESS: Material fully configured and saved!")
    else:
        unreal.log_error("FAILED: Could not create material asset")
        
except Exception as e:
    unreal.log_error(f"EXCEPTION: {str(e)}")
    import traceback
    unreal.log_error(traceback.format_exc())
