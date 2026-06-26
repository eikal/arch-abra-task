# Shimon Ltd. Enterprise Data Platform Architecture Workspace

Date: 2026-06-21
Role Lens: Enterprise Architect, Data Architect, Cloud Architect, Data Governance Lead

## 1) Executive Summary
Shimon Ltd. needs a secure, cost-controlled enterprise data platform that supports both governed BI and AI-assisted document analytics across CRM, ERP, legacy on-prem SQL, CosmosDB summaries, and external SaaS activity data. The recommended target is a Fabric-first architecture because it aligns with current Microsoft 365 and Power BI adoption, reduces operational burden for a small internal team, and provides integrated governance and semantic capabilities with lower delivery risk.

The design implements medallion data layers, source-specific ingestion (batch, CDC, micro-batch), and a shared governed semantic layer for consistent KPIs across Power BI, Qlik, and AI access paths. Security is enforced end-to-end through role and attribute-based access, row and column controls, masking, private networking, full audit trails, and environment segregation with CI/CD promotion gates.

To meet business outcomes under the $25K/month budget cap and 08:00 critical reporting SLA, the roadmap prioritizes week-6 MVP value, then expands AI/search depth and advanced resilience in phase 2. Assumptions and ambiguities are explicitly tracked to avoid architecture drift.

## 2) Business Requirements

| Requirement ID | Requirement | Business driver | Architectural impact | Security impact | Operational impact | Suggested solution patterns |
|---|---|---|---|---|---|---|
| BR-001 | Unified view of Customer -> Opportunity -> Document hierarchy | End-to-end credit lifecycle visibility | Canonical model and conformed dimensions | Consistent identity/access boundaries | Cross-domain lineage and ownership | Canonical data model + conformed keys |
| BR-002 | BI availability for 300 users, 30 heavy concurrent analysts | Daily decisions and performance tracking | Curated Gold marts, workload isolation | Least privilege for analytics roles | Capacity management and query governance | Star schemas + certified semantic model |
| BR-003 | AI assistant can answer governed business/document questions | Faster insight and productivity | Structured + unstructured retrieval strategy | Permission-aware AI grounding | AI query telemetry and guardrails | Governed semantic layer + RAG-lite |
| BR-004 | Minimize storage and processing cost | Budget discipline | Tiered storage and incremental processing | Cost controls on sensitive workloads | FinOps monitoring and rightsizing | Incremental CDC, partitioning, autoscale windows |
| BR-005 | Keep existing Power BI use while supporting Qlik business unit | Avoid tool disruption | Shared metric contract across tools | Single access policy model | Cross-tool certification process | Semantic contract + reusable SQL endpoints |
| BR-006 | Small internal team can run after handover | Sustainability | Managed services over custom platform glue | Reduced human error via policy automation | Runbooks, observability, simplified ops | Fabric-first managed stack + IaC + CI/CD |

## 3) Functional Requirements

| Requirement ID | Requirement | Business driver | Architectural impact | Security impact | Operational impact | Suggested solution patterns |
|---|---|---|---|---|---|---|
| FR-001 | Ingest Dynamics 365 CRM data | Customer and opportunity management | Connector + incremental loads | API auth and token handling | Retry and watermark control | Incremental pulls + landing zone |
| FR-002 | Ingest Business Central ERP data | Financial journals and accounting | Entity-level ingestion and harmonization | Finance data access boundaries | Batch windows and reconciliation | CDC where available, otherwise delta batch |
| FR-003 | Ingest CosmosDB JSON summaries | Document AI content access | Semi-structured ingestion and schema evolution | Summary-level access controls | Schema drift handling | JSON bronze + typed silver projection |
| FR-004 | Ingest on-prem SQL Server (no direct internet) | Legacy lending ledger continuity | Hybrid connectivity and secure replication | Private network + secrets + endpoint controls | Agent reliability and backfill | Self-hosted gateway + CDC/export |
| FR-005 | Ingest external SaaS marketing/events API | Marketing attribution and engagement | API ingestion and rate-limit handling | API key/secret governance | Retry, idempotency, dead-letter handling | Micro-batch API ingestion pattern |
| FR-006 | Critical reports ready by 08:00 daily | Business SLA | Dependency-aware orchestration | Controlled access during refresh | SLA monitoring and alerting | Time-boxed orchestration with checkpoints |
| FR-007 | Support near-real-time for selected datasets | Faster operational insight | Dual-latency pipeline design | Tighten controls on frequent refresh | Increased monitoring complexity | Micro-batch pipeline profile |
| FR-008 | AI answer: total exposure per customer | Portfolio visibility | Unified fact across opportunities | Role-based aggregation visibility | KPI validation and lineage checks | Governed metric definition |
| FR-009 | AI answer: identify missing documents | Compliance and process control | Document completeness rules | Restricted visibility of raw docs | Data-quality SLA and exception queue | Rule-based quality checks |
| FR-010 | AI answer: summarize latest document | Operational productivity | Latest-doc retrieval and provenance | Enforce source-level document entitlements | Retrieval latency and cache policy | Summary table with deterministic latest logic |

