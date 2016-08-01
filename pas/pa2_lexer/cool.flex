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

int comment_depth;
int string_length = 0;

bool strTooLong();
void resetStr();
int strLenErr();
void addToStr(char* str);

%}

 /* (2) DEFINITIONS
  * ======================================================================== 
  */

DARROW        =>
ASSIGN        <-
LE            <=
OTHER_SN      [{};:,\.()<=\+\-~@\*/]
NUMBER          [0-9]
ALPHANUMERIC    [a-zA-Z0-9_]

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

%x COMMENT
%x STRING
%x BROKENSTRING



 /* (3) RULES
  * ======================================================================== 
  */

%%

 /*
  *  Nested comments. We're using example from:
  *  http://flex.sourceforge.net/manual/Start-Conditions.html
  */

<INITIAL,COMMENT>"(*"                    { 
                          comment_depth++;
                          BEGIN(COMMENT); 
                        }
 /* eat up everything except newline */
<COMMENT>.              { }
<COMMENT>\n             { curr_lineno++; }
<COMMENT>"*)"           { 
                          comment_depth--;
                          if (comment_depth == 0) {
                            BEGIN(INITIAL); 
                          }
                        }
<COMMENT><<EOF>>        {   
                          BEGIN(INITIAL);
                          cool_yylval.error_msg = "EOF in comment";
                          return ERROR;
                        }
<INITIAL>"*)"           { 
                          cool_yylval.error_msg = "unmatched *)";
                          return ERROR;
                        } 

  /* discard comments */
"--".*\n                { curr_lineno++; }  
"--".*                  { curr_lineno++; }  


 /*
  *  The multiple-character operators.
  */
{DARROW}    { return DARROW; }
{ASSIGN}    { return ASSIGN; }
{LE}        { return LE; }
{OTHER_SN}  { return (char)*yytext; }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter 
  * (Manual, 10.4).
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
  * Identifiers are strings (other than keywords) consisting 
  * of letters, digits, and the underscore character. 
  * Type identifiers begin with a capital letter; 
  * object identifiers begin with a lower case letter.
  */ 

{NUMBER}+               {
                          cool_yylval.symbol = inttable.add_string(yytext);
                          return (INT_CONST);
                        }

[A-Z]{ALPHANUMERIC}*    {
                          cool_yylval.symbol = idtable.add_string(yytext);
                          return(TYPEID);
                        }

[a-z]{ALPHANUMERIC}*    {
                          cool_yylval.symbol = idtable.add_string(yytext);
                          return(OBJECTID);
                        }
 

 /*
  *  String constants (C syntax)
  *  (1) Strings are enclosed in double quotes "...".
  *  (2) Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *  (3) A non-escaped newline character may not appear in a string.
  *  (4) A string may not contain EOF. 
  *  (5) A string may not contain the null (character \0). 
  *  (Manual, 10.2)
  */

\"            { 
                    // "starting tag
                    BEGIN(STRING);
                }
<STRING>\"    { 
                    // Closing tag"
                    cool_yylval.symbol = stringtable.add_string(string_buf);
                    resetStr();
                    BEGIN(INITIAL);
                    return(STR_CONST);
                }
<STRING>(\0|\\\0) {
                      cool_yylval.error_msg = "String contains null character";
                      BEGIN(BROKENSTRING);
                      return(ERROR);
                }
<BROKENSTRING>.*[\"\n] {
                    //"//Get to the end of broken string
                    BEGIN(INITIAL);
                }
<STRING>\\\n      {   
                    // escaped slash
                    // printf("captured: %s\n", yytext);
                    if (strTooLong()) { return strLenErr(); }
                    curr_lineno++; 
                    addToStr("\n");
                    string_length++;
                    // printf("buffer: %s\n", string_buf);
                }
<STRING>\n      {   
                    // unescaped new line
                    curr_lineno++; 
                    BEGIN(INITIAL);
                    resetStr();
                    cool_yylval.error_msg = "Unterminated string constant";
                    return(ERROR);
                }

<STRING><<EOF>> {   
                    BEGIN(INITIAL);
                    cool_yylval.error_msg = "EOF in string constant";
                    return(ERROR);
                }

<STRING>\\n      {  // escaped slash, then an n
                    if (strTooLong()) { return strLenErr(); }
                    curr_lineno++; 
                    addToStr("\n");
                }

<STRING>\\t     {
                    if (strTooLong()) { return strLenErr(); }
                    string_length++;
                    addToStr("\t");
}
<STRING>\\b     {
                    if (strTooLong()) { return strLenErr(); }
                    string_length++;
                    addToStr("\b");
}
<STRING>\\f     {
                    if (strTooLong()) { return strLenErr(); }
                    string_length++;
                    addToStr("\f");
}
<STRING>\\.     {
                    //escaped character, just add the character
                    if (strTooLong()) { return strLenErr(); }
                    string_length++;
                    addToStr(&strdup(yytext)[1]);
                }
<STRING>.       {   
                    if (strTooLong()) { return strLenErr(); }
                    addToStr(yytext);
                    string_length++;
                }

 /*
  *  Catching all the rest including whitespace
  *
  */

 /* catch empty lines */
\n          { curr_lineno++; }

 /* catch white space */
[ \r\t\v\f] { }

 /* everything else is an error */

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

bool strTooLong() {
  if (string_length + 1 >= MAX_STR_CONST) {
      BEGIN(BROKENSTRING);
      return true;
    }
    return false;
}

void resetStr() {
    string_length = 0;
    string_buf[0] = '\0';
}

int strLenErr() {
  resetStr();
    cool_yylval.error_msg = "String constant too long";
    return ERROR;
}















