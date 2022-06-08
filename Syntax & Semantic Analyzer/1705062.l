%option noyywrap

%x MULTILINECOMMENT

%{
#include<bits/stdc++.h>
 using namespace std;
 
 
#include "symbol_table.h"
#include "y.tab.h"

#define BUCKET_SIZE 30

int error_count=0;
int line_count=1;

extern ofstream logfile;
extern ofstream errorfile;

extern YYSTYPE yylval;
extern SymbolTable symtab;
void yyerror(char *);

void prepSymInfo(string name, string type)
{
    SymbolInfo *s= new SymbolInfo(name,type);
	yylval.si = s;
}


void lexicalError(string s,string s1)
{
    logfile<<"Error at line "<<line_count<<": "<<s+s1<<endl;
    errorfile<<"Error at line "<<line_count<<": "<<s+s1<<endl<<endl;
    error_count++;
}


%}




Alphanumeric [a-zA-Z0-9]
singleQuote ["]
Digit [0-9]
Digits {Digit}+
Character [ -&(-[]|"]"|"^"|[_-~]
Escapeseq \\n|\\t|\\\\|\\\'|\\a|\\f|\\r|\\b|\\v|\\0
Charesc {Character}|{Escapeseq}




%%




[ \t\f\r\v]+ {}

[\n]|"\r\n" { line_count++; }




%keywords

"if" {return IF;}
"for" {return FOR;}
"int" { return INT;}
"float" { return FLOAT;}
"void" {return VOID;}
"else" {return ELSE;}
"while" {return WHILE;}
"return" {return RETURN;}
"printf"  {return PRINTLN;}


%integer_constant

{Digits} { prepSymInfo(yytext,"CONST_INT"); return CONST_INT; }


%floating_point_constant

({Digits}|[.]{Digits}|{Digits}[.]{Digits}?)([eE][-+]?{Digits})?  { prepSymInfo(yytext,"CONST_FLOAT"); return CONST_FLOAT; }



%operator_punctuator

[+-] { 
        prepSymInfo(yytext,"ADDOP");
        return ADDOP; 
	 } 
[*/%] { 
        prepSymInfo(yytext,"MULOP");
        return MULOP; 
	  } 
	  
"++" { return INCOP;}
"--" { return DECOP;}

"<"|"<="|">"|">="|"=="|"!=" { 
        prepSymInfo(yytext,"RELOP");
        return RELOP; 
	  }
"&&"|"||" { 
        prepSymInfo(yytext,"LOGICOP");
        return LOGICOP; 
	  } 
	   
[=] { return ASSIGNOP;}
[!] { return NOT;}
[(] { return LPAREN;}
[)] { return RPAREN;}
[{] { return LCURL;}
[}] { return RCURL;}
"[" { return LTHIRD;}
"]" { return RTHIRD;}
[,] { return COMMA;}
[;] { return SEMICOLON;}




%identifier

[a-zA-Z_]({Alphanumeric}|_)* { 
            prepSymInfo(yytext,"ID");
			return ID; 
		} 
		
		
%comment

"//"[^\n]*((("\\\n")|("\\\r\n"))[^\n]*)* {  }



%muliline_comment

"/*" { BEGIN MULTILINECOMMENT; }

<MULTILINECOMMENT>"*/" { 
                         BEGIN INITIAL;
                       }
                       
<MULTILINECOMMENT>[^a]|[a] {  }



%error

{Digits}?([.]{Digits})([.]{Digits})+([eE][-+]?{Digits}?([.]{Digits})*[.]?)? { 
                lexicalError("Too many decimal points ",yytext); 
                prepSymInfo(yytext,"CONST_FLOAT"); 
                return CONST_FLOAT; 
           }

({Digits}|[.]{Digits}|{Digits}[.]{Digits}?)([eE][-+]?{Digits}?)([.]{Digits})+[.]?  { 
                lexicalError("Ill formed number ",yytext); 
                prepSymInfo(yytext,"CONST_FLOAT"); 
                return CONST_FLOAT; 
           }

[0-9]({Alphanumeric}|_)+  { 
                lexicalError("Invalid prefix on ID or invalid suffix on Number ",yytext); 
                prepSymInfo(yytext,"ID"); 
                return ID;
           }


%%


