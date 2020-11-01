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
DROP TABLE G29_Billetera;

DROP TABLE G29_ComposicionOrden;

DROP TABLE G29_Mercado;

DROP TABLE G29_Moneda;

DROP TABLE G29_Movimiento;

DROP TABLE G29_Orden;

DROP TABLE G29_Pais;

DROP TABLE G29_RelMoneda;

DROP TABLE G29_Usuario;

-- End of file.
