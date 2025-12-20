SET SERVEROUTPUT ON;

DROP TRIGGER TRG_VEHICULO_CAPACIDAD;
DROP TRIGGER TRG_CONDUCTOR_LIMITE_HORAS;
DROP TRIGGER TRG_ENVIO_FECHA_AUTOMATICA;
DROP TRIGGER TRG_VEHICULO_REFRIGERADO_CHECK;
DROP TRIGGER TRG_VEHICULO_ADR_CHECK;

CREATE OR REPLACE TRIGGER TRG_VEHICULO_CAPACIDAD
BEFORE INSERT OR UPDATE ON PAQUETE
FOR EACH ROW
DECLARE
    v_capacidad_vehiculo VEHICULO.CAPACIDAD_KG%TYPE;
    v_peso_actual_envio NUMBER;
    v_id_vehiculo EJECUCION.ID_VEHICULO%TYPE;
    v_nuevo_peso NUMBER := :NEW.PESO;
BEGIN
    -- 1. Obtener el ID_VEHICULO de la ejecución asociada al ENVIO
    SELECT ID_VEHICULO INTO v_id_vehiculo
    FROM EJECUCION
    WHERE ID_EJECUCION = :NEW.ID_ENVIO;

    -- 2. Obtener la capacidad máxima del vehículo
    SELECT CAPACIDAD_KG INTO v_capacidad_vehiculo
    FROM VEHICULO
    WHERE ID_VEHICULO = v_id_vehiculo;

    -- 3. Calcular el peso total actual del ENVIO (excluyendo o ajustando el registro actual)
    SELECT NVL(SUM(PESO), 0) INTO v_peso_actual_envio
    FROM PAQUETE
    WHERE ID_ENVIO = :NEW.ID_ENVIO
    AND NOT (ID_ENVIO = :NEW.ID_ENVIO AND N_PAQUETE = :NEW.N_PAQUETE);

    -- 4. Verificar la capacidad
    IF (v_peso_actual_envio + v_nuevo_peso) > v_capacidad_vehiculo THEN
        RAISE_APPLICATION_ERROR(-20005, 
            'Error: El peso total (' || (v_peso_actual_envio + v_nuevo_peso) || 
            ' Kg) excede la capacidad del vehículo (' || v_capacidad_vehiculo || ' Kg).');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error de validación: No se encontró la Ejecución/Vehículo para el Envío ' || :NEW.ID_ENVIO);
END;
/


CREATE OR REPLACE TRIGGER TRG_CONDUCTOR_LIMITE_HORAS
BEFORE INSERT OR UPDATE OF HORAS_SEMANA ON CONDUCTOR
FOR EACH ROW
BEGIN
    IF :NEW.HORAS_SEMANA > 50 THEN
        RAISE_APPLICATION_ERROR(-20007, 
            'Error: Las horas semanales de un conductor no pueden exceder las 50 horas (' || :NEW.HORAS_SEMANA || ' h).');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_ENVIO_FECHA_AUTOMATICA
BEFORE INSERT ON ENVIO
FOR EACH ROW
BEGIN
    -- Si la fecha no está especificada, se establece automáticamente a la fecha actual
    IF :NEW.FECHA IS NULL THEN
        :NEW.FECHA := SYSDATE;
        DBMS_OUTPUT.PUT_LINE('Trigger TRG_ENVIO_FECHA_AUTOMATICA: Fecha de envío asignada a SYSDATE.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER TRG_VEHICULO_REFRIGERADO_CHECK
BEFORE INSERT ON VEHICULO_REFRIGERADO
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Comprobar si el VEHICULO ya existe como VEHICULO_ADR
    SELECT COUNT(*) INTO v_count
    FROM VEHICULO_ADR
    WHERE ID_VEHICULO = :NEW.ID_VEHICULO;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 
            'Error: El vehículo ' || :NEW.ID_VEHICULO || ' ya está registrado como VEHICULO_ADR. No puede ser Refrigerado al mismo tiempo.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VEHICULO_ADR_CHECK
BEFORE INSERT ON VEHICULO_ADR
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Comprobar si el VEHICULO ya existe como VEHICULO_REFRIGERADO
    SELECT COUNT(*) INTO v_count
    FROM VEHICULO_REFRIGERADO
    WHERE ID_VEHICULO = :NEW.ID_VEHICULO;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20009, 
            'Error: El vehículo ' || :NEW.ID_VEHICULO || ' ya está registrado como VEHICULO_REFRIGERADO. No puede ser ADR al mismo tiempo.');
    END IF;
END;
/

