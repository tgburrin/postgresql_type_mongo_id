#include "postgres.h"
#include "fmgr.h"
#include "utils/bytea.h"
#include "utils/builtins.h"
#include "utils/timestamp.h"

#include <regex.h>
#include <string.h>
#include <time.h>

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1 (mongo_id_in);
PG_FUNCTION_INFO_V1 (mongo_id_ts);
PG_FUNCTION_INFO_V1 (mongo_id_out);

Datum mongo_id_in (PG_FUNCTION_ARGS)
{
    char *id = PG_GETARG_CSTRING(0);
    int sz;
    regex_t expr;

    if ( regcomp(&expr, "[a-fA-F0-9]{24}", REG_EXTENDED|REG_NOSUB) != 0 )
        elog(ERROR, "regular expression could not be compiled");

    if ( regexec(&expr, id, 0, 0, 0) == REG_NOMATCH )
        elog(ERROR, "A valid mongo, 24 hex, must be passed");

    sz = strlen(id) / 2 + VARHDRSZ;
    bytea *result = (bytea *) palloc(sz);
    //elog(NOTICE, "allocated %d bytes for storage", sz);

    hex_decode(id, strlen(id), VARDATA(result));
    SET_VARSIZE(result, sz);

    regfree(&expr);   
    PG_RETURN_BYTEA_P(result);
}

Datum mongo_id_ts (PG_FUNCTION_ARGS)
{
    bytea *vlena = PG_GETARG_BYTEA_PP(0);
    uint64 s = 0;
    pg_time_t seconds = 0;

    memcpy(&s, VARDATA_ANY(vlena), 4);
    seconds = ntohl(s);

    //PG_RETURN_UINT64(seconds);
    PG_RETURN_TIMESTAMPTZ(time_t_to_timestamptz(seconds));
}

Datum mongo_id_out (PG_FUNCTION_ARGS)
{
    bytea *vlena = PG_GETARG_BYTEA_PP(0);
    char *result;

    int msglen = VARSIZE_ANY_EXHDR(vlena) * 2 + 1;
    //elog(NOTICE, "length is %d", msglen);

    result = palloc(msglen);
    memset(result, 0, msglen);

    int sz = hex_encode(VARDATA_ANY(vlena), VARSIZE_ANY_EXHDR(vlena), result);
    //PG_RETURN_TEXT_P(cstring_to_text(result));
    PG_RETURN_CSTRING(result);
}
