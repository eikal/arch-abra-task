# Part 4 - Operations, FinOps & Production Readiness

Date: 2026-06-26  
Platform context: Microsoft Fabric-first architecture for Shimon Ltd.

## 4.1 Production Readiness

### A. Production operating controls

| Domain | What is implemented in production | KPI / SLO target | Owner |
|---|---|---|---|
| Monitoring and alerting | End-to-end pipeline monitoring (ingestion, transform, publish), capacity health, query performance, gateway health, API failure rates. Alert tiers: P1 (SLA risk), P2 (degradation), P3 (non-critical). | P1 alert detection < 5 minutes; alert-to-ack < 15 minutes | DataOps + Platform Ops |
| Observability | Central logs, metrics, traces, data quality scorecards, lineage-aware incident views, run-level audit IDs for each pipeline. | 100% critical pipelines emit run metadata and quality status | Data Engineering |
| CI/CD | Git-based branching, pull-request checks, automated deployment pipelines, environment promotion with approvals, semantic model regression tests. | 0 manual prod hotfix without change ticket; 100% deploy artifacts versioned | Platform Lead |
| Environments | Separate Dev/Test/Prod workspaces and capacities, isolated service principals, masked non-prod data for sensitive domains. | Zero direct dev write access to prod | Platform Security |
| Failure handling | Retry with exponential backoff, dead-letter/quarantine zones, partial-failure isolation by domain, incident runbooks by pipeline. | > 99% critical job completion by scheduled window | DataOps |
| Backfill and replay | Partition-aware replay, watermark reset controls, idempotent upsert/merge logic, reconciliation jobs after backfill. | Backfill reproducibility 100%; no duplicate business keys | Data Engineering |

### B. SLA, RPO, RTO design

| Requirement | Target for Shimon | Technical design | Operational evidence |
|---|---|---|---|
| 08:00 reporting SLA | Gold marts + semantic refresh complete by 07:40, 20-minute buffer before 08:00 | Critical domain pipelines run overnight with dependency graph, early cut-off for non-critical jobs, pre-08:00 freshness validation gate | Daily SLA report with pipeline end-time, semantic refresh time, and dashboard readiness status |
| RPO (Recovery Point Objective) | <= 4 hours for critical financial/reporting data | Incremental ingestion every 1-4 hours by source, checkpointing/watermarks, immutable Bronze retention and replay | Recovery drills show max data loss window within policy |
| RTO (Recovery Time Objective) | <= 2 hours for critical reporting path | Predefined failover runbooks, prioritized restart sequence (ingest -> gold -> semantic), warm standby for gateway/connectivity components | Incident postmortems include measured restore time vs RTO |

### C. Go-live documentation checklist

| Document set | Minimum content before go-live | Acceptance owner |
|---|---|---|
| Architecture baseline | Final logical + physical architecture, data flow map, dependency map, environment topology | Enterprise Architect |
| Runbooks | Failure triage, restart order, replay/backfill steps, escalation matrix, P1 communication template | DataOps Lead |
| SLA/SLO catalog | SLA definitions, freshness commitments, business criticality tiering, breach protocol | Product Owner + Ops |
| Security and access | RBAC matrix, RLS/CLS policy map, privileged access workflow, break-glass process | Security Officer |
| Data contracts | Source schemas, freshness expectations, quality gates, change-notice requirements | Data Engineering Lead |
| DR and BCP | RPO/RTO controls, backup retention, restoration test evidence, fallback reporting procedure | Platform Owner |
| FinOps baseline | Budget allocation, unit cost KPIs, cost alert thresholds, monthly optimization cadence | FinOps Owner |
| Test evidence | UAT sign-off, reconciliation packs, performance/load tests, semantic metric parity tests (Power BI/Qlik/AI) | QA + Business Owner |

## 4.2 FinOps & Cost Architecture

### A. 3x cost overrun: investigation approach

