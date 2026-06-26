**Enterprise Data Architect**

Technical & Consulting Assessment

June 2026

| **Candidate Name**  |                                                     |
| ------------------- | --------------------------------------------------- |
| **Date**            |                                                     |
| **Role**            | Data Architect                                      |
| **Answer Language** | Answers may be written in Hebrew (עברית) or English |

# Exam Instructions

💡 This assessment is not about naming as many technologies as possible. We want to see how you make architecture decisions under real client constraints: business value, cost, scale, security, maintainability and delivery risk.

## General Guidelines

- Submit your answers by email in any tool of your choice: Word, PowerPoint, PDF, or other.
- This document contains the questions only.
- You may use AI tools during the exam - but generic, copy-paste answers will score poorly. We want your own reasoning, assumptions, and trade-offs.
- Unless otherwise stated, you may answer with a general explanation, a diagram, or pseudocode.
- State your assumptions explicitly - a good architect makes assumptions visible.
- Answer concisely and focus on the reasoning behind your choices.
- You may use diagrams, sketches, or verbal explanations.
- Quality of reasoning matters more than length.

⚠️ **There may be multiple valid architecture choices, but each answer is evaluated on clarity of assumptions, trade-off analysis, technical correctness, cost awareness, scalability, security, and practical delivery feasibility. There is no single right answer - but there are weak answers.**

## Submission & Required Deliverables

Expected effort: plan for about one full working day (more if you spread it part-time) - this assessment is intentionally broad. Using AI tools to work efficiently is expected and encouraged; we assess your decisions and how you validate them, not raw output. Recommended answer length: 8-12 pages, excluding diagrams.

Your submission must include:

- Executive summary (1 page).
- An architecture diagram for each of the two alternatives.
- A decision matrix and a clear, justified recommendation.
- A data model / semantic model - a diagram or a clear table-based model.
- A 12-week roadmap (table).
- The SQL query for Part 5.
- An assumptions, risks and open questions section.

💡 We do not expect a full implementation design - focus on the key decisions, the trade-offs, and your architecture reasoning. A large document is not the goal.

💡 Answer depth: deep answers are expected for Parts 1, 2 and 3; a short, structured answer is acceptable for Parts 0, 4 and 5.

⚠️ **If you used AI tools, briefly state how you used them and how you validated the output. We value mature, validated use of AI - not unverified generated text.**

💡 Shortlisted candidates will be asked to defend their architecture in a 60-minute live review - e.g., why this platform, what would make you switch, where the biggest risk is, what you would cut under a budget cut, and how you would explain it to both a CTO and a Data Engineer.

## Exam Structure

| **Part** | **Topic**                                  | **Business Context** | **Weight** | **Status** |
| -------- | ------------------------------------------ | -------------------- | ---------- | ---------- |
| 0        | Discovery & Clarifying Questions           | Shimon Ltd.          | 10         | Mandatory  |
| 1        | Architecture Design Case                   | Shimon Ltd.          | 25         | Mandatory  |
| 2        | Platform Selection & Trade-offs            | Generic              | 20         | Mandatory  |
| 3        | Data Modeling, Semantic Layer & Governance | Shimon Ltd.          | 20         | Mandatory  |
| 4        | Operations, FinOps & Production Readiness  | Shimon Ltd.          | 15         | Mandatory  |
| 5        | SQL / Practical Thinking                   | Independent          | 10         | Mandatory  |

💡 Parts 0-4 share the same business context (Shimon Ltd.), provided at the start of Part 0. Part 5 has its own independent context.

Part 0 - **Client Discovery**

## Business Context - Shimon Ltd

Shimon Ltd. is a non-bank financial services company specializing in credit and financing. It is launching a new enterprise data platform. The following context applies to Parts 0-4.

### Source Systems

| **Source System**                | **Description**                                                                 |
| -------------------------------- | ------------------------------------------------------------------------------- |
| CRM (Dynamics 365)               | Customer and opportunity management.                                            |
| ERP (Business Central)           | Organizational resources: revenues and expenses.                                |
| CosmosDB                         | PDF documents processed by an LLM, converted to structured JSON summaries.      |
| On-prem SQL Server (legacy)      | Core lending ledgers (loans, payments). On-premises, no direct internet access. |
| External SaaS (marketing/events) | Web and event engagement data, exposed via REST API.                            |

### Key Business Requirements

- Hierarchical relationship: Customer → Opportunity → Documents. One customer may have many opportunities; each opportunity may have many documents.
- Serve BI for the business and enable AI agents that can query document content.
- Minimize storage and processing costs.

### Scale, Volumes & Growth

