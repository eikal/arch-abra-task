# arch-abra-task

This repository contains my structured solution for the Enterprise Data Architect assessment (Shimon Ltd. case), organized by exam parts and supporting traceability artifacts.

## Output Structure

- `arch-abra-task/0-questions_assumptions.md`: Discovery questions and assumptions.
- `arch-abra-task/1-architecture-design-case.md`: End-to-end architecture alternatives and recommendation.
- `arch-abra-task/2-platform-selection-tradeoffs.md`: Platform choice and trade-off analysis.
- `arch-abra-task/3-data-modeling-semantic-governance.md`: Data model, semantic layer, governance and security design.
- `arch-abra-task/4-operations-finops-production-readiness.md`: Production operations, FinOps, roadmap, and operating model.
- `arch-abra-task/5-sql-practical-thinking.md`: SQL solution, scalability discussion, and validated query results.
- `arch-abra-task/contact_history_sample.csv`: Sample data used for SQL validation.
- `arch-abra-task/task.md`: Original task and evaluation context.
- `mql_attribution_query.sql`: Runnable SQL query for MQL source attribution.
- `requirements-traceability.csv`, `implementation-roadmap.csv`, `technology-decision-log.csv`, `architecture-workspace.md`: Supporting governance and delivery artifacts.

## AI Usage and Validation

AI was used to help structure the deliverables consistently across all parts, draft alternatives, and convert requirements into clear, testable outputs.

Validation was done by running practical checks, including:
- Executing SQL queries on a local SQLite engine.
- Comparing multiple query approaches for equivalent output.
- Verifying rule coverage against the stated requirements.

## Note on Sample Data

For the SQL practical section (Part 5), a sample dataset was generated because the task context referenced sample data but it was not available in the workspace as a ready-to-run file.

The generated file is `contact_history_sample.csv` and is used to test and validate `mql_attribution_query.sql`.
