# SELECT_Query_Parser
Write a string parser that will validate a simple select query. The parser should validate the construction
of the query including the column specification, the table specification and WHERE clause conditions.
Table joins or aliasing support is not required. For the columns assume that alternating columns would
be integer or varchar.
For example, from the following query the parser should point out that the WHERE clause in the first
query from below is not correct due to the column an integer. Other queries may have other issues.

SELECT Col1, Col2, Col3, Col4, Col5 FROM TABLE1 WHERE Col1 = ‘100’;
SELECT Col1, Col2, Col3, Col4, Col5 FROM TABLE1 WHERE Col1 >< ‘100’;
SELECT Col1, Col 2, Col3, Col4, Col5 FROM TABLE1 WEHERE Col2 = ‘100’;
SELECT Col1, Col2, Col3, Col4, Col’5 FROM TABLE1 WEHERE Col1 >< ‘100’;