- ~2 million customers; ~40 million opportunities; ~150 million documents.
- ~5 TB historical data, growing ~200 GB per month.
- ~300 BI users in total; ~30 heavy / concurrent analysts.
- Some data must be near-real-time (minutes); the rest is acceptable as daily batch.

### Constraints & Non-Functional Requirements

- Maximum cloud budget: ~\$25,000 / month.
- SLA: business-critical reports must be ready by 08:00 every morning.
- Define a target RPO / RTO and show how your design meets it.
- Security: data includes PII and credit / financial data; a full audit trail is required; financial-regulator compliance applies.
- Separate DEV / TEST / PROD environments with controlled, CI/CD-based promotion.
- Existing tooling: Microsoft 365 + Power BI are in use; some data is already in Azure; one business unit standardized on Qlik.
- A small internal data team will maintain the platform after handover.

💡 Each document is fully schematic except for a small "data" object - an AI-parsed summary intended to be queried by an LLM. The data field is always small and concise.

### 0.1 Discovery & Clarifying Questions

Before designing anything, write 15-20 questions you would ask the client. Group them (e.g., business use-cases, users, data & volumes, sensitivity / regulation, existing tooling, budget, internal team, real-time vs. batch, AI & self-service maturity). For each question, briefly note why the answer would change your architecture.

💡 A strong architect starts with questions and explicit assumptions - not with a diagram.

### 0.2 Assumptions to Validate First

List your top 10 assumptions about this engagement and mark each as: safe assumption / risky assumption / must validate before design. A good architect knows what they do not yet know.

Part 1 - **Architecture Design Case**

Using the Shimon Ltd. context above, design the platform end to end: source → ingestion → storage → transformation → serving → BI / AI.

### 1.1 End-to-End Architecture & Two Alternatives

Design an end-to-end architecture and provide TWO distinct alternatives:

- Alternative A - Microsoft Fabric-first (OneLake + Lakehouse + Power BI).
- Alternative B - ONE specific non-Fabric strategy that you choose (e.g., Fabric vs. Databricks, or vs. Snowflake, or vs. BigQuery, or vs. an AWS stack). Do not describe all platforms generally - pick one and justify why you chose it for the comparison.

Compare the two across cost, scalability, complexity, governance, BI integration, AI-readiness, implementation effort, and risk. State which you recommend for Shimon Ltd. and why - and under which conditions your recommendation would change.

Include one Architecture Decision Record (ADR): the decision, its context, the options considered, the chosen option, the consequences and risks, and the conditions under which you would change or roll back the decision.

### 1.2 Medallion Layers & Incremental Loads

Explain the Medallion Architecture (Bronze / Silver / Gold): the role of each layer, the file / table format you would choose per layer and why, and in which layer the CosmosDB documents live. How would you handle incremental loads / CDC from the source systems?

💡 For each source connection specify: ingestion method, refresh frequency, and the reason for your choice - given the volumes and the 08:00 SLA.

### 1.3 Replication vs. Virtualization

When would you physically copy data into the platform vs. virtualize / reference it in place? Give the trade-offs, and name at least one Shimon source where you would choose each approach.

### 1.4 Hybrid & Secure Ingestion

Some sources are on-prem (SQL Server, no internet), some are SaaS (API), some already in Azure. Design ingestion that is secure, reliable and cost-efficient. Address: gateway / private networking, CDC vs. batch vs. streaming, landing zone, and failure / backfill handling.

### 1.5 Document & Content Storage Strategy

There are ~150 million documents. Clarify what the platform must store and query, and explain the storage, cost, governance and AI implications of each choice:

- Original PDFs.
- Parsed text.
- Structured JSON summaries.
- Embeddings / vector index.
- Document metadata only.

If the AI must "summarize the latest document," does it answer only from the small JSON summary or from the source content? What does that imply for document intelligence, retention / legal evidence, full-text search and RAG design?

### 1.6 Client-Facing Explanation

In 5-7 sentences, explain your recommended architecture to a non-technical CTO / CFO: what you are building, why, what it costs at a high level, and what risk it removes.

### 1.7 What You Would NOT Do

Name three things you would intentionally avoid in this architecture, and explain why.

Part 2 - **Platform Selection & Trade-offs**

These questions broaden the lens beyond Shimon, but answer them with the Shimon Ltd. case in mind wherever it is relevant. We want judgment applied to a real client - not a catalogue of every platform.

### 2.1 Main Recommendation

Take a client like Shimon Ltd. - Power BI already in place, some data in Azure, a small team, a limited budget, and a wish to add AI later. Choose ONE platform (Fabric, Databricks, Snowflake, GCP / BigQuery or AWS) and justify it concretely.