## 4) Non-Functional Requirements

| Requirement ID | Requirement | Business driver | Architectural impact | Security impact | Operational impact | Suggested solution patterns |
|---|---|---|---|---|---|---|
| NFR-001 | Budget <= $25,000/month | Cost control | Architecture choices must be cost-bounded | Cost anomalies can expose data paths | Monthly budget gates and alerts | FinOps tagging + budgets + chargeback view |
| NFR-002 | 08:00 report SLA | Business continuity | Early-morning compute burst planning | Controlled release and access windows | On-time batch completion and incident runbooks | SLA-bound orchestration and precomputed marts |
| NFR-003 | RPO/RTO targets by criticality | Resilience | Backup/DR tiering by data domain | Encrypted backup and key strategy | DR drills and restore procedures | Tiered DR design |
| NFR-004 | Full audit trail | Regulatory compliance | End-to-end logging architecture | Immutable, tamper-evident records | Long-term retention and searchable audits | Centralized audit and lineage logs |
| NFR-005 | DEV/TEST/PROD separation with CI/CD promotion | Release quality | Environment-specific config and pipelines | Policy-as-code and secret isolation | Promotion approvals and rollback | Multi-stage deployment pipelines |
| NFR-006 | Handle growth 200 GB/month from 5 TB baseline | Scalability | Partitioning and lifecycle management | Security labeling at scale | Storage lifecycle and compaction | Partition + lifecycle tiering |
| NFR-007 | Maintainability by small team | Operability | Managed services preferred | Reduce privileged manual operations | Runbooks and SRE-lite process | Managed orchestration + IaC |

## 5) Current State Assessment

### 5.1 Landscape Summary
- CRM (Dynamics 365): customer/opportunity lifecycle source.
- ERP (Business Central): journals, revenues, expenses.
- CosmosDB: LLM-derived JSON summaries from document processing.
- On-prem SQL Server: core lending ledgers, no direct internet.
- External SaaS API: marketing/event engagement data.
- BI tooling split: enterprise uses Power BI, one BU standardized on Qlik.

### 5.2 Current-State Strengths
- Existing Microsoft footprint reduces adoption friction.
- Clear business hierarchy and known data domains.
- Document summaries already exist in structured JSON.

### 5.3 Current-State Gaps
- No unified semantic layer across Power BI/Qlik/AI.
- Ambiguous real-time boundaries and DR targets.
- Incomplete governance details for PII class-specific controls.
- On-prem to cloud ingestion reliability/latency boundaries unresolved.

## 6) Target State Architecture

### 6.1 Recommended Architecture (Fabric-first)
- Ingestion: Fabric Data Factory pipelines and gateway/hybrid path for on-prem SQL.
- Storage: OneLake medallion zones (Bronze/Silver/Gold).
- Processing: notebook/dataflow SQL transforms with incremental design.
- Serving: curated Gold marts + shared governed semantic model.
- Consumption: Power BI primary, Qlik via governed SQL/semantic endpoints, AI assistant via permission-aware semantic access.
- Governance: catalog, lineage, classification, audit, policy controls.
- Security: RBAC/ABAC, RLS/CLS, masking, secret vault, private endpoints.

