# Part 2 - Platform Selection & Trade-offs

## 2.1 Main Recommendation

**Recommended platform: Microsoft Fabric**

For a client like Shimon Ltd., Fabric is the strongest fit because it aligns with current capabilities and constraints rather than forcing a costly platform jump.

Why Fabric fits this case:
1. **Existing Power BI footprint**: Shimon already uses Power BI, and Fabric extends that ecosystem directly (same identity model, familiar UX, tighter BI integration).
2. **Azure adjacency**: Some data already sits in Azure, so Fabric reduces integration friction versus moving to a new cloud stack.
3. **Small team, limited budget**: Fabric can reduce operational overhead by consolidating ingestion, storage, transformation, and BI in one managed platform.
4. **AI later, not now**: Fabric keeps an upgrade path to AI (Copilot experiences, notebook/ML workflows, integration with Azure AI services) without over-engineering day one.
5. **Time-to-value**: Less re-skilling and fewer cross-platform handoffs usually means faster delivery for a small organization.

In short: Fabric gives Shimon the best near-term delivery speed and governance consistency, while preserving medium-term AI options.

## 2.2 When NOT to Choose It

Three concrete cases where Fabric would be the wrong choice:

1. **Strong multi-cloud or cloud-neutral strategy is mandatory**
- If Shimon must run equally across AWS, GCP, and Azure with strict portability, Fabric can become too Microsoft-centric.
- Better pick: **Databricks** (multi-cloud architecture and more portable lakehouse patterns).

2. **Ultra-large, engineering-heavy data science platform is the core business need**
- If the primary need is advanced ML platform engineering at large scale (custom training pipelines, complex MLOps), Fabric may be less flexible than specialist stacks.
- Better pick: **Databricks** (mature data engineering + ML lifecycle capabilities).

3. **Primary BI/reporting stack is non-Microsoft and will remain so**
- If the enterprise standard is Tableau/Looker with no interest in Power BI, Fabric’s biggest advantage is diluted.
- Better pick: **Snowflake** (strong neutral data platform with broad BI tool interoperability).

## 2.3 Head-to-Head Comparison (Fabric vs Databricks)

Alternative selected for direct comparison: **Databricks**.

| Dimension | Microsoft Fabric (Recommended) | Databricks (Alternative) |
|---|---|---|
| **Cost (for Shimon profile)** | Often better for small teams already paying into Microsoft stack; fewer platform components to operate. | Can be cost-effective at scale, but may require more engineering effort and governance setup overhead for a small team. |
| **Scale** | Strong for most SME and mid-market scenarios; sufficient for Shimon’s current stage. | Excellent for very large-scale engineering and complex workloads. |
| **Governance** | Unified with Microsoft Entra/Azure patterns; easier for teams already in Microsoft ecosystem. | Strong governance capabilities, but often needs more deliberate architecture and platform engineering maturity. |
| **BI Integration** | Native Power BI integration is a major advantage for Shimon. | Works with Power BI, but not as natively integrated end-to-end. |
| **AI Readiness** | Good path for incremental AI adoption with lower initial complexity. | Very strong for advanced ML and data science engineering depth. |
| **Team Fit** | Better fit for small team with existing Microsoft skills. | Better when organization has stronger data engineering bench. |
| **Time-to-Value** | Faster for Shimon due to existing tools and lower change management. | Slower initially if team must build platform patterns and upskill deeply. |

Decision framing:
- For **Shimon now**: Fabric is the pragmatic business choice.
- For a **future state with heavy ML engineering**: Databricks could become more attractive.

## 2.4 Real-time vs. Batch

When a client asks for "real-time dashboards," validate the requirement before committing to streaming architecture.

How to verify whether true real-time is needed:
1. Ask what decision is made from the dashboard and how delay changes outcomes.
2. Define maximum acceptable data latency in business terms (e.g., 1 minute, 15 minutes, 1 hour).
3. Identify which metrics truly need low latency versus metrics that are historical/operational.
4. Check whether source systems can even provide event-level updates reliably.

Useful alternatives:
1. **Hourly batch**
- Best for management reporting, KPI tracking, daily operations.
- Lowest complexity and cost.
2. **Micro-batch (e.g., every 5-15 minutes)**
- Good compromise for near-real-time operational visibility.
- Typically sufficient for most "real-time" requests once clarified.
3. **Event-driven / streaming**
- Reserve for hard latency requirements (fraud detection, live dispatch, critical alerting).
- Highest cost and operational complexity.

Cost and complexity implications:
1. Streaming increases spend across ingestion, compute, monitoring, and incident response.
2. Real-time pipelines require stricter reliability engineering (idempotency, replay, late-arriving events, drift handling).
3. Many organizations overpay for real-time where micro-batch provides the same business value.

Practical guidance for Shimon:
- Start with **hourly or 15-minute micro-batch** for most dashboards.
- Upgrade only specific metrics to streaming if business impact clearly justifies added cost.

## 2.5 Architecture Review

When reviewing an existing client architecture, focus first on the highest-impact risks and quick wins.

Top risks to look for and recommended improvements:

1. **Cost risk: uncontrolled compute and storage growth**
- Symptoms: always-on clusters, duplicate data copies, no lifecycle policy.
- Improvements: auto-scaling/auto-stop, tiered storage, data retention policy, chargeback/showback dashboards.

2. **Scale risk: tightly coupled pipelines and single bottlenecks**
- Symptoms: one pipeline failure blocks all domains, long batch windows, poor backfill strategy.
- Improvements: domain-oriented pipelines, workload isolation, incremental processing, clear backfill/replay design.

3. **Security risk: broad access and weak secrets handling**
- Symptoms: shared service accounts, excessive admin rights, secrets in notebooks/scripts.
- Improvements: least privilege RBAC, managed identities/service principals, centralized secret vault, network segmentation.

4. **Governance risk: inconsistent definitions and low lineage visibility**
- Symptoms: conflicting KPI definitions, no certified semantic layer, unclear ownership.
- Improvements: business glossary, certified datasets/semantic models, lineage tracking, named data owners and stewards.

5. **Reliability risk: weak observability and recovery controls**
- Symptoms: no SLAs/SLOs, minimal alerting, manual recovery after failures.
- Improvements: pipeline SLIs/SLOs, proactive alerting, runbooks, retry policies, disaster recovery testing.

A practical review outcome should include:
1. A prioritized risk register (impact x likelihood).
2. A 30/60/90-day remediation plan.
3. Clear ownership per remediation item.
4. Success metrics (cost per workload, pipeline success rate, data freshness adherence, access violations, MTTR).
