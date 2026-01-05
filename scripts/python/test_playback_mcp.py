"""
Test PlaybackManager via Unreal MCP Server
"""
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def test_playback():
    """Connect to Unreal MCP and inspect PlaybackManager"""
    
    # MCP server configuration for Unreal Engine
    server_params = StdioServerParameters(
        command="node",
        args=[r"C:\Users\YourUser\AppData\Roaming\npm\node_modules\@flopperam\unreal-engine-mcp\dist\index.js"],
        env=None
    )
    
    try:
        async with stdio_client(server_params) as (read, write):
            async with ClientSession(read, write) as session:
                print("=" * 60)
                print("UNREAL ENGINE MCP TEST")
                print("=" * 60)
                
                # Initialize
                await session.initialize()
                print("\n✓ Connected to Unreal MCP Server")
                
                # List available tools
                tools_result = await session.list_tools()
                print(f"\n✓ Available tools: {len(tools_result.tools)}")
                for tool in tools_result.tools[:10]:  # Show first 10
                    print(f"  - {tool.name}")
                
                # Get all actors in level
                print("\n" + "=" * 60)
                print("QUERYING LEVEL ACTORS")
                print("=" * 60)
                
                result = await session.call_tool("get_level_actors", {})
                print(f"\n✓ Level actors response:")
                print(result.content[0].text if result.content else "No content")
                
                # Try to get PlaybackManager properties
                print("\n" + "=" * 60)
                print("CHECKING PLAYBACKMANAGER")
                print("=" * 60)
                
                try:
                    pm_result = await session.call_tool("get_actor_properties", {
                        "actor_name": "PlaybackManager"
                    })
                    print(f"\n✓ PlaybackManager properties:")
                    print(pm_result.content[0].text if pm_result.content else "No content")
                except Exception as e:
                    print(f"\n✗ Could not get PlaybackManager properties: {e}")
                
                print("\n" + "=" * 60)
                print("TEST COMPLETE")
                print("=" * 60)
                
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_playback())