### 6.2 Alternative Architecture (Databricks on Azure)
- Similar medallion model in ADLS/Delta with Databricks compute and Unity Catalog.
- Strong engineering flexibility and AI expansion path.
- Higher operational complexity and skill demand for a small team.

### 6.3 Recommendation
Choose Fabric-first for initial implementation based on existing ecosystem fit, faster delivery, lower run complexity, and integrated Power BI semantics. Re-evaluate if advanced ML/streaming requirements become dominant or if cross-cloud neutrality becomes a hard requirement.

## 7) Data Architecture

### 7.1 Medallion Model
- Bronze: raw source landing with immutable ingestion metadata.
- Silver: conformed, quality-checked, deduplicated entities.
- Gold: business-ready marts and certified KPI tables.

### 7.2 Core Model Entities
- Customer (master/golden record with survivorship rules).
- Opportunity (many per customer; status history via SCD2 where needed).
- Document (many per opportunity; metadata and summary references).
- Journal Entry (financial facts tied to customer/opportunity where applicable).

### 7.3 Data Contracts (per source)
Each source contract includes schema version, freshness SLA, quality rules, owner, PII tags, and breaking-change protocol.

### 7.4 Duplicate Handling and Golden Record
- Deterministic and fuzzy matching on legal/business identifiers.
- Survivorship precedence: CRM identity fields > ERP financial attributes > legacy enrichment.
- Persist match confidence and lineage to support auditability.

### 7.5 Document Strategy (MVP and Expansion)
- MVP: store metadata + JSON summaries for primary AI workflows.
- Keep original PDFs in governed archival storage for legal evidence and reprocessing.
- Parsed full text and embeddings deferred unless answer quality or legal discovery requires it.

## 8) Integration Architecture

| Source | Ingestion method | Frequency | Rationale |
|---|---|---|---|
| Dynamics 365 | API incremental pull | Hourly or 4-hour micro-batch | Balance freshness with API and cost |
| Business Central | Delta batch/CDC | 4-hour + nightly reconcile | Financial integrity with predictable windows |
| CosmosDB summaries | Incremental extract | Hourly | Supports AI/doc insights without full streaming |
| On-prem SQL Server | Gateway + CDC or staged export | 4-hour + nightly checkpoint | Works with no direct internet constraint |
| External SaaS API | Incremental API micro-batch | Hourly | Marketing attribution timeliness |

Failure/backfill pattern: idempotent loads, watermark-based retries, dead-letter queues for bad records, and replay jobs scoped by source/time partition.

## 9) Security Architecture

### 9.1 Security Controls
- Identity and access: Entra ID RBAC + ABAC overlays.
- Data access enforcement: row-level and column-level security.
- Sensitive data masking: national ID, salary, scoring internals.
- Encryption: at-rest and in-transit for all tiers.
- Secrets: centralized vault and managed identity usage.
- Network: private endpoints, segmented VNets, restricted egress.

### 9.2 End-to-End Restricted Analyst Scenario
Analyst role can view customer exposure aggregates but cannot access national ID, salary, raw documents, or scoring logic. Controls are applied at storage policy, semantic model, BI dataset, and AI query broker levels with consistent identity propagation.

### 9.3 Audit and Compliance
- Full audit trail across ingestion, transformation, access, and policy changes.
- Immutable retention aligned to financial regulator and GDPR-like controls.
- Access approval workflow and periodic recertification.

## 10) Governance Architecture

### 10.1 Governance Operating Controls
- Data classification taxonomy (Public/Internal/Confidential/Restricted).
- Data catalog with ownership, glossary, and technical lineage.
- Policy-as-code for data access, masking, and environment promotion.
- Certified semantic metrics with stewardship and change control.

### 10.2 Cross-Tool Metric Governance (Power BI + Qlik + AI)
- Single metric definitions authored in governed semantic layer.
- Reusable metric contract consumed by Power BI, Qlik endpoints, and AI tools.
- KPI certification board (Data Owner + BI Lead + Governance Lead).

### 10.3 Data Quality Governance
- Rule tiers: critical (block), warning (quarantine), informational (monitor).
- Contract tests at ingestion and pre-Gold publication.
- Quality scorecards published weekly.

