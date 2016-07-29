/*
 *  The scanner definition for COOL.
 */


/* (1) DECLARATIONS
 * ======================================================================== 
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int string_length = 0;

void addToStr(char* str);
void resetStr();

%}

/* (2) DEFINITIONS
 * ======================================================================== 
 */

DARROW        =>

/*  
 * (?i:) - case insensitive regex.
 * (?i:ab7)        same as  ([aA][bB]7)
 * see here: http://flex.sourceforge.net/manual/Patterns.html
 * List of keywords is from Manual, 10.4
 */

CLASS         (?i:class)
ELSE          (?i:else)
FALSE         f(?i:alse)
FI            (?i:fi)
IF            (?i:if)
IN            (?i:in)
INHERITS      (?i:inherits)
ISVOID        (?i:isvoid)
LET           (?i:let)
LOOP          (?i:loop)
POOL          (?i:pool)
THEN          (?i:then)
WHILE         (?i:while)
CASE          (?i:case)
ESAC          (?i:esac)
NEW           (?i:new)
OF            (?i:of)
NOT           (?i:not)
TRUE          t(?i:rue)

/*
 * start conditions
 */

%x STRING
%x COMMENT


/* (3) RULES
 * ======================================================================== 
 */

%%

 /*
  *  Nested comments
  */

"(*".*          { curr_lineno++; }
"--".*\n        { curr_lineno++; }  
"--".*          { curr_lineno++; }  


 /*
  *  The multiple-character operators.
  */
{DARROW}    { return (DARROW); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter (Manual, 10.4).
  */

{CLASS}       { return CLASS; }
{ELSE}        { return ELSE; }
{FALSE}       { 
                cool_yylval.boolean = false;
                return(BOOL_CONST);
              }
{FI}          { return FI; }
{IF}          { return IF; }
{IN}          { return IN; }
{INHERITS}    { return INHERITS; }
{LET}         { return LET; }
{LOOP}        { return LOOP; }
{POOL}        { return POOL; }
{THEN}        { return THEN; }
{WHILE}       { return WHILE; }
{CASE}        { return CASE; }
{ESAC}        { return ESAC; }
{OF}          { return OF; }
{NEW}         { return NEW; }
{ISVOID}      { return ISVOID; }
{NOT}         { return NOT; }
{TRUE}        {
                cool_yylval.boolean = true;
                return(BOOL_CONST);
              }


 /*
  *  String constants (C syntax)
  *  (1) Strings are enclosed in double quotes "...".
  *  (2) Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *  (3) A non-escaped newline character may not appear in a string.
  *  (4) A string may not contain EOF. 
  *  (5) A string may not contain the null (character \0).
  *
  */

\"            { 
                    // opening tag "
                    BEGIN(STRING);
              }
<STRING>\"    { 
                    // closing tag "
                    cool_yylval.symbol = stringtable.add_string(string_buf);
                    resetStr();
                    BEGIN(INITIAL);
                    return(STR_CONST);
              }
<STRING>.     {   
                    addToStr(yytext);
                    string_length++;
              }




\n          { curr_lineno++; }

[ \r\t\v\f] { }

.           {
              cool_yylval.error_msg = yytext;
              return(ERROR);
            }


%%

/* (4) USER SUBROUTINES
 * ======================================================================== 
 */

void addToStr(char* str) {
    strcat(string_buf, str);
}

void resetStr() {
    string_length = 0;
    string_buf[0] = '\0';
}















