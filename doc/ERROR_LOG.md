# Error Log

Track general errors encountered due to LLM knowledge limitations from training data.

**Purpose**: Document API misuse, outdated methods, and knowledge gaps that caused errors across projects. This helps identify patterns where the LLM's training data is incomplete or outdated.

**Scope**: General technical errors applicable to multiple projects (wrong API usage, missing documentation, etc.)

**Not Included**: Project-specific design decisions, topology corrections, or requirements clarifications - these belong in project tracking documents.

## Error Format
- **Date**: YYYY-MM-DD
- **Error Type**: [Error classification]
- **Context**: Where/when it occurred
- **Message**: Full error message
- **Resolution**: How it was fixed
- **Reference**: Documentation links
- **Status**: Resolved / Recurring / Monitoring

## Logged Errors

### 2024-12-30: Wrong Connection Method for Simscape Blocks
- **Date**: 2024-12-30
- **Error Type**: API Misuse
- **Context**: Attempting to connect Simscape Isothermal Liquid blocks programmatically
- **Message**: Used `add_line()` which is for Simulink signal lines, not physical conserving connections
- **Root Cause**: AI attempted to use standard Simulink connection API instead of Simscape-specific API
- **Resolution**: Use `simscape.addConnection(block1, port1, block2, port2, 'autorouting', 'smart')` for Simscape conserving ports
- **Reference**: https://www.mathworks.com/help/simscape/ref/simscape.addconnection.html
- **Status**: ✅ Resolved
- **Prevention**: Always use Simscape API for physical network connections

### 2024-12-30: Unknown Port Names for Simscape Blocks
- **Date**: 2024-12-30
- **Error Type**: Missing Documentation/Discovery
- **Context**: Connecting blocks without knowing actual port names (A, B, P, T, etc.)
- **Message**: Connection failed because port names were assumed incorrectly
- **Root Cause**: Simscape blocks use specific port naming (e.g., DirectionalValve has P/T/A/B/S ports)
- **Resolution**: Use `simscape.connectionPortProperties(blockPath)` to discover actual port names
- **Script Created**: `discover_block_ports.m` - diagnostic tool to query port properties
- **Status**: ✅ Resolved
- **Prevention**: Always discover port names before connecting new block types

## Recurring Issues
[Issues that need investigation or systematic fix]
