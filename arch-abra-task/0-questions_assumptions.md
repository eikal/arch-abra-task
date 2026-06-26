## 0) Client Discovery

### 0.1 Discovery & Clarifying Questions

#### Group A — Business Use-Cases

| # | Question | Why the answer changes the architecture |
|---|---|---|
| A1 | Which business decisions depend on this platform most urgently — credit risk, portfolio management, collections, or marketing attribution? | Defines which Gold marts to build first and which KPIs are SLA-critical vs. deferred. |
| A2 | Do any business processes require event-driven triggers from the data platform (e.g., auto-flag a customer for review when a document arrives)? | Distinguishes passive BI from active operational use cases; the latter requires streaming or event-pub patterns and materially increases complexity and cost. |
| A3 | Are there external stakeholders (regulators, auditors, or partners) who need to consume data or reports directly from the platform? | Drives external-sharing controls, data residency, and whether a portal or API layer is needed beyond internal BI. |

#### Group B — Users

| # | Question | Why the answer changes the architecture |
|---|---|---|
| B1 | What are the top 5 queries the 30 heavy analysts run today, and what are their typical result set sizes and join complexity? | Determines star-schema grain, aggregation pre-compute strategy, and whether Power BI Import vs. DirectQuery is viable under the budget. |
| B2 | Do the 300 BI users self-serve or consume pre-built dashboards only? | A self-service model requires a semantic layer with governed certified datasets; a dashboard-only model can use simpler curated marts without exposing raw tables. |
| B3 | Which teams use Qlik and is there a roadmap to consolidate to a single BI tool? | If Qlik is temporary, a lighter compatibility shim suffices. If strategic, the semantic layer must expose stable XMLA/SQL endpoints with full parity and long-term maintenance costs rise. |

#### Group C — Data & Volumes

| # | Question | Why the answer changes the architecture |
|---|---|---|
| C1 | Of the 150 million documents, what is the split between active (queried regularly) and archived (queried rarely or only for legal hold)? | Determines whether a hot/warm/cold storage tiering strategy is needed, which directly drives monthly storage cost. |
| C2 | Is the 200 GB/month growth rate uniform across all source systems, or is it driven primarily by document volume? | If growth is document-heavy, archival lifecycle policy is the main cost lever. If it is transactional, partition strategy on fact tables becomes the priority. |
| C3 | What is the current state of data quality in each source system — are there known duplicates, nulls in key fields, or schema drift in CosmosDB? | Poor source quality requires heavier Silver-layer validation and deduplication logic, which increases engineering complexity and can jeopardize the 08:00 SLA. |

#### Group D — Sensitivity & Regulation

| # | Question | Why the answer changes the architecture |
|---|---|---|
| D1 | Which specific regulatory frameworks apply — Israeli financial regulator, GDPR, SOX, or others? And what is the required audit log retention period? | Each framework has different controls: GDPR requires erasure-by-design; SOX requires immutable change logs; Israeli regulation may impose local data residency. The wrong assumption blocks compliance sign-off. |
| D2 | Which fields are classified as PII and which as financial-sensitive (e.g., national ID, salary, credit score, loan amount)? Who decides field-level classification? | Drives the column-level security and masking policy. Without a field inventory, any access control design is provisional and may be incomplete at audit time. |
| D3 | Must the AI assistant's answers be traceable to source records for regulatory or legal purposes? | If yes, every AI answer must carry a provenance reference, which changes the retrieval architecture (RAG with citations vs. semantic search without evidence). |

#### Group E — Existing Tooling

| # | Question | Why the answer changes the architecture |
|---|---|---|
| E1 | Is any data already in Azure today (Blob, Synapse, Azure SQL)? If so, can it be migrated in place or must it be reloaded from source? | Existing Azure assets can reduce initial backfill cost and timeline. Reloading from source carries reconciliation risk and affects week-1 planning. |
| E2 | What CI/CD and source control tooling is currently in use (Azure DevOps, GitHub, Jenkins)? | Determines the deployment pipeline framework and whether environment promotion gates can be implemented natively or require custom wiring. |

#### Group F — Budget

| # | Question | Why the answer changes the architecture |
|---|---|---|
| F1 | Is the $25,000/month cap inclusive of Power BI Premium licensing and any existing Azure commitments, or is it net-new compute and storage only? | Power BI Premium P1 alone is ~$4,800/month. If already licensed, the effective compute budget is larger. If not, the platform compute budget shrinks materially and may force a lower SKU. |
| F2 | Is there a one-time migration budget separate from the recurring monthly cap? | Initial backfill of 5 TB and environment setup can temporarily spike cost 2–3× above steady state. Without a migration budget, week-1 activities must be throttled and the roadmap extends. |

#### Group G — Internal Team

| # | Question | Why the answer changes the architecture |
|---|---|---|
| G1 | How many FTEs will operate the platform after handover, and what are their skill levels — data engineering, BI development, or primarily analytics? | A team with strong DE skills can manage Databricks-style infra. A BI-leaning team needs Fabric's managed services and low-code options. Getting this wrong creates a platform the team cannot maintain. |
| G2 | Will there be an external support contract or 24/7 on-call coverage available? | Without on-call cover, RTO targets must be conservative (hours, not minutes) and the platform must favour self-healing automation over manual intervention. |

