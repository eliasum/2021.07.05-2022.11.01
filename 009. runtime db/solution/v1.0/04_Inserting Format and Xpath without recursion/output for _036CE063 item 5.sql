﻿
CREATE TABLE IF NOT EXISTS public."Dictionary"
(
    key integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    "XPath" character varying(200) COLLATE pg_catalog."default",
    "Format" character varying(100) COLLATE pg_catalog."default",
    CONSTRAINT "Dictionary_pkey" PRIMARY KEY (key)
)
  
INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='1']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='2']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='3']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='4']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='5']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='6']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='7']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='8']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='9']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='10']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='11']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='12']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='13']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='14']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='15']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='16']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='17']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='18']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='19']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='20']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='21']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='22']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='23']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='24']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='25']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='26']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='27']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='28']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='29']/Supply/Item[@key='Anode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Photocathode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Photocathode']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate1']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate1']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate12']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate12']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate2']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Microchannelplate2']/Voltage/@format","N0");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Anode']/Amperage/@format","F1");

INSERT INTO public."Dictionary" ("XPath", "Format") 
VALUES ("ControlWorkstation/Equipment/Slot/Item[@key='30']/Supply/Item[@key='Anode']/Voltage/@format","N0");
