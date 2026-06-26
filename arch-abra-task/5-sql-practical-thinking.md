# Part 5 - SQL / Practical Thinking

Date: 2026-06-26  
Scope: MQL source attribution query and scale strategy

## 5.0 Execution Setup and Embedded Sample Data

Executed engine: SQLite (local `marketing.db`)

Source file used: [contact_history_sample.csv](contact_history_sample.csv)

Embedded sample data (same 19 rows used for query execution):

| ContactId | EventId | EventTimestamp | EventDescription | EventName | TriggeredByEvent | EventType |
|---|---:|---|---|---|---|---|
| C001 | 1001 | 2026-01-03 09:00:00 | Registered for Jan digital event | Digital Kickoff | Digital Event | Registration |
| C001 | 1002 | 2026-01-05 10:00:00 | Downloaded product brochure | Loan Brochure | Campaign | PDF Download |
| C001 | 1003 | 2026-01-10 12:00:00 | Attended webinar | SME Credit Webinar | Webinar | Attendance |
| C001 | 1004 | 2026-01-12 08:30:00 | Became MQL | MQL Jan | Campaign | MQL |
| C001 | 1005 | 2026-01-15 11:00:00 | Visited cost estimator page | Cost Estimator | Campaign | Estimator Visit |
| C001 | 1006 | 2026-01-20 09:15:00 | Handraise in webinar follow-up | Follow-up Handraise | Webinar | Handraise |
| C001 | 1007 | 2026-01-20 09:15:00 | Became MQL second time | MQL Jan Follow-up | Campaign | MQL |
| C002 | 2001 | 2026-02-01 14:00:00 | Attended physical roadshow | Roadshow TLV | Physical Event | Attendance |
| C002 | 2002 | 2026-02-02 10:00:00 | Downloaded pricing sheet | Pricing PDF | Campaign | PDF Download |
| C002 | 2003 | 2026-02-03 09:00:00 | Became MQL | MQL Feb | Campaign | MQL |
| C002 | 2004 | 2026-02-03 09:00:00 | Same time digital click | Same Time Click | Digital Event | Click |
| C003 | 3001 | 2026-03-01 08:00:00 | Became MQL with no prior activity | MQL Direct | Campaign | MQL |
| C004 | 4001 | 2026-03-05 10:00:00 | Registered webinar | Funding Webinar | Webinar | Registration |
| C004 | 4002 | 2026-03-05 10:00:00 | Visited estimator same timestamp | Estimator Visit | Campaign | Estimator Visit |
| C004 | 4003 | 2026-03-06 09:00:00 | Became MQL | MQL March | Campaign | MQL |
| C005 | 5001 | 2026-03-10 08:00:00 | Downloaded whitepaper | Whitepaper | Campaign | PDF Download |
| C005 | 5002 | 2026-03-10 08:00:00 | Attended webinar same timestamp | Partner Webinar | Webinar | Attendance |
| C005 | 5003 | 2026-03-10 12:00:00 | Became MQL | MQL Noon | Campaign | MQL |
| C005 | 5004 | 2026-03-11 09:00:00 | Attended physical event after MQL | Expo Visit | Physical Event | Attendance |

## 5.1 Query A (ANSI Window Function)

Dialect: ANSI SQL (works in SQLite/Postgres/Snowflake/BigQuery/Databricks SQL with minor type syntax differences if needed).

```sql
WITH mql_events AS (
    SELECT
        ContactId,
        EventId      AS MqlEventId,
        EventTimestamp AS MqlEventTimestamp,
        EventDescription AS MqlEventDescription,
        EventName    AS MqlEventName,
        TriggeredByEvent AS MqlTriggeredByEvent,
        EventType    AS MqlEventType
    FROM contact_history
    WHERE EventType = 'MQL'
),
prior_activity_candidates AS (
    SELECT
        m.ContactId,
        m.MqlEventId,
        m.MqlEventTimestamp,
        a.EventId          AS SourceEventId,
        a.EventTimestamp   AS SourceEventTimestamp,
        a.EventDescription AS SourceEventDescription,
        a.EventName        AS SourceEventName,
        a.TriggeredByEvent AS SourceTriggeredByEvent,
        a.EventType        AS SourceEventType,
        ROW_NUMBER() OVER (
            PARTITION BY m.ContactId, m.MqlEventId
            ORDER BY a.EventTimestamp DESC, a.EventId DESC
        ) AS rn
    FROM mql_events m
    LEFT JOIN contact_history a
        ON a.ContactId = m.ContactId
       AND a.EventType <> 'MQL'
       AND (
            a.EventTimestamp < m.MqlEventTimestamp
            OR (
                a.EventTimestamp = m.MqlEventTimestamp
                AND a.EventId < m.MqlEventId
            )
       )
)
SELECT
    m.ContactId,
    m.MqlEventId,
    m.MqlEventTimestamp,
    m.MqlEventDescription,
    m.MqlEventName,
    m.MqlTriggeredByEvent,
    c.SourceEventId,
    c.SourceEventTimestamp,
    c.SourceEventDescription,
    c.SourceEventName,
    c.SourceTriggeredByEvent,
    c.SourceEventType
FROM mql_events m
LEFT JOIN prior_activity_candidates c
    ON c.ContactId = m.ContactId
   AND c.MqlEventId = m.MqlEventId
   AND c.rn = 1
ORDER BY m.ContactId, m.MqlEventTimestamp, m.MqlEventId;
```

