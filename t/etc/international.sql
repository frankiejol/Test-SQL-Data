/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE "foo" (
  "cod_asig" int(11) NOT NULL DEFAULT '0',
  "cod_plan" int(11) NOT NULL DEFAULT '0',
  "num_ordre" int(11) DEFAULT NULL,
  "tipus" char(7) DEFAULT NULL,
  "curs" char(10) DEFAULT NULL,
  "nom" char(120) DEFAULT NULL,
  "abrev" char(8) DEFAULT NULL,
  "cod_depart" char(3) DEFAULT NULL,
  "cred_teo" double DEFAULT NULL,
  "cred_lab" double DEFAULT NULL,
  "cred_apl" double DEFAULT NULL,
  "cred_tot" double DEFAULT NULL,
  "actiu" char(1) DEFAULT NULL,
  "abrev_examens" char(20) DEFAULT NULL,
  "name" char(120) DEFAULT NULL,
  "nombre" char(120) DEFAULT NULL,
  "idRegim" int(11) DEFAULT NULL,
  "idIdioma" int(11) DEFAULT NULL,
  "especialitat" char(1) DEFAULT NULL,
  "imparticio" char(1) DEFAULT 'A',
  "a2" char(1) DEFAULT 'S'
);
/*!40101 SET character_set_client = @saved_cs_client */;
INSERT INTO "foo" VALUES (9003,1,6013,'Q0','0','Fonaments d''Electrònica',NULL,'710',2.25,0.75,0,3,'N','Fon Electr',NULL,'Fundamentos de Electronica',1,3,'Q','T','N');
INSERT INTO "foo" VALUES (9004,1,6010,'Q0','0','Ciència i Mètode',NULL,'230',3,0,0,3,'N','Cienc Met',NULL,'Ciencia y Método',1,3,'Q','T','N');
