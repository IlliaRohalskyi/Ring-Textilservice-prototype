-- Create tables for Ring Textilservice data processing
-- This script is idempotent - safe to run multiple times

-- Overview table: production metrics
CREATE TABLE IF NOT EXISTS overview (
    date DATE PRIMARY KEY,
    tonage INTEGER,
    water_m3 REAL,
    liters_per_kg REAL,
    electricity_per_kg REAL,
    gas_per_kg REAL,
    gas_plus_elec_per_kg REAL,
    hours_production REAL,
    kg_per_hour REAL
);

-- Fleet table: vehicle and transport metrics
CREATE TABLE IF NOT EXISTS fleet (
    date DATE PRIMARY KEY,
    driving_hours REAL,
    kg_per_hour_driving REAL,
    km_driven INTEGER,
    CONSTRAINT fk_fleet_date FOREIGN KEY (date) REFERENCES overview (date)
);

-- Washing machines table: equipment performance
CREATE TABLE IF NOT EXISTS washing_machines (
    date DATE PRIMARY KEY,
    machine_130kg INTEGER,
    steps_130kg INTEGER,
    machine_85kg_plus_85kg INTEGER,
    machine_85kg_middle INTEGER,
    steps_85kg_middle INTEGER,
    machine_85kg_right INTEGER,
    steps_85kg_right INTEGER,
    electrolux INTEGER,
    avg_load_130kg REAL,
    avg_load_85kg_middle REAL,
    avg_load_85kg_right REAL,
    CONSTRAINT fk_washing_machines_date FOREIGN KEY (date) REFERENCES overview (date)
);

-- Drying table: drying equipment and processes
CREATE TABLE IF NOT EXISTS drying (
    date DATE PRIMARY KEY,
    roboter_1 INTEGER,
    roboter_2 INTEGER,
    roboter_3 INTEGER,
    roboter_4 INTEGER,
    terry_prep_1 INTEGER,
    terry_prep_2 INTEGER,
    terry_prep_3 INTEGER,
    terry_prep_4 INTEGER,
    blankets_1 INTEGER,
    blankets_2 INTEGER,
    sum_drying_load INTEGER,
    steps_total INTEGER,
    kipper INTEGER,
    avg_drying_load REAL,
    sum_drying INTEGER,
    steps INTEGER,
    CONSTRAINT fk_drying_date FOREIGN KEY (date) REFERENCES overview (date)
);