| Step | What to analyze | Typical signals | Tools/outputs |
|---|---|---|---|
| 1. Baseline variance | Compare planned vs actual by service/domain/workspace | Cost spike starts after specific release or source onboarding | Monthly cost variance report by tag/workload |
| 2. Compute attribution | Identify which jobs, notebooks, refreshes, or capacities consume most CU/compute | Long-running transforms, overlapping refresh windows, excessive concurrency | Capacity utilization timeline + top job cost table |
| 3. Storage growth | Analyze Bronze/Silver/Gold growth, duplicate copies, retention misconfig | Rapid historical duplication, snapshots retained too long, hot-tier overuse | Storage age/temperature distribution report |
| 4. Data movement | Measure cross-region egress/API pull inefficiency/redundant extracts | Repeated full loads, high outbound transfer, unnecessary intermediate copies | Data movement and egress matrix |
| 5. BI and semantic load | Check semantic model design, refresh frequency, report query inefficiency | Too many full refreshes, high-cardinality model bloat | Semantic refresh profile + query performance traces |
| 6. AI/search load | Examine embedding/index rebuild frequency and retrieval volume | Re-embedding unchanged documents, broad retrieval scope | AI job cost per 1,000 queries/documents |

### B. Likely causes in this Fabric-first workload

| Cost bucket | Likely cause in Shimon context | Why it happens |
|---|---|---|
| Compute | Overlapping overnight transforms + semantic refresh + ad hoc daytime jobs | Small team schedules jobs by convenience, not capacity windows |
| Compute | Full reloads instead of incremental merges for some entities | CDC/watermark controls not enforced consistently |
| Storage | Bronze and Silver duplication without retention tiers | "Keep everything forever" defaults after rapid MVP go-live |
| Data movement | Repeated API extracts and unnecessary cross-workspace copies | Weak reuse of standardized ingestion artifacts |
| BI | Too many near-identical semantic models and frequent full refreshes | Local report team autonomy without semantic governance guardrails |
| AI/search | Full index rebuilds and broad document retrieval for every request | No delta-index strategy and no query pre-filtering |

### C. Cost-efficient redesign actions

| Priority | Redesign action | Cost impact | Trade-off |
|---|---|---|---|
| 1 | Enforce incremental-only pipelines with watermark checks and block full-load fallback in prod | High compute reduction | Slightly more complex failure recovery logic |
| 2 | Re-plan orchestration windows: isolate critical SLA jobs from non-critical workloads | High compute and concurrency reduction | Less scheduling flexibility for ad hoc jobs |
| 3 | Introduce storage lifecycle policy (hot -> cool/archive) and retention-by-tier | High storage reduction | Longer restore time for cold historical data |
| 4 | Consolidate semantic models into certified shared models/marts | Medium BI compute reduction | Teams give up custom local transformations |
| 5 | Delta embeddings/index updates only on changed docs | Medium AI/search reduction | Requires change-tracking metadata discipline |
| 6 | Tag-based cost ownership with monthly showback/chargeback | Medium sustained reduction | Additional governance/admin overhead |

### D. Fabric capacity/scaling behavior and implication

| Platform behavior (Fabric) | Risk if unmanaged | FinOps control |
|---|---|---|
| Shared capacity consumed by concurrent ingestion, transformations, and BI/semantic workloads | Throttling or expensive scale-up during peak windows | Workload isolation windows + priority scheduling |
| Burst usage during refresh peaks | High monthly run-rate variability | Capacity autoscale guardrails + capped burst policy |
| Interactive BI and scheduled pipelines compete for same capacity headroom | SLA misses or forced overprovisioning | Reserve headroom for 06:00-08:00 critical path; move non-critical jobs off-peak |
| Always-on heavy transformations | Persistent high burn rate | Convert to event-triggered or schedule-based execution |

### E. High-level monthly cost allocation (target envelope: 25,000 USD)

| Cost area | Target share of budget | High-level amount (USD/month) | Notes |
|---|---|---:|---|
| Ingestion | 10% | 2,500 | Pipelines, connectors, gateway ops |
| Storage | 15% | 3,750 | OneLake tiers, retention, archival |
| Compute (data engineering + transformations) | 30% | 7,500 | Largest controllable cost driver |
| BI / semantic serving | 18% | 4,500 | Semantic refresh, query workload |
| AI / search | 10% | 2,500 | Summary retrieval, indexing, optional vector ops |
| Monitoring / observability | 5% | 1,250 | Logs, metrics retention, alerting |
| Environments (Dev/Test overhead) | 7% | 1,750 | Non-prod capacities and test runs |
| Backup / DR | 5% | 1,250 | Snapshots, replication, DR drills |
| **Total** | **100%** | **25,000** | Planning baseline, not exact vendor quote |

