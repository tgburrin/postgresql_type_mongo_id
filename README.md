## A custom postgres datatype for storing mongo ids
The project here is a result of attempting to store mongo ids as bytea and attempting to use a custom type to make presentation easier.

### Layout
mongo_data.c contains the functions needed to take in and output a 24 character hex mongo object id.  This is built using the shell script.  The test.sql is a sample script setting up the type, adding the appropriate operators, and testing the type.  All of the test is subsequently rolled back and does not persist anything in the database.

