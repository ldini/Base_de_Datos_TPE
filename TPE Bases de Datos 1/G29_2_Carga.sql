
INSERT INTO "g29_pais" (id_pais, nombre, cod_telef)
VALUES  (55254,'Argentina',54),
        (53168,'Uruguay',34),
        (697869,'Paraguay',32),
        (74294,'Estados Unidos',123),
        (31705,'Chile',43),
        (4656,'Dinamarca',36),
        (5906,'Holanda',14);

INSERT INTO "g29_usuario" (id_usuario,apellido,nombre,fecha_alta,estado,email,password,telefono,id_pais)
VALUES (200,'Cahan','Aian','05-06-2014','Nueva','aliquet.Phalus@erasemper.net','MTH66T1WM','111981','55254'),
       (201,'eeves','Vanna','12-05-2016','Cumplida','Sedid@Nam.co.uk','BWE8AID1TA','230460','53168'),
       (202,'rry','Isabella','08-07-2017','Nueva','ltus@ligula.net','LQH2TGW8XM','15825','697869'),
       (203,'Tyle','Amity','07-10-2019','Cumplida','massa.rum.magna@mollisDuis.net','YVO19MH7HW','017499','74294'),
       (204,'Christ','Stone','12-09-2018','Nueva','urna@stasrhoncus.com','LMQ44ZV6AB','013059','697869'),
       (205,'Frederk','Cullen','02-10-2019','Nueva','rius.odio.aucor@Donecluctus.org','GU93PBU4YC','084642','31705'),
       (206,'Oln','Chava','09-07-2021','Cumplida','arcu@miAliquaravida.org','WGM60BE4LX','0112392','4656'),
       (207,'Canon','Lillian','09-10-2010','Nueva','sed.dui@posecubiliaCurae.com','COB0XRA7ZY','554745','697869'),
       (208,'Hains','Lacy','02-01-2011','Cumplida','fringil@risus.org','LWY67QT8YD','20277','55254'),
       (209,'well','Mage','06-10-2019','Nueva','magnis.dis@msanon.edu','SIP15DU4CL','67145','55254');

-- EL USUARIO DEBE TENER UNA BILLETERA POR CADA MONEDA EXISTENTE
CREATE OR REPLACE FUNCTION TRFN_G29_Insert_Billetera()
RETURNS TRIGGER AS
$$
DECLARE
    reg RECORD;
BEGIN
    FOR reg IN (SELECT moneda FROM g29_moneda)
    LOOP
        INSERT INTO g29_billetera(id_usuario, moneda, saldo)
        VALUES (new.id_usuario,reg.moneda,0);
    END LOOP;
    RETURN new;
END
 $$ LANGUAGE 'plpgsql';

CREATE TRIGGER TR_G29_Insert_Billetera
AFTER INSERT ON g29_usuario
FOR EACH ROW
EXECUTE PROCEDURE TRFN_G29_Insert_Billetera();




INSERT INTO "g29_moneda" (moneda,nombre,descripcion,alta,estado,fiat)
 VALUES
  --Cripto moneda
  ('BTC','Bitcoin','none','03-02-2020','N','N'),
  ('ETH','Ethereum','none','03-02-2002','C','N'),
  ('XRP','Ripple','none','03-02-2010','N','N'),
  ('LTC','Litecoin','none','03-02-2020','C','N'),
  ('TRX','TRON','none','03-02-2020','C','N'),
  ('XLM','Stellar','none','03-02-2011','N','N'),
  ('ACA','Acash Coin','none','03-02-2020','N','N'),
  ('MKR','Maker','none','03-02-2000','C','N'),
  ('THETA','THETA','none','03-02-2002','N','N'),

  --Moneda Estable
  ('USDT','Tether','none','03-02-2020','N','N'),
  ('DAI','Dai','none','03-02-2020','N','N'),
  ('BTC/JPY','bitFlyer','vinculada a Yeb','03-02-2020','C','N'),
  ('TER','Terra','none','03-02-2020','N','N'),
  ('CARBON','Carboncoin','','03-02-2020','C','N'),

   -- Moneda Fiat
  ('USD','Dolar','none','03-02-2020','N','Y'),
  ('EUR','Euro','none','03-02-2020','N','Y'),
  ('JPY','Yen','none','03-02-2020','C','Y'),
  ('PEN','Sol Peruano','none','03-02-2020','C','Y'),
  ('MXN','Peso Mexicano','none','03-02-2020','C','Y'),
  ('ARS','Peso Argentino','none','03-02-2020','N','Y');


CREATE OR REPLACE FUNCTION TRFN_G29_Insert_Moneda()
RETURNS TRIGGER AS
$$
DECLARE
    reg RECORD;
