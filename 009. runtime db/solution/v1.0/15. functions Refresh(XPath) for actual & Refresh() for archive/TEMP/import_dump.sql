--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 13.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: opt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.opt (
    id integer NOT NULL,
    "Масса" character varying(100),
    "Объем" character varying(100)
);


ALTER TABLE public.opt OWNER TO postgres;

--
-- Name: table_glossary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.table_glossary (
    key integer NOT NULL,
    configuration text NOT NULL,
    communication text,
    allowance double precision NOT NULL,
    tablename character(15) NOT NULL
);


ALTER TABLE public.table_glossary OWNER TO postgres;

--
-- Name: table_glossary_key_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.table_glossary ALTER COLUMN key ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.table_glossary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: opt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.opt (id, "Масса", "Объем") FROM stdin;
\.


--
-- Data for Name: table_glossary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.table_glossary (key, configuration, communication, allowance, tablename) FROM stdin;
\.


--
-- Name: table_glossary_key_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.table_glossary_key_seq', 1, false);


--
-- Name: table_glossary glossary_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.table_glossary
    ADD CONSTRAINT glossary_key PRIMARY KEY (key);


--
-- Name: opt table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.opt
    ADD CONSTRAINT table_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

