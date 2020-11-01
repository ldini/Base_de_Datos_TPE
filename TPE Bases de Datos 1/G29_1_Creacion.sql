-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2020-09-21 21:47:13.678

-- tables
-- Table: G29_Billetera
CREATE TABLE G29_Billetera (
    id_usuario int  NOT NULL,
    moneda varchar(10)  NOT NULL,
    saldo decimal(20,10)  NOT NULL,
    CONSTRAINT PK_G29_Billetera PRIMARY KEY (id_usuario,moneda)
);

-- Table: G29_ComposicionOrden
CREATE TABLE G29_ComposicionOrden (
    id_o int8  NOT NULL,
    id_d int8  NOT NULL,
    cantidad numeric(20,10)  NOT NULL,
    CONSTRAINT PK_G29_ComposicionOrden PRIMARY KEY (id_o,id_d)
);

-- Table: G29_Mercado
CREATE TABLE G29_Mercado (
    nombre varchar(20)  NOT NULL,
    moneda_o varchar(10)  NOT NULL,
    moneda_d varchar(10)  NOT NULL,
    precio_mercado numeric(20,10)  NOT NULL,
    CONSTRAINT PK_G29_Mercado PRIMARY KEY (nombre)
);

-- Table: G29_Moneda
CREATE TABLE G29_Moneda (
    moneda varchar(10)  NOT NULL,
    nombre varchar(80)  NOT NULL,
    descripcion varchar(2048)  NOT NULL,
    alta timestamp  NOT NULL,
    estado char(1)  NOT NULL,
    fiat char(1)  NOT NULL,
    CONSTRAINT PK_G29_Moneda PRIMARY KEY (moneda)
);

-- Table: G29_Movimiento
CREATE TABLE G29_Movimiento (
    id_usuario int  NOT NULL,
    moneda varchar(10)  NOT NULL,
    fecha timestamp  NOT NULL,
    tipo char(1)  NOT NULL,
    comision decimal(20,10)  NOT NULL,
    valor decimal(20,10)  NOT NULL,
    bloque int  NULL,
    direccion varchar(100)  NULL,
    CONSTRAINT PK_G29_Movimiento PRIMARY KEY (id_usuario,moneda,fecha)
);

-- Table: G29_Orden
CREATE TABLE G29_Orden (
    id bigserial  NOT NULL,
    mercado varchar(20)  NOT NULL,
    id_usuario int  NOT NULL,
    tipo char(10)  NOT NULL,
    fecha_creacion timestamp  NOT NULL,
    fecha_ejec timestamp  NULL,
    valor decimal(20,10)  NOT NULL,
    cantidad decimal(20,10)  NOT NULL,
    estado char(10)  NOT NULL,
    CONSTRAINT PK_G29_Orden PRIMARY KEY (id)
);

-- Table: G29_Pais
CREATE TABLE G29_Pais (
    id_pais int  NOT NULL,
    nombre varchar(40)  NOT NULL,
    cod_telef int  NOT NULL,
    CONSTRAINT PK_G29_Pais PRIMARY KEY (id_pais)
);

-- Table: G29_RelMoneda
CREATE TABLE G29_RelMoneda (
    moneda varchar(10)  NOT NULL,
    monedaf varchar(10)  NOT NULL,
    fecha timestamp  NOT NULL,
    valor numeric(20,10)  NOT NULL,
    CONSTRAINT PK_G29_RelMoneda PRIMARY KEY (moneda,monedaf,fecha)
);

-- Table: G29_Usuario
CREATE TABLE G29_Usuario (
    id_usuario int  NOT NULL,
    apellido varchar(40)  NOT NULL,
    nombre varchar(40)  NOT NULL,
    fecha_alta date  NOT NULL,
    estado char(10)  NOT NULL,
    email varchar(120)  NOT NULL,
    password varchar(120)  NOT NULL,
    telefono int  NOT NULL,
    id_pais int  NOT NULL,
    CONSTRAINT PK_G29_Usuario PRIMARY KEY (id_usuario)
);

-- foreign keys
-- Reference: FK_G29_Billetera_Moneda (table: G29_Billetera)
ALTER TABLE G29_Billetera ADD CONSTRAINT FK_G29_Billetera_Moneda
    FOREIGN KEY (moneda)
    REFERENCES G29_Moneda (moneda)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_Billetera_Usuario (table: G29_Billetera)
ALTER TABLE G29_Billetera ADD CONSTRAINT FK_G29_Billetera_Usuario
    FOREIGN KEY (id_usuario)
    REFERENCES G29_Usuario (id_usuario)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_CompOp_Op_d (table: G29_ComposicionOrden)
ALTER TABLE G29_ComposicionOrden ADD CONSTRAINT FK_G29_CompOp_Op_d
    FOREIGN KEY (id_d)
    REFERENCES G29_Orden (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_CompOp_Op_o (table: G29_ComposicionOrden)
ALTER TABLE G29_ComposicionOrden ADD CONSTRAINT FK_G29_CompOp_Op_o
    FOREIGN KEY (id_o)
    REFERENCES G29_Orden (id)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_Movimiento_Billetera (table: G29_Movimiento)
ALTER TABLE G29_Movimiento ADD CONSTRAINT FK_G29_Movimiento_Billetera
    FOREIGN KEY (id_usuario, moneda)
    REFERENCES G29_Billetera (id_usuario, moneda)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_Operacion_Mercado (table: G29_Orden)
ALTER TABLE G29_Orden ADD CONSTRAINT FK_G29_Operacion_Mercado
    FOREIGN KEY (mercado)
    REFERENCES G29_Mercado (nombre)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_Operacion_Usuario (table: G29_Orden)
ALTER TABLE G29_Orden ADD CONSTRAINT FK_G29_Operacion_Usuario
    FOREIGN KEY (id_usuario)
    REFERENCES G29_Usuario (id_usuario)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_RelMoneda_Moneda (table: G29_RelMoneda)
ALTER TABLE G29_RelMoneda ADD CONSTRAINT FK_G29_RelMoneda_Moneda
    FOREIGN KEY (monedaf)
    REFERENCES G29_Moneda (moneda)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_RelMoneda_Monedaf (table: G29_RelMoneda)
ALTER TABLE G29_RelMoneda ADD CONSTRAINT FK_G29_RelMoneda_Monedaf
    FOREIGN KEY (moneda)
    REFERENCES G29_Moneda (moneda)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_Usuario_Pais (table: G29_Usuario)
ALTER TABLE G29_Usuario ADD CONSTRAINT FK_G29_Usuario_Pais
    FOREIGN KEY (id_pais)
    REFERENCES G29_Pais (id_pais)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_mercado_moneda_d (table: G29_Mercado)
ALTER TABLE G29_Mercado ADD CONSTRAINT FK_G29_mercado_moneda_d
    FOREIGN KEY (moneda_d)
    REFERENCES G29_Moneda (moneda)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_G29_mercado_moneda_o (table: G29_Mercado)
ALTER TABLE G29_Mercado ADD CONSTRAINT FK_G29_mercado_moneda_o
    FOREIGN KEY (moneda_o)
    REFERENCES G29_Moneda (moneda)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- End of file.

