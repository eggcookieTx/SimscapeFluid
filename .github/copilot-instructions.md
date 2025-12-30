# Custom Instructions for MATLAB Simscape Fluid + Unreal Project

## Critical Rule: No Code Changes Without Approval

**DO NOT ADD or MODIFY code before asking me to proceed.**

Always:
1. Explain what you plan to do
2. Show the changes you propose
3. Wait for explicit approval before implementing

This applies to:
- Creating new files
- Creating new documentation files
- Modifying existing files
- Adding or removing code blocks
- Changing file structure or organization

**DO NOT generate new documentation files without explicit permission.**

## Unit Testing Requirement

**All new functions, scripts, and features must include unit tests.**

Before marking any code as complete:
1. Write or provide unit tests that validate the functionality
2. Ensure tests cover the main use cases and edge cases
3. Verify tests pass successfully
4. Include test files in the submission for approval

This applies to:
- New MATLAB functions and scripts
- New Python scripts
- New Unreal Engine integration code
- Modifications to existing functionality

## Never Assume - Always Ask

**Do NOT assume:**
- Project structure, folder locations, or naming conventions
- User intent or requirements clarity
- Existing dependencies or library versions
- Performance or security implications
- Compatibility with existing code

**Instead:**
- Ask clarifying questions when requirements are ambiguous
- Validate assumptions against existing code patterns
- Confirm dependencies before using new libraries
- Check version requirements for tools and packages

## Show Your Work First

**For every implementation:**
1. Explain the approach and why it's suitable
2. Show the proposed code/changes
3. List any assumptions you're making
4. Identify potential risks or edge cases
5. Wait for approval before executing

Never jump to implementation without these steps.

## Planning & Task Estimation Rule

**NEVER add time estimates (weeks, days, hours) to task planning documents.**

Only specify tasks and objectives. Actual duration will be tracked as work progresses. Time estimates are unreliable and should not constrain the project.

## Code Quality Standards

**All code must include:**
- Proper error handling and validation
- Clear comments explaining complex logic
- Function documentation with parameters and return values
- Consistent formatting matching existing code style
- No placeholder or non-functional code

**Before submitting:**
- Verify code follows the existing patterns in the project
- Check for edge cases and error conditions
- Ensure backward compatibility
- Consider performance implications

## Documentation is the Source of Truth

**Always reference documentation first:**
- Check `doc/` folder for project progress, decisions, and status
- Review existing README files for context and usage patterns
- Read CHANGELOG.md for recent changes and what's been done
- Check error logs in `doc/` for known issues and solutions

**Before starting any work:**
1. Search relevant documentation files for related work
2. Check if this task is already documented as in-progress or completed
3. Review any errors or blockers documented from previous attempts
4. Understand the current state of the project from docs

**After completing work:**
1. Update relevant documentation with results
2. Document any errors encountered and how they were resolved
3. Note any improvements or lessons learned
4. Update status in project tracking files

**Never assume state without checking docs first** - Documentation is the single source of truth for project status, not assumptions about what might be done.

## Dependency and Environment Management

**All scripts must declare dependencies:**
- MATLAB scripts: List required toolboxes at the top with versions
- Python scripts: Include requirements.txt or environment.yml
- Unreal integration: Document plugin and version requirements

**Before using a new library:**
- Check if it already exists in the project
- Verify compatibility with existing versions
- Document the reason for adding it
- Update dependency tracking files

## Input/Output Validation

**All scripts must validate inputs:**
- Check file existence before reading
- Validate data format and structure
- Confirm parameter ranges and types
- Provide clear error messages, not silent failures

**All exports must be reproducible:**
- Include metadata with every export (timestamp, script, parameters, MATLAB/Python version)
- Use consistent naming: `YYYY-MM-DD_description_vX.ext`
- Never modify original files - always work on copies
- Verify output format matches expected schema

## Working Directory Safety

**Protect original files:**
- Always work on copies in `data/processed/` or temporary directories
- Never directly modify files in `data/raw/` or `model/simscape/`
- Create backups before any batch processing
- Use version control for model changes

## Code Structure Requirements

**Every script must have:**
- Clear header with purpose, author (implied: AI), date modified
- Input parameters documented at the top
- Output description and file locations
- Error handling for common failures
- Comments explaining complex logic sections

**Every MATLAB model must have:**
- System description in model comments
- Documented parameter meanings and ranges
- Clear subsystem organization
- Version tracking in design notes
