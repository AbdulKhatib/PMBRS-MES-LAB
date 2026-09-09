ALTER TABLE batch ADD CONSTRAINT chk_batch_times 
    CHECK (end_time IS NULL OR end_time >= start_time);

ALTER TABLE equipment ADD CONSTRAINT chk_equipment_status 
    CHECK (status IN ('RUNNING','STOPPED','MAINTENANCE'));

CREATE INDEX idx_batch_equipment ON batch(equipment_id);
CREATE INDEX idx_event_batch ON production_event(batch_id);