Execution result (actual run on `marketing.db`):

| ContactId | MqlEventId | MqlEventTimestamp | SourceEventId | SourceEventTimestamp | SourceTriggeredByEvent | SourceEventType |
|---|---:|---|---:|---|---|---|
| C001 | 1004 | 2026-01-12 08:30:00 | 1003 | 2026-01-10 12:00:00 | Webinar | Attendance |
| C001 | 1007 | 2026-01-20 09:15:00 | 1006 | 2026-01-20 09:15:00 | Webinar | Handraise |
| C002 | 2003 | 2026-02-03 09:00:00 | 2002 | 2026-02-02 10:00:00 | Campaign | PDF Download |
| C003 | 3001 | 2026-03-01 08:00:00 | NULL | NULL | NULL | NULL |
| C004 | 4003 | 2026-03-06 09:00:00 | 4002 | 2026-03-05 10:00:00 | Campaign | Estimator Visit |
| C005 | 5003 | 2026-03-10 12:00:00 | 5002 | 2026-03-10 08:00:00 | Webinar | Attendance |

## 5.2 Query B (ANSI Self-Join + NOT EXISTS)

Dialect: ANSI SQL.

```sql
SELECT
    m.ContactId,
    m.EventId AS MqlEventId,
    m.EventTimestamp AS MqlEventTimestamp,
    a.EventId AS SourceEventId,
    a.EventTimestamp AS SourceEventTimestamp,
    a.TriggeredByEvent AS SourceTriggeredByEvent,
    a.EventType AS SourceEventType
FROM contact_history m
LEFT JOIN contact_history a
    ON a.ContactId = m.ContactId
   AND a.EventType <> 'MQL'
   AND (
        a.EventTimestamp < m.EventTimestamp
        OR (a.EventTimestamp = m.EventTimestamp AND a.EventId < m.EventId)
   )
   AND NOT EXISTS (
        SELECT 1
        FROM contact_history a2
        WHERE a2.ContactId = m.ContactId
          AND a2.EventType <> 'MQL'
          AND (
               a2.EventTimestamp < m.EventTimestamp
               OR (a2.EventTimestamp = m.EventTimestamp AND a2.EventId < m.EventId)
          )
          AND (
               a2.EventTimestamp > a.EventTimestamp
               OR (a2.EventTimestamp = a.EventTimestamp AND a2.EventId > a.EventId)
          )
   )
WHERE m.EventType = 'MQL'
ORDER BY m.ContactId, m.EventTimestamp, m.EventId;
```

Execution result (actual run on `marketing.db`):

| ContactId | MqlEventId | MqlEventTimestamp | SourceEventId | SourceEventTimestamp | SourceTriggeredByEvent | SourceEventType |
|---|---:|---|---:|---|---|---|
| C001 | 1004 | 2026-01-12 08:30:00 | 1003 | 2026-01-10 12:00:00 | Webinar | Attendance |
| C001 | 1007 | 2026-01-20 09:15:00 | 1006 | 2026-01-20 09:15:00 | Webinar | Handraise |
| C002 | 2003 | 2026-02-03 09:00:00 | 2002 | 2026-02-02 10:00:00 | Campaign | PDF Download |
| C003 | 3001 | 2026-03-01 08:00:00 | NULL | NULL | NULL | NULL |
| C004 | 4003 | 2026-03-06 09:00:00 | 4002 | 2026-03-05 10:00:00 | Campaign | Estimator Visit |
| C005 | 5003 | 2026-03-10 12:00:00 | 5002 | 2026-03-10 08:00:00 | Webinar | Attendance |

## 5.3 Verification Against Task.md Chapter 5 Requirements

Verification queries run:
1. Result row count vs MQL count.
2. Symmetric difference between Query A and Query B outputs.
3. Null-source edge case count.

Observed verification output:
1. `q1_minus_q2 = 0`
2. `q2_minus_q1 = 0`
3. `mql_count = 6`
4. `result_count = 6`
5. `null_source_count = 1`

Requirement compliance matrix:

