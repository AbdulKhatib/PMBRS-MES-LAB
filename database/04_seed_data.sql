INSERT INTO batch_status VALUES ('PLANNED', 'Batch planned, not yet started');
INSERT INTO batch_status VALUES ('ACTIVE', 'Batch currently running');
INSERT INTO batch_status VALUES ('COMPLETE', 'Batch finished successfully');
INSERT INTO batch_status VALUES ('FAILED', 'Batch failed during production');
INSERT INTO batch_status VALUES ('CANCELLED', 'Batch cancelled before completion');

INSERT INTO equipment (equipment_name, area, status) VALUES ('FILL-01', 'Filling', 'RUNNING');
INSERT INTO equipment (equipment_name, area, status) VALUES ('FILL-02', 'Filling', 'STOPPED');
INSERT INTO equipment (equipment_name, area, status) VALUES ('PACK-01', 'Packaging', 'RUNNING');

INSERT INTO batch (batch_number, product_code, start_time, status, equipment_id) 
    VALUES ('BATCH-1001', 'PRD-A', SYSTIMESTAMP - 2, 'ACTIVE', 1);
INSERT INTO batch (batch_number, product_code, start_time, end_time, status, equipment_id) 
    VALUES ('BATCH-1002', 'PRD-B', SYSTIMESTAMP - 5, SYSTIMESTAMP - 3, 'COMPLETE', 3);
INSERT INTO batch (batch_number, product_code, start_time, end_time, status, equipment_id) 
    VALUES ('BATCH-1003', 'PRD-A', SYSTIMESTAMP - 1, SYSTIMESTAMP, 'FAILED', 2);

INSERT INTO production_event (batch_id, equipment_id, event_type, description, severity)
    VALUES (1, 1, 'START', 'Batch 1001 started on FILL-01', 'INFO');
INSERT INTO production_event (batch_id, equipment_id, event_type, description, severity)
    VALUES (3, 2, 'FAILURE', 'Batch 1003 failed - equipment fault', 'CRITICAL');

COMMIT;