"""
Validate and visualize topology.json structure
Tests:
1. JSON syntax validity
2. Required fields present
3. Component IDs referenced in connections exist
4. Coordinate ranges reasonable
5. 2D layout visualization
"""
import json
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

def load_topology(filepath):
    """Load and validate JSON syntax"""
    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
        print("✓ JSON syntax valid")
        return data
    except json.JSONDecodeError as e:
        print(f"✗ JSON syntax error: {e}")
        return None

def validate_structure(topology):
    """Validate required fields"""
    print("\n=== STRUCTURE VALIDATION ===")
    
    if 'components' not in topology:
        print("✗ Missing 'components' field")
        return False
    
    if 'connections' not in topology:
        print("✗ Missing 'connections' field")
        return False
    
    print(f"✓ Found {len(topology['components'])} components")
    print(f"✓ Found {len(topology['connections'])} connections")
    
    # Validate each component
    required_comp_fields = ['id', 'type', 'name', 'position', 'mesh', 'scale']
    for i, comp in enumerate(topology['components']):
        missing = [f for f in required_comp_fields if f not in comp]
        if missing:
            print(f"✗ Component {i} missing fields: {missing}")
            return False
        
        # Validate position
        if not all(k in comp['position'] for k in ['x', 'y', 'z']):
            print(f"✗ Component {comp['id']} position missing x/y/z")
            return False
    
    print("✓ All components have required fields")
    
    # Validate connections
    component_ids = {c['id'] for c in topology['components']}
    for i, conn in enumerate(topology['connections']):
        if 'from' not in conn or 'to' not in conn:
            print(f"✗ Connection {i} missing from/to")
            return False
        
        from_comp = conn['from']['component']
        to_comp = conn['to']['component']
        
        if from_comp not in component_ids:
            print(f"✗ Connection {conn['id']}: '{from_comp}' not in components")
            return False
        
        if to_comp not in component_ids:
            print(f"✗ Connection {conn['id']}: '{to_comp}' not in components")
            return False
    
    print("✓ All connections reference valid components")
    return True

def analyze_coordinates(topology):
    """Analyze coordinate ranges"""
    print("\n=== COORDINATE ANALYSIS ===")
    
    x_coords = [c['position']['x'] for c in topology['components']]
    y_coords = [c['position']['y'] for c in topology['components']]
    z_coords = [c['position']['z'] for c in topology['components']]
    
    print(f"X range: {min(x_coords)} to {max(x_coords)} cm (span: {max(x_coords) - min(x_coords)})")
    print(f"Y range: {min(y_coords)} to {max(y_coords)} cm (span: {max(y_coords) - min(y_coords)})")
    print(f"Z range: {min(z_coords)} to {max(z_coords)} cm (span: {max(z_coords) - min(z_coords)})")
    
    if max(z_coords) - min(z_coords) > 10:
        print("⚠ Warning: Z span > 10cm - components at different heights")

def visualize_layout(topology):
    """Create 2D top-down visualization"""
    print("\n=== GENERATING VISUALIZATION ===")
    
    fig, ax = plt.subplots(figsize=(12, 10))
    
    # Component colors by type
    type_colors = {
        'pump': 'blue',
        'valve': 'green',
        'actuator': 'red',
        'filter': 'orange',
        'reservoir': 'cyan'
    }
    
    # Draw components
    for comp in topology['components']:
        x = comp['position']['x']
        y = comp['position']['y']
        comp_type = comp['type']
        color = type_colors.get(comp_type, 'gray')
        
        # Draw rectangle for component
        width = comp['scale']['x'] * 50  # Scale up for visibility
        height = comp['scale']['y'] * 50
        rect = mpatches.Rectangle((x - width/2, y - height/2), width, height, 
                                   facecolor=color, edgecolor='black', alpha=0.6)
        ax.add_patch(rect)
        
        # Add label
        ax.text(x, y, comp['id'], ha='center', va='center', fontsize=8, fontweight='bold')
    
    # Draw connections as lines
    for conn in topology['connections']:
        if 'waypoints' in conn:
            waypoints = conn['waypoints']
            x_coords = [wp['x'] for wp in waypoints]
            y_coords = [wp['y'] for wp in waypoints]
            ax.plot(x_coords, y_coords, 'k-', linewidth=1.5, alpha=0.5)
            
            # Add arrow at end
            ax.arrow(x_coords[-2], y_coords[-2], 
                    x_coords[-1] - x_coords[-2], 
                    y_coords[-1] - y_coords[-2],
                    head_width=20, head_length=30, fc='black', alpha=0.3)
    
    # Legend
    legend_elements = [mpatches.Patch(facecolor=color, label=ctype.capitalize()) 
                      for ctype, color in type_colors.items()]
    ax.legend(handles=legend_elements, loc='upper right')
    
    ax.set_xlabel('X (cm)', fontsize=12)
    ax.set_ylabel('Y (cm)', fontsize=12)
    ax.set_title('Hydraulic System Topology - Top View', fontsize=14, fontweight='bold')
    ax.grid(True, alpha=0.3)
    ax.set_aspect('equal')
    
    plt.tight_layout()
    output_path = 'topology_layout.png'
    plt.savefig(output_path, dpi=150)
    print(f"✓ Visualization saved to {output_path}")
    plt.show()

def print_connections(topology):
    """Print connection summary"""
    print("\n=== CONNECTION SUMMARY ===")
    for conn in topology['connections']:
        from_comp = conn['from']['component']
        from_port = conn['from']['port']
        to_comp = conn['to']['component']
        to_port = conn['to']['port']
        print(f"{conn['id']:12} {from_comp:20} [{from_port}] → {to_comp:20} [{to_port}]")

if __name__ == "__main__":
    import sys
    
    # Default path
    filepath = r'C:\0Work\Projects\LLM-MCP\SimscapeFluid\data\processed\topology.json'
    if len(sys.argv) > 1:
        filepath = sys.argv[1]
    
    print("=" * 60)
    print("TOPOLOGY VALIDATION")
    print("=" * 60)
    print(f"File: {filepath}\n")
    
    # Load
    topology = load_topology(filepath)
    if not topology:
        sys.exit(1)
    
    # Validate
    if not validate_structure(topology):
        print("\n✗ VALIDATION FAILED")
        sys.exit(1)
    
    # Analyze
    analyze_coordinates(topology)
    
    # Print connections
    print_connections(topology)
    
    # Visualize
    visualize_layout(topology)
    
    print("\n" + "=" * 60)
    print("✓ ALL TESTS PASSED")
    print("=" * 60)
