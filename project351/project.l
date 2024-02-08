LETTER [a-zA-Z]
DIGIT  [0-9]

%{
	#include <stdio.h>
	#include <string.h>
	#include "y.tab.h"
%}
%%

\+																	    return PLUS;
\-                                                                      return MINUS;
\/                                                                      return DIVIDE;
\*                                                                      return MULTIPLY;
"="                                                                     return EQUAL;
":"                                                                     return COLON;
{LETTER}({LETTER}|{DIGIT}|"_")* {
																		yylval.str=strdup(yytext);
																		return IDENT;
								}
("0"|[1-9]{DIGIT}*)	{
																		yylval.str=strdup(yytext);
																		return INT;
					}
(("0"|[1-9]{DIGIT}*)"."{DIGIT}+|("0"|[1-9]{DIGIT}*)"."|"."{DIGIT}+) {
																		yylval.str=strdup(yytext);
																		return FLOAT;
																	}
\"([#-~]|"\\\""|"!"|" ")*\"	{
																		yylval.str=strdup(yytext);
																		return STRING;
							}
"if "                                                                   return IF;
"elif "                                                                 return ELIF;
"else:"                                                                 return ELSE;
"=="|"!="|"<="|"<"|">="|">" {
																		yylval.str=strdup(yytext);
																		return COMPARISON;
							}
\t|"    "                                                               return TAB;
\n	                                                                    return NEWLINE;
.
%%