### 2.2 When NOT to Choose It

Give three specific situations in which your chosen platform would be the wrong choice, and what you would pick instead.

### 2.3 Head-to-Head Comparison

Choose ONE alternative platform and compare it head-to-head with your recommendation. Compare only those two - across cost, scale, governance, BI, AI-readiness, team fit and time-to-value. Do not describe all platforms generally.

### 2.4 Real-time vs. Batch

A client asks for "real-time dashboards." How do you verify whether real-time is genuinely required? What are the alternatives, and when is hourly or micro-batch good enough? Discuss the cost and complexity implications.

### 2.5 Architecture Review

You are handed an existing architecture from a client. Identify the top risks and propose improvements across cost, scale, security, governance, and reliability.

💡 In the live interview you may be given a diagram that intentionally contains problems - be ready to critique an existing design, not only to draw your own.

Part 3 - **Data Modeling, Semantic Layer & Governance**

Based on the Shimon Ltd. context above.

### 3.1 Conceptual → Logical → Analytical Model

Provide a conceptual model, then a logical model, then an analytical / dimensional model (star schema) for reporting. Include the entities Customers, Opportunities, Documents and Journal Entries - with relationships, cardinality (1:1, 1:many, many:many), primary keys and foreign keys.

- Explain the difference between the operational (OLTP) ERD and the analytical model used for BI and AI.
- Specify what is stored as a fact, as a dimension, as document metadata, and what enters the semantic layer.
- Apply SCD Type 2 where appropriate (e.g., Customer / Opportunity status) and justify it.
- Describe how you handle duplicates and define a master / golden customer record.
- Define a data contract for each source.

### 3.2 Semantic Layer & AI-Readiness

Focus on the AI-readiness of the data platform, not on agent or prompt design. The business wants an AI assistant that can answer questions such as:

- "What is the total credit exposure of customer X across all their opportunities?"
- "Which opportunities are missing documents?"
- "Summarize the latest document for opportunity Y."

Explain: semantic definitions and trusted / governed metrics; data-quality gates; lineage; permission-aware (grounded) access over structured + unstructured data; and how you validate that answers are grounded in real data and not hallucinated. Why does the structure of the data model directly affect the quality of the AI's answers?

### 3.3 Security, Governance & Compliance

Shimon is a financial entity; data includes PII and credit data. Describe an access and governance model covering:

- RBAC / ABAC, row-level and column-level security, and masking.
- Data classification, data catalog, lineage, and audit logs.
- Encryption, secrets management, private endpoints / VNet, and tenant separation.
- How you prevent unauthorized access in BOTH the BI layer and the AI / semantic layer.
- Dev / Test / Prod separation, CI/CD permissions, and external-sharing controls.

Scenario: a business analyst is allowed to see customer-level credit exposure, but NOT national ID, salary, raw documents, or the credit-scoring logic. Design how this is enforced end to end - across storage, the semantic model, the BI tools, and the AI assistant.

### 3.4 Consistent Metrics Across Power BI & Qlik

One business unit uses Qlik while the enterprise uses Power BI. How would you avoid duplicated business logic and inconsistent KPIs across BI tools? Explain how the same governed metrics will be reused across Power BI, Qlik and AI access (e.g., a shared semantic layer, certified datasets / governed marts, single KPI definitions, and one access model).

Part 4 - **Operations, FinOps & Production Readiness**

💡 A table-based answer is preferred for Part 4 - keep it practical and concise.

### 4.1 Production Readiness

Describe how you run the platform in production: monitoring & alerting, observability, CI/CD, environments, failure handling, and backfill strategy. How do you meet the 08:00 SLA, the RPO and the RTO? What would you document before go-live?

### 4.2 FinOps & Cost Architecture

After two months the client reports cloud cost is 3× higher than expected. How do you investigate, what are the likely causes, and how would you redesign for cost efficiency? Tie your answer to where compute, storage and data-movement costs accumulate, and to how the capacity / scaling model of your chosen platform behaves under this workload.

Provide a high-level monthly cost allocation (not exact pricing) showing where the budget goes: ingestion, storage, compute, BI, AI / search, monitoring, environments, and backup / DR.

### 4.3 Budget Cut

Two months in, the client asks you to cut 40% of cloud cost without hurting the core SLA. What do you do, concretely, and in what order?

💡 We are testing maturity here: name the trade-offs you accept and the ones you refuse.

### 4.4 Delivery Plan & 12-Week Roadmap