BEGIN
    FOR reg IN (SELECT id_usuario FROM g29_usuario)
    LOOP
        INSERT INTO g29_billetera(id_usuario, moneda, saldo)
        VALUES (reg.id_usuario,new.moneda,0);
    END LOOP;
    RETURN new;
END
 $$ LANGUAGE 'plpgsql';

CREATE TRIGGER TR_G29_Insert_Moneda
AFTER INSERT OR UPDATE ON g29_moneda
FOR EACH ROW
EXECUTE PROCEDURE TRFN_G29_Insert_Moneda();




INSERT INTO "g29_mercado" (nombre,moneda_o,moneda_d,precio_mercado)
VALUES ('Mercado 1','USDT','BTC',826047.54),
       ('Mercado 2','USDT','ETH',297.15),
       ('Mercado 3','USDT','XRP',	0.248879),
       ('Mercado 4','USDT','LTC',3566.03),
       ('Mercado 5','USDT','TRX',0.026081),
       ('Mercado 6','USDT','XLM',	0.07286),
       ('Mercado 7','USDT','ACA',0.0034),
       ('Mercado 8','USDT','MKR',	547.64),
       ('Mercado 9','USDT','THETA',0.755019);

INSERT INTO "g29_mercado" (nombre,moneda_o,moneda_d,precio_mercado)
VALUES ('Mercado 11','DAI','BTC',826047.54),
       ('Mercado 12','DAI','ETH',297.15),
       ('Mercado 13','DAI','XRP',	0.248879),
       ('Mercado 14','DAI','LTC',3566.03),
       ('Mercado 15','DAI','TRX',0.026081),
       ('Mercado 16','DAI','XLM',	0.07286),
       ('Mercado 17','DAI','ACA',0.0034),
       ('Mercado 18','DAI','MKR',	547.64),
       ('Mercado 19','DAI','THETA',0.755019);

INSERT INTO "g29_mercado" (nombre,moneda_o,moneda_d,precio_mercado)
VALUES ('Mercado 21','BTC/JPY','BTC',826047.54),
       ('Mercado 22','BTC/JPY','ETH',297.15),
       ('Mercado 23','BTC/JPY','XRP',	0.248879),
       ('Mercado 24','BTC/JPY','LTC',3566.03),
       ('Mercado 25','BTC/JPY','TRX',0.026081),
       ('Mercado 26','BTC/JPY','XLM',	0.07286),
       ('Mercado 27','BTC/JPY','ACA',0.0034),
       ('Mercado 28','BTC/JPY','MKR',	547.64),
       ('Mercado 29','BTC/JPY','THETA',0.755019);

INSERT INTO "g29_mercado" (nombre,moneda_o,moneda_d,precio_mercado)
VALUES ('Mercado 31','TER','BTC',826047.54),
       ('Mercado 32','TER','ETH',297.15),
       ('Mercado 33','TER','XRP',	0.248879),
       ('Mercado 34','TER','LTC',3566.03),
       ('Mercado 35','TER','TRX',0.026081),
       ('Mercado 36','TER','XLM',	0.07286),
       ('Mercado 37','TER','ACA',0.0034),
       ('Mercado 38','TER','MKR',	547.64),
       ('Mercado 39','TER','THETA',0.755019);

INSERT INTO "g29_mercado" (nombre,moneda_o,moneda_d,precio_mercado)
VALUES ('Mercado 41','CARBON','BTC',826047.54),
       ('Mercado 42','CARBON','ETH',297.15),
       ('Mercado 43','CARBON','XRP',	0.248879),
       ('Mercado 44','CARBON','LTC',3566.03),
       ('Mercado 45','CARBON','TRX',0.026081),
       ('Mercado 46','CARBON','XLM',	0.07286),
       ('Mercado 47','CARBON','ACA',0.0034),
       ('Mercado 48','CARBON','MKR',	547.64),
       ('Mercado 49','CARBON','THETA',0.755019);

INSERT INTO "g29_mercado" (nombre,moneda_o,moneda_d,precio_mercado)
VALUES ('Mercado 51','BTC','BTC',826047.54),
       ('Mercado 52','BTC','ETH',297.15),
       ('Mercado 53','BTC','XRP',	0.248879),
       ('Mercado 54','BTC','LTC',3566.03),
       ('Mercado 55','BTC','TRX',0.026081),
       ('Mercado 56','BTC','XLM',	0.07286),
       ('Mercado 57','BTC','ACA',0.0034),
       ('Mercado 58','BTC','MKR',	547.64),
       ('Mercado 59','BTC','THETA',0.755019);