| Requirement (Task.md Chapter 5) | Status | Evidence |
|---|---|---|
| Return one row per MQL event | PASS | `result_count = 6` and `mql_count = 6` |
| Return only latest marketing activity before MQL | PASS | Ordering logic (`EventTimestamp DESC, EventId DESC`) + output examples C001/1004 -> 1003, C005/5003 -> 5002 |
| Exclude activities after MQL | PASS | Join predicate only allows earlier events; C005/5004 (after MQL 5003) is not selected |
| Handle multiple MQLs per contact | PASS | C001 has two MQLs (1004, 1007), each mapped correctly |
| Tie-break same timestamp via EventId | PASS | C001 MQL 1007 at same timestamp as activity 1006, selected source is 1006 (lower than MQL EventId and latest prior) |
| If no prior activity exists, return NULL source fields | PASS | C003/3001 returns NULL source columns |
| No manual/Excel logic | PASS | Fully SQL-based execution in SQLite |

Conclusion: both SQL approaches satisfy all Chapter 5 business rules on the provided sample data.

## 5.4 Scale and Optimization (500M rows)

### A. How the baseline query behaves

| Topic | Behavior at 500M | Risk |
|---|---|---|
| Join cardinality | MQL rows join to many prior events for same contact | Large intermediate shuffle/sort |
| Window function | `ROW_NUMBER` requires partition sort by contact + event order | Expensive memory and spill if poorly clustered |
| Full table scans | Likely if table layout does not prune data | High compute cost and long runtime |

### B. Data modeling for performance

| Modeling choice | Why it helps |
|---|---|
| Keep immutable event log at atomic grain | Supports replay and deterministic attribution |
| Add derived sequence per contact (`contact_event_seq`) | Speeds predecessor lookups and incremental logic |
| Maintain separate MQL table/materialization | Reduces scan for target events |
| Normalize EventType values and encode compactly | Better compression and scan efficiency |
| Persist incremental attribution table (`mql_attribution`) | Avoids full recompute over historical data |

### C. Platform-specific optimization guidance

| Platform | Physical optimization | Serving optimization | Notes |
|---|---|---|---|
| Fabric (Warehouse/Lakehouse) | Partition by event date; cluster/order by ContactId, EventTimestamp; optimize Delta maintenance | Materialized attribution table for recent windows; semantic model over curated output | Align heavy jobs off SLA window; preserve capacity headroom for BI |
| Snowflake | Micro-partition pruning via clustering key on (ContactId, EventTimestamp); search optimization if selective | Dynamic tables/materialized views for incremental attribution | Monitor warehouse size and auto-suspend/resume to control spend |
| Databricks | Delta partition by date; Z-ORDER on (ContactId, EventTimestamp); OPTIMIZE + VACUUM cadence | Incremental Delta Live Tables/job for changed contacts only | Photon + file compaction reduce scan overhead |
| BigQuery | Partition by DATE(EventTimestamp); cluster by ContactId, EventType | Incremental scheduled query into attribution table | Control bytes scanned with partition filters and column pruning |
| AWS Redshift | Sort key on (ContactId, EventTimestamp); distribution key on ContactId where appropriate | Materialized view or incremental ETL table for attribution | WLM/concurrency scaling tuning for mixed BI + ETL workloads |

### D. Why queries become expensive

| Cost driver | What to inspect | Example symptom |
|---|---|---|
| Data scanned | Partition pruning effectiveness | Query scans full history despite daily reporting need |
| Shuffle/sort | Window and join distribution | Large spill-to-disk, long stage durations |
| Skew | Contacts with very high event counts | Single partition stragglers dominate runtime |
| Recompute | Reprocessing old unchanged periods | Same historical months recomputed daily |

### E. Incremental model (preferred over full recompute)

| Step | Incremental strategy |
|---|---|
| 1. Capture deltas | Ingest only new/changed contact_history rows (CDC or watermark on EventTimestamp + EventId). |
| 2. Detect impacted contacts | Build a small set of ContactId values with new events or changed MQL events. |
| 3. Recompute attribution only for impacted contacts and bounded lookback window | Re-run attribution logic for those contacts, not all history. |
| 4. Merge into `mql_attribution` | Upsert by (ContactId, MqlEventId) to replace changed mappings. |
| 5. Validate | Row-count checks, null-rate checks, and deterministic tie-break assertions. |

Suggested attribution table:
1. Key: `(ContactId, MqlEventId)`.
2. Columns: MQL fields, source activity fields, attribution_run_ts, attribution_version.
3. SLA usage: BI and AI read this curated table instead of recomputing attribution on demand.

## 5.5 Practical test checklist

| Test case | Expected result |
|---|---|
| MQL with multiple earlier activities | Only latest earlier activity returned |
| Activity after MQL exists | Must not be selected |
| Two activities same timestamp before MQL | Activity with larger EventId selected |
| No activity before MQL | Source columns are NULL |
| Contact has 2+ MQL events | Each MQL gets its own correct source |

