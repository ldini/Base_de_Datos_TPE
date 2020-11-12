-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2020-09-21 21:47:13.678

-- foreign keys
ALTER TABLE G29_Billetera
    DROP CONSTRAINT FK_G29_Billetera_Moneda;

ALTER TABLE G29_Billetera
    DROP CONSTRAINT FK_G29_Billetera_Usuario;

ALTER TABLE G29_ComposicionOrden
    DROP CONSTRAINT FK_G29_CompOp_Op_d;

ALTER TABLE G29_ComposicionOrden
    DROP CONSTRAINT FK_G29_CompOp_Op_o;

ALTER TABLE G29_Movimiento
    DROP CONSTRAINT FK_G29_Movimiento_Billetera;

ALTER TABLE G29_Orden
    DROP CONSTRAINT FK_G29_Operacion_Mercado;

ALTER TABLE G29_Orden
    DROP CONSTRAINT FK_G29_Operacion_Usuario;

ALTER TABLE G29_RelMoneda
    DROP CONSTRAINT FK_G29_RelMoneda_Moneda;

ALTER TABLE G29_RelMoneda
    DROP CONSTRAINT FK_G29_RelMoneda_Monedaf;

ALTER TABLE G29_Usuario
    DROP CONSTRAINT FK_G29_Usuario_Pais;

ALTER TABLE G29_Mercado
    DROP CONSTRAINT FK_G29_mercado_moneda_d;

ALTER TABLE G29_Mercado
    DROP CONSTRAINT FK_G29_mercado_moneda_o;

-- tables
DROP TABLE G29_Billetera CASCADE;
DROP TABLE G29_ComposicionOrden;
DROP TABLE G29_Mercado CASCADE;
DROP TABLE G29_Moneda CASCADE;
DROP TABLE G29_Movimiento;
DROP TABLE G29_Orden;
DROP TABLE G29_Pais CASCADE;
DROP TABLE G29_RelMoneda;
DROP TABLE G29_Usuario;

---funciones

DROP FUNCTION IF EXISTS trfn_g29_movimientosbloquesconsecutivos();
DROP FUNCTION IF EXISTS fn_g29_listarordenes(mercadop varchar, fecha date) cascade;
DROP FUNCTION IF EXISTS trfn_g29_ejecutarordenmarket();
DROP FUNCTION IF EXISTS trfn_g29_ordensaldosuficiente();
DROP FUNCTION IF EXISTS trfn_g29_retirofondossuficientes();
DROP FUNCTION IF EXISTS trfn_g29_calcular20porciento();
DROP FUNCTION IF EXISTS fn_g29_preciomercado(mercadoo varchar, compra double precision, venta double precision);
DROP FUNCTION IF EXISTS G29_FN_FECHAS_RANDOM();
DROP FUNCTION IF EXISTS G29_FN_MONEDA_RANDOM();
DROP FUNCTION IF EXISTS G29_FN_MERCADO_RANDOM();
DROP FUNCTION IF EXISTS G29_FN_USUARIO_RANDOM();
DROP FUNCTION IF EXISTS G29_FN_TIPO_RANDOM();
DROP FUNCTION IF EXISTS G29_FN_CREAR_ORDENES_RANDOM();


--FUNCIONES TRIGGER Y TRIGGERS

DROP FUNCTION IF EXISTS TRFN_G29_Insert_Billetera() CASCADE;
DROP TRIGGER IF EXISTS TR_G29_Insert_Billetera ON g29_moneda;

DROP FUNCTION IF EXISTS TRFN_G29_Insert_Moneda() CASCADE; -- cascade por que tr_g29_insert_moneda en la tabla g29_moneda depende de esta funcion
DROP TRIGGER IF EXISTS TR_G29_Insert_Moneda ON g29_usuario;


-- End of file.