#### Group H — Real-Time vs. Batch

| # | Question | Why the answer changes the architecture |
|---|---|---|
| H1 | For the data sources that require near-real-time (minutes), what is the acceptable maximum lag — 5 minutes, 15 minutes, or 30 minutes? And which specific use cases drive this requirement? | Even small differences in target latency force very different technology choices: <5 min needs streaming (Eventstream/Kafka); 15–30 min can be served by micro-batch at a fraction of the cost. |

#### Group I — AI & Self-Service Maturity

| # | Question | Why the answer changes the architecture |
|---|---|---|
| I1 | When the AI assistant summarizes the latest document, does the answer need to cite the original source text, or is a narrative generated from the JSON summary acceptable? | If citation from source text is required, the platform must store and index parsed document content or embeddings. If JSON summary is sufficient, storage, retrieval complexity, and cost are significantly lower. |
| I2 | Who owns the AI agent roadmap — the data team, a separate AI/ML team, or a vendor? And is there an existing Azure OpenAI or other LLM contract? | Platform design (RAG depth, embedding pipelines, private endpoint for LLM) differs completely depending on whether AI is built in-house vs. consumed via a managed service, and whether a contract already exists. |

---

### 0.2 Assumptions to Validate First

| # | Assumption | Classification | Why it matters / What changes if wrong |
|---|---|---|---|
| 1 | Microsoft Fabric is an acceptable enterprise platform choice — there are no board-level or procurement blockers against Microsoft cloud concentration. | **Safe assumption** | Existing M365 and Power BI use confirms Microsoft is an approved vendor. If wrong, the entire recommendation shifts to a cloud-neutral stack (Databricks + ADLS), adding delivery risk and timeline. |
| 2 | The JSON summary in CosmosDB is sufficient for AI-assisted document Q&A in MVP — no full-text indexing or embedding pipeline is needed on day one. | **Risky assumption** | Depends on undeclared legal and quality requirements. If legal evidence or answer quality demands require source-text citations, the document storage architecture must expand to include parsed text or vector embeddings, materially increasing cost and complexity. |
| 3 | Near-real-time (minutes) applies to a small subset of sources or use cases, and micro-batch (15–30 min) satisfies those requirements without always-on streaming infrastructure. | **Must validate before design** | The brief says "some data must be near-real-time" with no source-level detail. If true streaming (<5 min) is required for a core use case, Fabric Eventstream or Azure Event Hubs is needed, doubling ingestion complexity and cost. |
| 4 | The $25,000/month budget covers all recurring cloud costs — compute, storage, networking, BI licensing, and monitoring — with no separate EA or Reserved Instance credits. | **Must validate before design** | If existing reserved capacity or credits reduce the effective bill, there is room for higher-performance SKUs. If not, every component must be costed conservatively from day one. |
| 5 | The on-premises SQL Server can be reached via an existing VPN or hybrid connection that supports a self-hosted integration runtime, with polling allowed every 4–6 hours. | **Risky assumption** | No hybrid connectivity is confirmed in the brief. If no path exists, a new ExpressRoute must be provisioned, potentially blocking on-prem ingestion for weeks and threatening the 08:00 SLA. |
| 6 | Regulatory compliance baseline is the Israeli financial regulator plus GDPR-equivalent privacy controls with a 7-year audit retention — no SOX-specific immutable ledger or US-regulatory obligation applies. | **Must validate before design** | SOX adds immutable change-data requirements that significantly affect Bronze layer design and audit log cost. GDPR adds right-to-erasure obligations that conflict with SCD Type 2 history and require a pseudonymisation strategy. |
| 7 | CRM (Dynamics 365) is the master source of truth for customer identity, and ERP and legacy SQL contain subsets of the same customer base — not independently mastered records. | **Safe assumption** | CRM as customer master is the standard pattern for financial services firms on this stack. If wrong, a full MDM exercise is required before any reporting is trustworthy, adding 3–4 weeks to the Silver-layer design. |
| 8 | The 2–3 FTEs who will operate the platform post-handover have BI and data engineering backgrounds, not ML or platform-engineering backgrounds, so managed services and low-code operations are necessary. | **Risky assumption** | Team composition is unstated. If the team has strong engineering capability, a more flexible platform (Databricks) becomes viable. If BI-leaning, even Fabric must be simplified with visual pipelines preferred over custom notebooks. |
| 9 | Qlik will remain in use for the foreseeable future (2+ years) in at least one business unit and the semantic layer must expose stable SQL or XMLA endpoints for Qlik consumption alongside Power BI. | **Risky assumption** | If Qlik is being retired within 6–12 months, the investment in cross-tool semantic compatibility can be deferred, simplifying governance and reducing phase-2 scope. |
| 10 | The 5 TB historical backfill can be performed as a one-time bulk load in weeks 1–2 without a streaming catch-up, and source systems can tolerate a bulk read window without impacting production operations. | **Must validate before design** | Bulk reads from a legacy on-prem SQL Server under production load are a common failure point. If source systems cannot sustain a bulk export, backfill must be throttled or scheduled out-of-hours, potentially extending the foundation phase from 2 to 4 weeks and delaying the week-6 value milestone. |