## 4.3 Budget Cut (40% reduction without hurting core SLA)

Target: reduce monthly spend from 25,000 to approximately 15,000 USD while preserving 08:00 SLA for critical reports.

### A. Execution order and concrete actions

| Order | Action | Expected savings contribution | Keep / change |
|---|---|---|---|
| 1 | Freeze non-critical enhancements and non-essential daytime compute immediately | 5-8% | Keep core ingestion, Gold, semantic refresh |
| 2 | Move all non-critical pipelines and heavy backfills out of SLA window; enforce workload priority | 6-10% | Keep 08:00 critical jobs protected |
| 3 | Eliminate full refreshes; enforce incremental loads and partition pruning across large facts | 8-12% | Keep metric correctness via reconciliation checks |
| 4 | Apply aggressive storage lifecycle and retention cleanup for duplicated historical intermediates | 5-8% | Keep immutable audit-required raw retention only where mandated |
| 5 | Consolidate semantic models and deprecate duplicate departmental models | 4-6% | Keep certified KPI layer only |
| 6 | Restrict AI/search to high-value use cases; delta re-index only | 3-5% | Keep "latest summary" and exposure Q&A use cases |
| 7 | Right-size Dev/Test capacities and schedule auto-stop outside working windows | 3-5% | Keep release validation gates |

### B. Trade-offs accepted vs refused

| Category | Accepted trade-offs | Refused trade-offs |
|---|---|---|
| Freshness | Non-critical domains moved from hourly to every 4-12 hours | Any degradation that risks 08:00 critical reporting SLA |
| Scope | Defer advanced AI/search breadth and lower-priority marts | Removing controls required for financial compliance and audit |
| Performance | Slightly slower ad hoc exploration for non-priority users | Breaking governed KPI consistency across Power BI/Qlik/AI |
| Operations | Stricter change control and fewer parallel experiments in prod | Disabling monitoring/alerting or DR tests to save cost |

## 4.4 Delivery Plan & 12-Week Roadmap

### A. 12-week plan with MVP by week 6

| Weeks | Scope | Deliverables | Acceptance criteria |
|---|---|---|---|
| 1-2 | Foundation | Environment setup, security baseline, source connectivity, data contracts, CI/CD skeleton | Dev/Test/Prod available, access model approved, first source ingested to Bronze |
| 3-4 | Core ingestion + conformance | CRM, ERP, legacy SQL, Cosmos summaries incremental pipelines to Silver; DQ rules v1 | >= 95% ingestion success rate, critical keys validated, reconciliation baseline established |
| 5-6 (MVP value) | Gold marts + semantic MVP | `Total Credit Exposure`, `Missing Documents`, `Latest Document Summary` use cases in Power BI + governed endpoint for Qlik/AI | Business demo accepted: answers match controlled test cases and daily refresh meets timeline |
| 7-8 | Hardening | SLA orchestration, observability dashboards, incident runbooks, replay/backfill automation | Dry-run incidents resolved within target operational runbook times |
| 9-10 | Governance expansion | Catalog/lineage completeness, certification workflow, policy automation for access reviews | 100% critical datasets cataloged with owner/steward and lineage |
| 11-12 | Production readiness + cutover | UAT, performance tuning, DR drill, cutover rehearsal, go-live | Go-live checklist signed, SLA met in rehearsal, rollback validated |

### B. What is in MVP vs deferred to phase 2

| Scope decision | MVP (by week 6) | Phase 2 (post week 12) |
|---|---|---|
| Sources | Core CRM, ERP, legacy SQL, Cosmos summaries | Additional SaaS enrichments and edge domains |
| Analytics | Core exposure, document coverage, key finance/risk KPIs | Extended departmental analytics and long-tail KPIs |
| AI-readiness | Governed summary retrieval over structured metadata and latest summaries | Full-text retrieval expansion, advanced vector search, broader copilot experiences |
| Governance | Core RBAC/RLS/CLS, catalog for critical assets, audit logging | Advanced ABAC automation and extended stewardship workflows |

