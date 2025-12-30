# Project Structure

## Directory Layout

```
SimscapeFluid/
├── data/
│   ├── raw/                   # Original, unmodified data
│   └── processed/             # Processed outputs and results
├── doc/                       # Project documentation
├── scripts/
│   ├── matlab/                # MATLAB scripts (.m files)
│   ├── python/                # Python scripts (.py files)
│   └── unreal/                # Unreal Engine integration scripts
├── models/
│   ├── simscape/              # Simscape Fluid models
│   └── unreal/                # Unreal Engine models and configs
└── .github/                   # GitHub configuration (copilot-instructions.md)
```

## Directory Descriptions

### `/data`
- **raw/** – Original, unmodified input data (never modify these files)
- **processed/** – Processed outputs and analysis results

### `/doc`
Documentation divided into LLM-readable and human-readable formats:
- **PROJECT_STRUCTURE.md** – This file; directory organization and file structure
- **project_overview.md** – High-level description of the project goals and scope
- **project_tracking_llm.md** – Detailed, verbose project status for LLM context (can be very long)
- **project_tracking_human.md** – Concise summary for human review (quick reference)
- **bug_reports.md** – Issue tracking and bug descriptions
- **improvements.md** – Feature requests, enhancements, and optimization ideas
- **CHANGELOG.md** – Version history and major completed milestones
- **ERROR_LOG.md** – Errors encountered and their resolutions
- **DEPENDENCIES.md** – Required toolboxes, libraries, and version information

### `/scripts`
- **matlab/** – MATLAB scripts (.m files) with unit tests
- **python/** – Python scripts (.py files) with unit tests
- **unreal/** – Unreal Engine integration scripts with tests

### `/models`
- **simscape/** – Simscape Fluid models and configurations
- **unreal/** – Unreal Engine model files and integration code

## Documentation Standards

- **LLM-readable docs** (project_tracking_llm.md): Detailed, can be lengthy, includes context for AI reasoning
- **Human-readable docs** (project_tracking_human.md): Concise, action-focused, quick reference format

## Key Files

- `.github/copilot-instructions.md` – Custom Copilot instructions for this project

## Notes

- All work follows the rules in `.github/copilot-instructions.md`
- Original data files in `data/raw/` should never be modified
- Always use copies in `data/processed/` or temporary directories
- Every script must include unit tests
- Code changes require approval before implementation