## 11) Operational Model

### 11.1 Ownership Model (RACI summary)
- Platform/Data Engineering: ingestion pipelines, transformations, infra IaC.
- BI Team: semantic model, certified metrics, dashboard release.
- Governance/Security: access approvals, classification, compliance evidence.
- Operations/SRE-lite: monitoring, incidents, SLA, backfill execution.

### 11.2 Production Readiness
- Monitoring: pipeline latency, freshness lag, quality failures, capacity saturation.
- Alerting: SLA breach risk, security anomalies, cost spikes.
- CI/CD: branch-based deployments with environment approvals.
- Backfill: source-partition replay with deterministic idempotent jobs.

### 11.3 DR Targets (custom tiered assumption)
- Critical curated reporting: RPO 4h, RTO 2h.
- Non-critical historical analytics: RPO 24h, RTO 8h.

## 12) Risks and Assumptions

### 12.1 Key Assumptions
- Fabric-first is organizationally acceptable for enterprise standardization.
- JSON summaries are sufficient for AI MVP grounding for most questions.
- Near-real-time can be met with micro-batch for MVP without always-on streaming.
- Compliance baseline: financial regulator controls + GDPR-like controls + 7-year audit retention.

### 12.2 Top Risks
- Ambiguous real-time boundaries could force costly redesign.
- Undefined legal/eDiscovery requirements may require full-text storage/indexing earlier.
- On-prem connectivity reliability may impact morning SLA.
- Dual BI tool governance can drift without strict semantic contract ownership.

### 12.3 Risk Mitigations
- Decision gates in week 2 and week 5 for latency and AI retrieval scope.
- Legal/compliance validation before finalizing document retention/search strategy.
- Early performance rehearsal for 08:00 SLA.
- KPI certification and change board for cross-tool consistency.

## 13) Technology Decision Log

| Decision ID | Decision | Options considered | Selected option | Why selected | Risks | Switch condition |
|---|---|---|---|---|---|---|
| TDL-001 | Core platform | Fabric, Databricks, Snowflake | Fabric-first | Team fit, Power BI integration, faster delivery | Vendor concentration | Move if advanced ML/streaming dominates |
| TDL-002 | Document AI MVP scope | JSON only, JSON+text, full RAG | JSON summaries + archival PDFs | Lowest cost/risk while preserving legal evidence | Possible answer-quality limits | Add parsed text/embeddings if KPI fails |
| TDL-003 | Ingestion latency pattern | Streaming, micro-batch, daily batch | Mixed micro-batch + daily batch | Meets SLA with lower complexity | Some latency-sensitive cases delayed | Enable streaming for approved domains |
| TDL-004 | Metric consistency across BI tools | Per-tool logic, central semantic contract | Central semantic contract | Eliminates KPI drift | Governance overhead | Simplify if single-BI consolidation occurs |
| TDL-005 | DR posture | Uniform strict DR, tiered DR | Tiered DR by criticality | Aligns resilience to value/cost | Misclassification risk | Tighten DR if risk appetite changes |

### ADR-001 (Condensed)
- Context: Need low-risk enterprise delivery under budget with small team.
- Decision: Fabric-first architecture as target state baseline.
- Consequences: Faster time-to-value and integrated governance, with less custom engineering flexibility than Databricks-first.
- Rollback/Change trigger: switch if required streaming/ML complexity and cross-platform interoperability exceed Fabric-first constraints.

## 14) Implementation Roadmap (12 Weeks)

