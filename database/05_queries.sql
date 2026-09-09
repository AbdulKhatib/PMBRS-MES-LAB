-- Active batches
SELECT batch_number, product_code, status FROM batch WHERE status = 'ACTIVE';

-- Failed batches with the event that explains why
SELECT b.batch_number, pe.description, pe.event_timestamp
FROM batch b JOIN production_event pe ON b.batch_id = pe.batch_id
WHERE b.status = 'FAILED';

-- Production count by equipment
SELECT e.equipment_name, COUNT(b.batch_id) AS batch_count
FROM equipment e LEFT JOIN batch b ON e.equipment_id = b.equipment_id
GROUP BY e.equipment_name;