Build a 12-week roadmap to stand up the platform. What goes into the MVP, what is deferred to phase 2, who should be on the team, and what are the main risks? Address assumptions, dependencies, acceptance criteria, and a cutover / migration plan.

The client wants value by week 6, not only at week 12. What concretely will you deliver by week 6?

Include your migration approach from the current state to the target architecture - coexistence, validation, and rollback.

### 4.5 Operating Model After Handover

A small internal data team will maintain the platform after handover. Define the operating model: who owns the pipelines, the semantic models, data quality, access approvals, cost monitoring, incidents and change requests?

Part 5 - **SQL / Practical Thinking**

## Business Context

A marketing team wants to understand which activities are most effective at generating MQLs (Marketing Qualified Leads). An MQL is a contact who has engaged enough to be a potential customer but is not yet ready for a direct sales pitch.

All contact events are stored in a table called contact_history. Each row represents one event performed by a contact:

- Digital event registration
- Webinar attendance
- Physical event attendance
- PDF download
- Cost estimator page visit
- Handraise event
- MQL event

## Business Rule

For each MQL event, identify the latest marketing activity that occurred before the MQL event for the same contact. This source activity is used to classify the MQL as sourced by a digital event, physical event, webinar, campaign, etc.

## Table: contact_history

| **Field Name**   | **Description**                                                     |
| ---------------- | ------------------------------------------------------------------- |
| ContactId        | Unique identifier of the contact                                    |
| EventId          | Unique identifier of the contact history event                      |
| EventTimestamp   | Date and time when the event occurred                               |
| EventDescription | Description of the event                                            |
| EventName        | Name of the marketing event or activity                             |
| TriggeredByEvent | Source type: Digital Event, Physical Event, Webinar, Campaign, etc. |
| EventType        | Type / category of the event                                        |

⚠️ **A sample Excel file with data is attached alongside this exam. Use it to understand the data structure and test your query.**

## Task

Write a SQL query that returns one row per MQL event. For each MQL event, return the latest marketing activity that occurred before the MQL for the same contact.

- Return only the latest marketing activity before each MQL event.
- Activities that happened after the MQL must not be matched.
- If a contact has multiple MQL events, each must be handled separately.
- Do not use a manual / Excel-based solution.

⚠️ **Rules of the game: "marketing activity" means any non-MQL event unless stated otherwise. If multiple prior activities share the same timestamp, use EventId as a deterministic tie-breaker. If no prior activity exists, return the MQL with NULL source fields. Use ANSI SQL where possible, or clearly state your SQL dialect (T-SQL, Spark SQL, etc.).**

### 5.1 Scale & Optimization

Now assume contact_history holds 500M rows.

- How would this query behave at that scale, and how would you model the table so it runs well?
- Which indexes / partitioning / clustering / Z-order / materialized views would you consider - and how does your answer differ across Fabric, Snowflake, Databricks, BigQuery and an AWS stack (e.g., Redshift)?
- How would you explain why a query is expensive, and how would you design an incremental model instead of a full recompute?

💡 Hint: consider window functions or a self-join to compare events within the same contact.

# Scoring

Your submission is scored by part:

| **Part** | **Topic**                                  | **Weight** |
| -------- | ------------------------------------------ | ---------- |
| 0        | Client Discovery                           | 10         |
| 1        | Architecture Design Case                   | 25         |
| 2        | Platform Selection & Trade-offs            | 20         |
| 3        | Data Modeling, Semantic Layer & Governance | 20         |
| 4        | Operations, FinOps & Production Readiness  | 15         |
| 5        | SQL / Practical Thinking                   | 10         |
|          | Total                                      | 100        |

# What We Look For

### Green Flags

- Starts with discovery questions and states assumptions.
- Offers 2-3 alternatives rather than a single solution; comfortable saying "it depends."
- Links business SLA to technical design, and talks about cost early.
- Treats security & governance as first-class from the start.
- Can scope an MVP and understands the BI & semantic layer.
- Knows why not to push everything into Gold, and chooses between Fabric / Databricks / Snowflake by situation.
- Can speak to both a CTO and a Data Engineer.

### Red Flags

- Picks a platform without asking about budget or scale.
- Says "Fabric fits everything" or "Databricks is always best."
- Ignores security; doesn't separate storage from compute.
- Can't distinguish batch from streaming; ignores Dev / Test / Prod.
- Can't explain incremental load; puts all logic in the BI layer.
- Can't discuss data quality or defend a decision to a client.
- Gives a polished answer with no trade-offs; ignores cost.

**Good Luck! 🚀**

We are looking for clear reasoning, explicit trade-offs, and depth of understanding.