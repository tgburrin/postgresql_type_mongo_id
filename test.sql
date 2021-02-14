start transaction;
-- The following would be presentation functions that could be used on a bytea
-- Using a custom type is a more difficult solution to checking and displaying ids

-- create or replace function public.mongo_id_in(mid text)
-- returns bytea
-- LANGUAGE plpgsql
-- IMMUTABLE
-- AS $$
-- BEGIN
--     IF mid ~* '[a-fA-F0-9]{24}' THEN
--         return ('\x'||mid)::bytea;
--     ELSE
--         RAISE EXCEPTION 'Invalid project id submitted';
--     end if;
-- END;
-- $$;
--
-- create or replace function public.mongo_id_out(mid bytea)
-- returns text
-- LANGUAGE plpgsql
-- IMMUTABLE
-- AS $$
-- BEGIN
--     return encode(mid, 'hex')::text;
-- END;
-- $$;

create type public.mongo_id;
create function public.mongo_id_in(cstring) returns mongo_id as 'mongo_data', 'mongo_id_in' LANGUAGE C IMMUTABLE STRICT;
create function public.mongo_id_out(mongo_id) returns cstring as 'mongo_data', 'mongo_id_out' LANGUAGE C IMMUTABLE STRICT;
create function public.mongo_id_ts(mongo_id) returns timestamptz as 'mongo_data', 'mongo_id_ts' LANGUAGE C IMMUTABLE STRICT;

create function public.mongo_id_eq(mongo_id, mongo_id) returns boolean as 'byteaeq' LANGUAGE internal STRICT;
create function public.mongo_id_ne(mongo_id, mongo_id) returns boolean as 'byteane' LANGUAGE internal STRICT;
create function public.mongo_id_lt(mongo_id, mongo_id) returns boolean as 'bytealt' LANGUAGE internal STRICT;
create function public.mongo_id_le(mongo_id, mongo_id) returns boolean as 'byteale' LANGUAGE internal STRICT;
create function public.mongo_id_gt(mongo_id, mongo_id) returns boolean as 'byteagt' LANGUAGE internal STRICT;
create function public.mongo_id_ge(mongo_id, mongo_id) returns boolean as 'byteage' LANGUAGE internal STRICT;
create function public.mongo_id_cmp(mongo_id, mongo_id) returns integer as 'byteacmp' LANGUAGE internal STRICT;

create type public.mongo_id (
    INPUT = public.mongo_id_in,
    OUTPUT = public.mongo_id_out
);

-- create operator = ( leftarg = mongo_id, rightarg = mongo_id, procedure = public.mongo_id_eq, NEGATOR = != );
create operator = ( leftarg = mongo_id, rightarg = mongo_id, procedure = public.mongo_id_eq);
-- create operator != ( leftarg = mongo_id, rightarg = mongo_id, procedure = public.mongo_id_ne, NEGATOR = = );
create operator != ( leftarg = mongo_id, rightarg = mongo_id, procedure = public.mongo_id_ne);
create operator < ( leftarg = mongo_id, rightarg = mongo_id, procedure = public.mongo_id_lt);
create operator <= ( leftarg = mongo_id, rightarg = mongo_id, procedure = public.mongo_id_le);
create operator >= ( leftarg = mongo_id, rightarg = mongo_id, procedure = public.mongo_id_ge);
create operator > ( leftarg = mongo_id, rightarg = mongo_id, procedure = public.mongo_id_gt);

-- Allows for the use of this custom type in btree indexes
-- https://www.cybertec-postgresql.com/en/operator-classes-explained/
create operator class mongo_id_ops
    DEFAULT FOR TYPE mongo_id USING btree as
        OPERATOR    1   < ,
        OPERATOR    2   <= ,
        OPERATOR    3   = ,
        OPERATOR    4   >= ,
        OPERATOR    5   > ,
        FUNCTION    1   public.mongo_id_cmp(mongo_id, mongo_id);

create table test (
    id bigserial not null primary key,
    mid public.mongo_id not null
);

insert into test (mid) values ('0e5fa6a00000000000001234'::public.mongo_id), ('10adb2f80000000000005678'::public.mongo_id), ('0e5fa6a00000000000001234'::public.mongo_id);

create index on test(mid);

select *, public.mongo_id_ts(mid) as ts from test;
select * from test t1 join test t2 on t1.mid = t2.mid and t1.id < t2.id;

rollback;
