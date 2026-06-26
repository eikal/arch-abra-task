WITH mql_events AS (
    SELECT
        ContactId,
        EventId AS MqlEventId,
        EventTimestamp AS MqlEventTimestamp,
        EventDescription AS MqlEventDescription,
        EventName AS MqlEventName,
        TriggeredByEvent AS MqlTriggeredByEvent,
        EventType AS MqlEventType
    FROM contact_history
    WHERE EventType = 'MQL'
),
prior_activity_candidates AS (
    SELECT
        m.ContactId,
        m.MqlEventId,
        m.MqlEventTimestamp,
        a.EventId AS SourceEventId,
        a.EventTimestamp AS SourceEventTimestamp,
        a.EventDescription AS SourceEventDescription,
        a.EventName AS SourceEventName,
        a.TriggeredByEvent AS SourceTriggeredByEvent,
        a.EventType AS SourceEventType,
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