### C. Team model, risks, dependencies, assumptions

| Area | Definition |
|---|---|
| Core team | Platform Lead/Architect (1), Data Engineers (2), Analytics Engineer/Semantic Modeler (1), BI Developer (1), Security/Governance SME (0.5), QA/UAT Lead (0.5), Product Owner (1) |
| Key dependencies | Source system owners, gateway/network approvals, identity group readiness, business KPI sign-off, legal/compliance policy decisions |
| Critical assumptions | Access to source APIs/DBs granted on time; business owners available weekly; no major source schema breaks without notice |
| Top risks | Delayed source access, uncontrolled schema drift, unresolved KPI definition disputes, under-scoped operational ownership |
| Risk response | Early contract sign-off, schema change process, KPI governance council, explicit RACI before week 4 |

### D. Cutover / migration approach (coexistence, validation, rollback)

| Phase | Approach | Exit criteria |
|---|---|---|
| Coexistence | Run legacy reporting and new platform in parallel for agreed period; same KPI pack produced by both | Variance within agreed tolerance (e.g., <= 1%) for critical KPIs |
| Validation | Daily reconciliation by source and KPI, user acceptance from finance/risk teams, lineage checks complete | Business sign-off for critical dashboards and semantic queries |
| Cutover | Route primary BI consumption to new semantic model, freeze legacy logic changes, monitor hypercare | 2 consecutive weeks of SLA success with no Sev-1 data incidents |
| Rollback | Keep legacy pipeline/reporting runnable during hypercare; pre-approved rollback switch and communication runbook | Rollback rehearsed and timed before production go-live |

## 4.5 Operating Model After Handover

### A. Ownership model (small internal team)

| Capability | Primary owner | Backup owner | Cadence / control |
|---|---|---|---|
| Pipeline operations | Data Engineer A | Data Engineer B | Daily run review + weekly reliability review |
| Semantic models and KPI definitions | Analytics Engineer + Business KPI Owner | BI Lead | Weekly metric governance board |
| Data quality rules and incidents | Data Engineer B | Data Engineer A | Daily DQ scorecard + monthly rule tuning |
| Access approvals and policy enforcement | Security/Governance Owner | Platform Lead | Access review every 2 weeks |
| Cost monitoring and optimization | FinOps Owner (shared role) | Platform Lead | Weekly cost dashboard + monthly optimization sprint |
| Incident management | DataOps on-call rotation | Platform Lead | 24x7 P1 escalation, postmortem within 48 hours |
| Change requests and release | Product Owner + Platform Lead | QA Lead | Biweekly change advisory and release train |

### B. Lightweight RACI for sustained operations

| Activity | Responsible | Accountable | Consulted | Informed |
|---|---|---|---|---|
| New pipeline onboarding | Data Engineering | Platform Lead | Security, Source Owner | Business Stakeholders |
| KPI definition change | Analytics Engineer | Business KPI Owner | Risk, Finance, Data Engineering | BI/AI Consumers |
| Access exception approval | Security Owner | Compliance Lead | Platform Lead | Requestor Manager |
| Cost optimization decision | FinOps Owner | Platform Lead | Product Owner, Data Engineering | Finance Controller |
| P1 incident closure | On-call Engineer | Platform Lead | Security/Source teams | Executive stakeholders |

### C. Post-handover operating cadence

| Cadence | Meeting / artifact | Purpose |
|---|---|---|
| Daily | Ops stand-up + SLA/DQ dashboard review | Resolve failures quickly and protect 08:00 SLA |
| Weekly | Reliability + cost review | Track incidents, performance, and burn-rate corrections |
| Biweekly | Change advisory board | Approve releases and schema/KPI changes |
| Monthly | Governance and access audit | Ensure compliance, least privilege, and lineage completeness |
| Quarterly | DR and resilience test | Validate RPO/RTO and improve runbooks |