--Funciones NECESARIAS PARA AUTO CARGAR ORDENES

 CREATE OR REPLACE FUNCTION G29_FN_FECHAS_RANDOM(desde timestamp, hasta timestamp) returns timestamp as $$
 BEGIN
     RETURN desde + random() * (hasta - desde);
 END;
 $$ language plpgsql;

 CREATE OR REPLACE FUNCTION G29_FN_MONEDA_RANDOM() returns varchar as $$
 BEGIN
     RETURN (SELECT nombre FROM g29_moneda OFFSET floor(random()*(SELECT count(*) FROM g29_moneda )) LIMIT 1);
 END;
 $$ language plpgsql;

 CREATE OR REPLACE FUNCTION G29_FN_MERCADO_RANDOM() returns varchar as $$
 BEGIN
     RETURN (SELECT nombre FROM g29_mercado OFFSET floor(random()*(SELECT count(*) FROM g29_mercado )) LIMIT 1);
 END;
 $$ language plpgsql;

 CREATE OR REPLACE FUNCTION G29_FN_USUARIO_RANDOM() returns int as $$
 BEGIN
     RETURN (SELECT id_usuario FROM g29_usuario OFFSET floor(random()*(SELECT count(*) FROM g29_usuario)) LIMIT 1);
 END;
 $$ language plpgsql;

 CREATE OR REPLACE FUNCTION G29_FN_TIPO_RANDOM() returns varchar as $$
 DECLARE
     tipo varchar;
 BEGIN
     IF (SELECT ROUND(RANDOM() * 1) = 1) THEN
         tipo = 'ACTIVA';
     ELSE
         tipo = 'INACTIVA';
     END IF;
     RETURN tipo;
 END;
 $$ language plpgsql;

 --ESTE PROCEDIMIENTO CREA 100 FILAS EN LA TABLA ORDEN

 do $$
 declare
     i integer;
 begin
     i := 1;
     loop
         exit when i = 101;
         insert into g29_orden(mercado, id_usuario, tipo, fecha_creacion, fecha_ejec, valor, cantidad, estado) VALUES
         (G29_FN_MERCADO_RANDOM(),
          G29_FN_USUARIO_RANDOM(),
          G29_FN_TIPO_RANDOM(),
          G29_FN_FECHAS_RANDOM('2000-01-01 00:00:00','2010-01-01 00:00:00'),
          G29_FN_FECHAS_RANDOM('2010-01-01 00:00:00','2020-01-01 00:00:00'),
          round(random()*1000),
          round(random()*1000),
          G29_FN_TIPO_RANDOM());
         i := i + 1;
     end loop;
 end;
 $$ language plpgsql;

-- FIN DE ORDEN
-- TODO: AGREGAR BILLETERAS (CADA USUARIO TIENE UNA POR MONEDA, O SEA 20 BILLETERAS POR USUARIO)
-- TODO : INSERTAR MOVIMIENTOS PARA HACER PRUEBAS


-- INSERT INTO g29_billetera values (105,'USD',0);
--
--
-- INSERT INTO g29_movimiento values (100,'USD','2000-01-01 00:00:00','s',0.5,100,200,2336784);
-- INSERT INTO g29_movimiento values (101,'USD','2003-01-01 00:00:00','s',0.5, 190,100,2336784);
-- INSERT INTO g29_movimiento values (102,'USD','2004-01-01 00:00:00','s',0.5, 100,2336784);
-- INSERT INTO g29_movimiento values (103,'USD',current_date,'s',0.5, 200,2336784);
-- INSERT INTO g29_movimiento values (104,'USD',current_date,'s',0.5,200,21,2336784);


INSERT INTO g29_orden values (123456,'Mercado 1',100,'COMPRA', current_date,NULL,10000, 20000,'ACTIVA');
-- INSERT INTO g29_orden values (123457,'Mercado 1',100,'VENTA', current_date,NULL,10000, 2000,'ACTIVA');
-- INSERT INTO g29_orden values (123466,'Mercado 1',100,'VENTA', current_date,NULL,10000, 2000,'ACTIVA');
--
-- INSERT INTO g29_orden values (1234466,'Mercado 1',102,'VENTA', current_date,NULL,10000, 20000,'ACTIVA');
-- INSERT INTO g29_orden values (12344566,'Mercado 1',102,'COMPRA', current_date,NULL,10000, 20000,'ACTIVA');


--LLAMADO A TABLAS
--SELECT * FROM g29_pais;
SELECT * FROM g29_usuario;
SELECT * FROM g29_moneda;
--SELECT  * FROM g29_mercado;
--SELECT * FROM g29_orden;
SELECT * FROM g29_billetera;