| Week | Workstream | Deliverable | Acceptance criteria |
|---|---|---|---|
| 1 | Discovery and controls | Finalized assumptions, risk register, source contracts v1 | Stakeholder sign-off on scope/assumptions |
| 2 | Foundation | DEV/TEST/PROD baseline, IAM roles, networking, CI/CD skeleton | Security and deployment controls validated |
| 3 | Ingestion sprint 1 | CRM + ERP pipelines to Bronze | Incremental loads complete with lineage |
| 4 | Ingestion sprint 2 | CosmosDB + SaaS + on-prem path enabled | End-to-end load with retry/backfill tested |
| 5 | Data quality and conformance | Silver conformance, DQ rules, dedup/golden customer v1 | DQ score above agreed threshold |
| 6 | MVP value milestone | Gold marts (exposure + missing docs) + first dashboards | Business users consume MVP by agreed KPIs |
| 7 | Semantic governance | Certified KPI model, Power BI semantic contract v1 | Cross-team KPI definitions approved |
| 8 | Qlik and AI access enablement | Governed endpoints for Qlik and AI query path | Access controls verified end-to-end |
| 9 | Security hardening | Masking, RLS/CLS, audit evidence pack v1 | Compliance and penetration checks passed |
| 10 | Performance and SLA rehearsal | 08:00 readiness simulation + optimization | SLA met in rehearsal for 5 consecutive runs |
| 11 | DR and operations readiness | Backup/restore drill, runbooks, on-call workflow | RPO/RTO drills pass for critical services |
| 12 | Cutover and handover | Production cutover, hypercare plan, team enablement | Go-live acceptance and ownership transfer complete |

## Requirement Impact Matrix (Consolidated)

| Requirement ID | Business driver | Architectural impact | Security impact | Operational impact | Suggested solution patterns |
|---|---|---|---|---|---|
| BR-001 | Unified lifecycle insight | Canonical hierarchy and conformed dimensions | Identity boundary consistency | Lineage and ownership clarity | Canonical model + MDM-lite |
| BR-002 | BI scale and performance | Gold marts and semantic optimization | Role-based data exposure | Concurrency and cache strategy | Star schema + aggregation tables |
| BR-003 | AI productivity | Governed retrieval over structured/unstructured data | Permission-aware grounding | AI telemetry and quality checks | Semantic access broker + retrieval policies |
| BR-004 | Cost minimization | Incremental design, data tiering | Cost controls for privileged workloads | FinOps governance cadence | Partitioning + lifecycle policies |
| FR-004 | Legacy continuity | Hybrid ingestion architecture | Private connectivity and secrets | Backfill and retry robustness | Gateway + staged CDC export |
| FR-006 | Morning SLA | Orchestrated dependency DAG | Controlled pre-release gates | Active SLA alerting and runbooks | SLA-aware scheduling |
| NFR-004 | Regulatory auditability | Centralized immutable logs and lineage | Tamper-evident records | Retention and search obligations | Unified audit architecture |
| NFR-005 | Safe releases | Environment isolation and promotion policy | Segregation of duties | Controlled deployment process | CI/CD with approval gates |
| GOV-001 | KPI consistency | Shared semantic contract | Access policy reuse | Certification workflow | Certified dataset + semantic governance |
| SEC-001 | PII and financial protection | CLS/RLS/masking and data zoning | Least privilege and masking coverage | Access review and incident workflows | ABAC/RBAC + data classification |

## Missing Requirements and Ambiguities (Highlighted)

| Gap ID | Missing/Ambiguous area | Why it matters | Impact if unresolved | Clarifying question | Provisional assumption |
|---|---|---|---|---|---|
| GAP-001 | Exact near-real-time scope per source/use case | Determines need for streaming vs micro-batch | Cost and architecture churn | Which datasets truly require minute-level freshness? | Micro-batch default for MVP |
| GAP-002 | AI retrieval evidence depth | Controls whether JSON-only is enough | Potential rework for full-text/RAG | Must AI cite original document text as evidence? | JSON summaries in MVP, extend later |
| GAP-003 | Legal retention/eDiscovery detail | Drives storage/index architecture | Compliance and legal risk | Are full PDFs searchable online or archive-only? | Archive PDFs, searchable summaries first |
| GAP-004 | DR scope by service tier | Changes backup/failover investment | Over/under-engineering resilience | Which business services require 2h recovery? | Tiered DR model |
| GAP-005 | On-prem connectivity SLO | Affects ingestion reliability | SLA misses for critical reports | What uptime and bandwidth are guaranteed for gateway path? | 4-hour batch tolerance + nightly reconcile |
| GAP-006 | Qlik long-term strategy | Influences semantic governance burden | KPI drift if unmanaged | Is Qlik temporary or strategic for 2+ years? | Support both in phase 1-2 |