-- ====================================================================
-- BLOQUE DE PRUEBAS PARA TRIGGERS (PRACTICA 4)
-- ====================================================================
DECLARE
    v_matricula_temp VEHICULO.MATRICULA%TYPE := '9999XYZ';
    v_id_vehiculo_temp VEHICULO.ID_VEHICULO%TYPE := 'TMP01';
    v_id_gps_temp GPS.ID_GPS%TYPE := 'gpsTMP';
    v_id_envio_temp ENVIO.ID_ENVIO%TYPE := 'ENV_T';
    v_id_paquete_temp PAQUETE.N_PAQUETE%TYPE := 100;
    v_id_conductor_temp CONDUCTOR.ID_EMPLEADO%TYPE := '8a8b8c'; -- 46h
    v_id_conductor_limite CONDUCTOR.ID_EMPLEADO%TYPE := '7a7b7c'; -- 50h
    v_id_cliente_temp CLIENTE.ID_CLIENTE%TYPE := 'cl001';
BEGIN
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '-------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('-- INICIO: PRUEBAS DE TRIGGERS SEMÁNTICOS Y AUTOMÁTICOS --');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
    
    -- Preparación para TRG_VEHICULO_CAPACIDAD (Capacidad: 7400 kg)
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- PREPARACION: VEHICULO, GPS y ENVIO TEMPORALES (Capacidad 7400kg) ---');
    INSERT INTO GPS (ID_GPS, MODELO, NUM_SERIE) VALUES (v_id_gps_temp, 'Test', '111SERIE');
    INSERT INTO VEHICULO (ID_VEHICULO, ID_GPS, MATRICULA, CAPACIDAD_KG) VALUES (v_id_vehiculo_temp, v_id_gps_temp, v_matricula_temp, 7400);
    INSERT INTO ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) VALUES (v_id_envio_temp, v_id_cliente_temp, SYSDATE, 'Pendiente');
    INSERT INTO EJECUCION (ID_EJECUCION, FECHA_EJECUCION, ID_VEHICULO, ID_RUTA) VALUES (v_id_envio_temp, SYSDATE, v_id_vehiculo_temp, 'ruta1a');
    COMMIT;

    -- ===================================================
    -- PRUEBA 1: TRG_VEHICULO_CAPACIDAD (BEFORE INSERT/UPDATE ON PAQUETE)
    -- ===================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 1. TRG_VEHICULO_CAPACIDAD ---');
    
    -- CASO A: Éxito (Inserción de paquete que respeta la capacidad 7400kg)
    BEGIN
        INSERT INTO PAQUETE (N_PAQUETE, ID_ENVIO, PESO, CONTENIDO) 
        VALUES (v_id_paquete_temp, v_id_envio_temp, 7000, 'Carga ligera');
        DBMS_OUTPUT.PUT_LINE('A. [ÉXITO] Paquete 7000kg insertado correctamente. Peso total: 7000kg.');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;

    -- CASO B: Fallo (Inserción que excede la capacidad 7400kg)
    BEGIN
        INSERT INTO PAQUETE (N_PAQUETE, ID_ENVIO, PESO, CONTENIDO) 
        VALUES (v_id_paquete_temp + 1, v_id_envio_temp, 500, 'Carga pesada');
        DBMS_OUTPUT.PUT_LINE('B. [FALLO ESPERADO] Sentencia ejecutada sin excepción (ERROR).');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20005 THEN
                DBMS_OUTPUT.PUT_LINE('B. [ÉXITO] Excepción capturada (Capacidad). ' || SUBSTR(SQLERRM, 1, 60) || '...');
            ELSE
                DBMS_OUTPUT.PUT_LINE('B. [FALLO INESPERADO] ' || SQLERRM);
            END IF;
            ROLLBACK;
    END;

    -- ===================================================
    -- PRUEBA 2: TRG_CONDUCTOR_LIMITE_HORAS (BEFORE INSERT/UPDATE ON CONDUCTOR)
    -- ===================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 2. TRG_CONDUCTOR_LIMITE_HORAS ---');
    
    -- CASO A: Éxito (Actualizar a 50 horas, el límite)
    BEGIN
        UPDATE CONDUCTOR SET HORAS_SEMANA = 50 WHERE ID_EMPLEADO = v_id_conductor_temp; -- Era 46
        DBMS_OUTPUT.PUT_LINE('A. [ÉXITO] Horas de ' || v_id_conductor_temp || ' actualizadas a 50 (límite).');
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;

    -- CASO B: Fallo (Actualizar a más de 50 horas)
    BEGIN
        UPDATE CONDUCTOR SET HORAS_SEMANA = 51 WHERE ID_EMPLEADO = v_id_conductor_temp;
        DBMS_OUTPUT.PUT_LINE('B. [FALLO ESPERADO] Sentencia ejecutada sin excepción (ERROR).');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20007 THEN
                DBMS_OUTPUT.PUT_LINE('B. [ÉXITO] Excepción capturada (Límite de Horas). ' || SUBSTR(SQLERRM, 1, 60) || '...');
            ELSE
                DBMS_OUTPUT.PUT_LINE('B. [FALLO INESPERADO] ' || SQLERRM);
            END IF;
            ROLLBACK;
    END;
    
    -- ===================================================
    -- PRUEBA 3: TRG_ENVIO_FECHA_AUTOMATICA (BEFORE INSERT ON ENVIO)
    -- ===================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 3. TRG_ENVIO_FECHA_AUTOMATICA ---');
    
    DELETE FROM ENVIO WHERE ID_ENVIO IN ('ENV_AUTO', 'ENV_FIJA');
    
    -- CASO A: Éxito (Insertar sin fecha, debe asignar SYSDATE)
    DECLARE
        v_fecha_check DATE;
        v_id_envio_auto ENVIO.ID_ENVIO%TYPE := 'ENV_AUTO';
    BEGIN
        INSERT INTO ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) VALUES (v_id_envio_auto, v_id_cliente_temp, NULL, 'Pendiente');
        SELECT FECHA INTO v_fecha_check FROM ENVIO WHERE ID_ENVIO = v_id_envio_auto;
        DBMS_OUTPUT.PUT_LINE('A. [ÉXITO] Envío insertado. Fecha (esperada SYSDATE): ' || TO_CHAR(v_fecha_check, 'YYYY-MM-DD HH24:MI:SS'));
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;
    
    -- CASO B: Éxito (Insertar CON fecha, NO debe cambiarla)
    DECLARE
        v_fecha_check DATE;
        v_fecha_fija DATE := TO_DATE('2023-12-25', 'YYYY-MM-DD');
        v_id_envio_fija ENVIO.ID_ENVIO%TYPE := 'ENV_FIJA';
    BEGIN
        INSERT INTO ENVIO (ID_ENVIO, ID_CLIENTE, FECHA, ESTADO) VALUES (v_id_envio_fija, v_id_cliente_temp, v_fecha_fija, 'Pendiente');
        SELECT FECHA INTO v_fecha_check FROM ENVIO WHERE ID_ENVIO = v_id_envio_fija;
        DBMS_OUTPUT.PUT_LINE('B. [ÉXITO] Envío insertado. Fecha (esperada 2023): ' || TO_CHAR(v_fecha_check, 'YYYY-MM-DD'));
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('B. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;

    -- ===================================================
    -- PRUEBA 4: TRG_VEHICULO_REFRIGERADO_CHECK / TRG_VEHICULO_ADR_CHECK (BEFORE INSERT)
    -- ===================================================
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- 4. TRG_REFRIGERADO_ADR\_CHECK ---');
    
    -- CASO A: Éxito (Insertar cam1a como Refrigerado, no es ADR)
    BEGIN
        INSERT INTO VEHICULO_REFRIGERADO (ID_VEHICULO, TEMP_MIN, TEMP_MAX) VALUES ('cam1a', -10, 0);
        DBMS_OUTPUT.PUT_LINE('A. [ÉXITO] cam1a registrado como Refrigerado (no era ADR).');
        ROLLBACK; -- Para no afectar otros tests
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('A. [FALLO INESPERADO] ' || SQLERRM);
            ROLLBACK;
    END;

    -- CASO B: Fallo (Insertar cam3a como Refrigerado, YA es ADR)
    BEGIN
        INSERT INTO VEHICULO_REFRIGERADO (ID_VEHICULO, TEMP_MIN, TEMP_MAX) VALUES ('cam3a', -5, 5); -- cam3a ya es ADR
        DBMS_OUTPUT.PUT_LINE('B. [FALLO ESPERADO] Sentencia ejecutada sin excepción (ERROR).');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20008 THEN
                DBMS_OUTPUT.PUT_LINE('B. [ÉXITO] Excepción capturada (ADR ya existe). ' || SUBSTR(SQLERRM, 1, 60) || '...');
            ELSE
                DBMS_OUTPUT.PUT_LINE('B. [FALLO INESPERADO] ' || SQLERRM);
            END IF;
            ROLLBACK;
    END;
    
    -- CASO C: Fallo (Insertar cam4a como ADR, YA es Refrigerado)
    BEGIN
        INSERT INTO VEHICULO_ADR (ID_VEHICULO, CLASEMERCANCIA) VALUES ('cam4a', '9'); -- cam4a ya es Refrigerado
        DBMS_OUTPUT.PUT_LINE('C. [FALLO ESPERADO] Sentencia ejecutada sin excepción (ERROR).');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20009 THEN
                DBMS_OUTPUT.PUT_LINE('C. [ÉXITO] Excepción capturada (Refrigerado ya existe). ' || SUBSTR(SQLERRM, 1, 60) || '...');
            ELSE
                DBMS_OUTPUT.PUT_LINE('C. [FALLO INESPERADO] ' || SQLERRM);
            END IF;
            ROLLBACK;
    END;

    -- Limpieza (borrar temporales)
    DELETE FROM EJECUCION WHERE ID_EJECUCION = v_id_envio_temp;
    DELETE FROM ENVIO WHERE ID_ENVIO = v_id_envio_temp;
    DELETE FROM VEHICULO WHERE ID_VEHICULO = v_id_vehiculo_temp;
    DELETE FROM GPS WHERE ID_GPS = v_id_gps_temp;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '-------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('-- FIN: PRUEBAS DE TRIGGERS SEMÁNTICOS Y AUTOMÁTICOS --');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
END;
/