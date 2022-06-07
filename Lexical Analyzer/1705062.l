%option noyywrap

%x MULTILINECOMMENT

%{

#include "symbol_table.h"
#define BUCKET_SIZE 7

int error_count=0;
int line_count=1;

SymbolTable symtab(BUCKET_SIZE);

string multicomment="/*";


void tableInsert(string key, string value)
{
    bool flag=symtab.Insert(key,value);
    if(flag) symtab.printAllScopeTable();
    else logfile<<key<<" already exists in current ScopeTable"<<endl<<endl;
}


void keyword(string s)
{
    string S=s;
    transform(S.begin(), S.end(), S.begin(), ::toupper);
    tokenfile<<"<"<<S<<"> ";
    logfile<<"Line no "<<line_count<<": Token <"<<S<<"> Lexeme "<<s<<" found"<<endl<<endl;
}


void op_punc(string type,string symbol)
{
    tokenfile<<"<"<<type<<", "<<symbol<<"> ";
    logfile<<"Line no "<<line_count<<": Token <"<<type<<"> Lexeme "<<symbol<<" found"<<endl<<endl;
}


void integer_literal(string intgr)
{
    tokenfile<<"<CONST_INT, "<<intgr<<"> ";
    logfile<<"Line no "<<line_count<<": Token <CONST_INT> Lexeme "<<intgr<<" found"<<endl<<endl;
    tableInsert(intgr,"CONST_INT");
}


void floating_literal(string flt)
{
    tokenfile<<"<CONST_FLOAT, "<<flt<<"> ";
    logfile<<"Line no "<<line_count<<": Token <CONST_FLOAT> Lexeme "<<flt<<" found"<<endl<<endl;
    tableInsert(flt,"CONST_FLOAT");
}


void character_literal(string ch)
{
    char c=ch[1];
    tokenfile<<"<CONST_CHAR, "<<c<<"> ";
    logfile<<"Line no "<<line_count<<": Token <CONST_CHAR> Lexeme "<<ch<<" found --> <CONST_CHAR, "<<c<<">"<<endl<<endl;
    tableInsert(ch,"CONST_CHAR");
}


char getCharFromEsc(string ch)
{
    if(ch=="\'\\n\'") return '\n';
    else if(ch=="\'\\t\'") return '\t';
    else if(ch=="\'\\\\\'") return '\\';
    else if(ch=="\'\\\'\'") return '\'';
    else if(ch=="\'\\a\'") return '\a';
    else if(ch=="\'\\f\'") return '\f';
    else if(ch=="\'\\r\'") return '\r';
    else if(ch=="\'\\b\'") return '\b';
    else if(ch=="\'\\v\'") return '\v';
    //else if(ch=="\'\\0\'") return '\0';
    else return '\n'; //printing newline for '\0' because printing '\0' corrupts the output file.
}


void escape_sequence(string ch)
{
    char c=getCharFromEsc(ch);
    
    tokenfile<<"<CONST_CHAR, "<<c<<"> ";
    logfile<<"Line no "<<line_count<<": Token <CONST_CHAR> Lexeme "<<ch<<" found --> <CONST_CHAR, "<<c<<">"<<endl<<endl;
    tableInsert(ch,"CONST_CHAR");
}


void unknown_escape_sequence(string ch)
{
    char c=ch[2];
    
    tokenfile<<"<CONST_CHAR, "<<c<<"> ";
    logfile<<"Line no "<<line_count<<": Token <CONST_CHAR> Lexeme "<<ch<<" found --> <CONST_CHAR, "<<c<<">"<<endl<<endl;
    tableInsert(ch,"CONST_CHAR");
}


void identifier(string id)
{
    tokenfile<<"<ID, "<<id<<"> ";
    logfile<<"Line no "<<line_count<<": Token <ID> Lexeme "<<id<<" found"<<endl<<endl;
    tableInsert(id,"ID");
}


void string_object(string str)
{
    //str is the matched lexeme to be printed in logfile
    //strsymbol is the symbol that goes with token
    
    string strsymbol=str;
    int l=str.length(),j=0,string_line=0;;
    
    for(int i=0;i<l;i++)
    {
        if(str[i]=='\\')
        {
            //multi-line string goes to new line; case: \n
            if(str[i+1]=='\n') 
            {
                j--;
                string_line++;
            }
            //multi-line string goes to new line; case: \r\n
            else if(str[i+1]=='\r' && str[i+2]=='\n') 
            {
                j--;
                i++;
                string_line++;
            }
            //escape character
            else if(str[i+1]=='n') strsymbol[j]='\n';
            else if(str[i+1]=='t') strsymbol[j]='\t'; 
            else if(str[i+1]=='a') strsymbol[j]='\a';
            else if(str[i+1]=='f') strsymbol[j]='\f';
            else if(str[i+1]=='r') strsymbol[j]='\r';
            else if(str[i+1]=='b') strsymbol[j]='\b';
            else if(str[i+1]=='v') strsymbol[j]='\v';
            else if(str[i+1]=='0') strsymbol[j]='\n';
            // \\,\' and unescapable characters; print whatever's after them
            else strsymbol[j]=str[i+1];
            
            j++;
            i++;
        }
        else
        {
            strsymbol[j]=str[i];
            j++;
        }
    }
    strsymbol=strsymbol.substr(0,j);
    
    tokenfile<<"<STRING, "<<strsymbol<<"> ";
    logfile<<"Line no "<<line_count<<": Token <STRING> Lexeme "<<str<<" found --> <STRING, "<<strsymbol<<">"<<endl<<endl;
    
    line_count += string_line;
    
}



void comment(string cmnt)
{
    int l=cmnt.length(),comment_line=0;
    if(cmnt[l-1]=='\r') cmnt=cmnt.substr(0,l-1);
    
    l=cmnt.length();
    for(int i=0;i<l;i++)
    {
        if(cmnt[i]=='\n')
        {
            comment_line++;
        }
    }
    
    logfile<<"Line no "<<line_count<<": Token <COMMENT> Lexeme "<<cmnt<<" found"<<endl<<endl;
    
    line_count += comment_line;
    
}


void error(string errortype, string lexeme)
{
    int l=lexeme.length(),error_line=0;
    if(lexeme[l-1]=='\r') lexeme=lexeme.substr(0,l-1);
    
    l=lexeme.length();
    for(int i=0;i<l;i++)
    {
        if(lexeme[i]=='\n')
        {
            error_line++;
        }
    }
    
    logfile<<"Error at line no "<<line_count<<": "<<errortype<<" "<<lexeme<<endl<<endl;
    line_count += error_line;
    error_count++;
}


void endProcess()
{
    symtab.printAllScopeTable();
    logfile<<"Total lines: "<<line_count<<endl;
    logfile<<"Total errors: "<<error_count<<endl;
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

"if"|"for"|"do"|"int"|"float"|"void"|"switch"|"default"|"else"|"while"|"break"|"char"|"double"|"return"|"case"|"continue" { keyword(yytext);}





%integer_constant

{Digits} { integer_literal(yytext); }





%floating_point_constant

({Digits}|[.]{Digits}|{Digits}[.]{Digits}?)([eE][-+]?{Digits})?  { floating_literal(yytext); }





%character_constant

\'{Character}\' { character_literal(yytext); }
\'{Escapeseq}\' { escape_sequence(yytext); } 




%unknown_escape_sequence
\'\\{Character}\' { unknown_escape_sequence(yytext); }  




%operator_punctuator

[+-] { op_punc("ADDOP",yytext); }
[*/%] { op_punc("MULOP",yytext); }
"++"|"--" { op_punc("INCOP",yytext); }
"<"|"<="|">"|">="|"=="|"!=" { op_punc("RELOP",yytext); }
[=] { op_punc("ASSIGNOP",yytext); }
"&&"|"||" { op_punc("LOGICOP",yytext); }
[!] { op_punc("NOT",yytext); }
[(] { op_punc("LPAREN",yytext); }
[)] { op_punc("RPAREN",yytext); }
[{] { op_punc("LCURL",yytext); symtab.enterScope(); }
[}] { op_punc("RCURL",yytext); symtab.exitScope(); }
"[" { op_punc("LTHIRD",yytext); }
"]" { op_punc("RTHIRD",yytext); }
[,] { op_punc("COMMA",yytext); }
[;] { op_punc("SEMICOLON",yytext); }




%identifier

[a-zA-Z_]({Alphanumeric}|_)* { identifier(yytext); } 




%string

["][^\n]*((("\\\n")|("\\\r\n"))[^\n]*)*["] { string_object(yytext); } 




%comment

"//"[^\n]*((("\\\n")|("\\\r\n"))[^\n]*)* { comment(yytext); }




%muliline_comment

"/*" { BEGIN MULTILINECOMMENT; }

<MULTILINECOMMENT>"*/" { multicomment += "*/";
                         comment(multicomment); 
                         multicomment="/*"; 
                         BEGIN INITIAL;
                       }
<MULTILINECOMMENT>[^a]|[a] { multicomment += yytext; }





%error

{Digits}?([.]{Digits})([.]{Digits})+([eE][-+]?{Digits}?([.]{Digits})*[.]?)? { error("Too many decimal points",yytext); }

({Digits}|[.]{Digits}|{Digits}[.]{Digits}?)([eE][-+]?{Digits}?)([.]{Digits})+[.]?  { error("Ill formed number",yytext); }

[0-9]({Alphanumeric}|_)+  { error("Invalid prefix on ID or invalid suffix on Number",yytext); }

\'{Charesc}{Charesc}+\'  { error("Multi character constant error",yytext); }

\'\' { error("Empty character constant error",yytext); }

\'[\\]?{Charesc}*  { error("Unterminated character",yytext); }

["]([^\n"]|[\\]["])*((("\\\n")|("\\\r\n"))([^\n"]|[\\]["])*)*$ { error("Unterminated String",yytext); } 

<MULTILINECOMMENT><<EOF>> { error("Unterminated Comment",multicomment); 
                            endProcess();    
                            return 0;                        
                          } 




%end_of_file

<<EOF>>   { endProcess(); return 0; }  




. { error("Unrecognized character",yytext); }

%%





int main(int argc,char *argv[])
{        
    logfile.open("logfile.txt");
    tokenfile.open("tokenfile.txt");    
    
    logfile<<endl;
    

	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Can't open specified file\n");
		return 0;
	}

	yyin= fin;
	yylex();
	fclose(yyin);
	return 0;
}
