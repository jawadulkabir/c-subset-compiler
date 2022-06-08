%{
#include<bits/stdc++.h>
 using namespace std;
 
#include "symbol_table.h"

#define BUCKET_SIZE 30
#define print_proc 2
#define init_seg 0
#define data_seg 1

int yylex(void);
extern FILE *yyin;
ofstream logfile;
ofstream errorfile;
ofstream asmfile;
ofstream optimizedfile;

string asmstring[30];
string funcstring="";
int currentFuncNo=3;

extern int line_count;
extern int error_count;

SymbolTable symtab(BUCKET_SIZE);

int func_scope=0;
string currentFunc;

bool syntax_error=0;


int label_count=0;
int temp_count=0;


void init()
{
    string x=".MODEL SMALL\n\
.STACK 100H\n\
.DATA\n\
CR EQU 0DH\n\
LF EQU 0AH\n";
    asmfile<<x<<endl;
}


string newLabel()
{
    string lb="L";
	lb+=to_string(label_count);
	label_count++;
	return lb;
}

string newTemp()
{	
	string temp="t";
	temp+=to_string(temp_count);
	temp_count++;
	return temp;
}


void yyerror(char *s)
{
	//write your code
	syntax_error=1;
    logfile<<"Line "<<line_count<<": Syntax Error\n\n";
}


void printRule(string s)
{
    logfile<<"Line "<<line_count<<": "<<s<<endl;
}

void printCode(string s)
{
    logfile<<endl<<s<<endl<<endl;
}

void semanticError(string s)
{
    logfile<<"Error at line "<<line_count<<": "<<s<<endl;
    errorfile<<"Error at line "<<line_count<<": "<<s<<endl<<endl;
    error_count++;
}

string getStrFromParamVector(vector<param> vpar)
{
    string s="";
    
    int i=0;
    for(i=0;i<vpar.size()-1;i++)
    {
        s += vpar.at(i).getstr()+",";
    }
    s += vpar.at(i).getstr();
    
    return s;
}



string getStrFromArgVector(vector<entity*> varg)
{
    string s="";
    if(varg.size()==0) return s;
    
    int i=0;
    for(i=0;i<varg.size()-1;i++)
    {
        s += varg.at(i)->srccode+",";
    }
    s += varg.at(i)->srccode;
    
    return s;
}

string getCardinal(int n)
{
    if(n==1) return "1st";
    if(n==2) return "2nd";
    if(n==3) return "3rd";
    return to_string(n)+"th";
}

string getTypeSpecifier(string s)
{
    if(s[0]=='f') return "float";
    if(s[0]=='v') return "void";
    if(s[0]=='i') return "int";
    return "";
}

bool check(string line1, string line2)
{
    string op11="",op12="",op21="",op22="";
    if(line1.length()<7 || line2.length()<7) return false;
    if(line1[4]!='m' || line1[5]!='o' || line1[6]!='v' || line2[4]!='m' || line2[5]!='o' || line2[6]!='v') return false;
    
    int i=8;
    while(line1[i]!=',') 
    {
        op11+=line1[i];
        i++;
    }
     i+=2;
    while(line1[i]!='\n') 
    {
        op12+=line1[i];
        i++;
    }
    
    
    i=8;
    while(line2[i]!=',') 
    {
        op21+=line2[i];
        i++;
    }
     i+=2;
    while(line2[i]!='\n') 
    {
        op22+=line2[i];
        i++;
    }
    
    
    if(op11==op22 && op21==op12) return true;
    return false;
}




%}


%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%token LPAREN RPAREN SEMICOLON COMMA LCURL RCURL LTHIRD RTHIRD INT FLOAT VOID FOR IF WHILE PRINTLN RETURN NOT INCOP DECOP ASSIGNOP

%union{
        int ival;
        float fval;
        SymbolInfo* si;
        vector<SymbolInfo*>* vsi;
        string* str;
        vector<param>* vpar;
        entity* en;
        vector<entity*>* ven;
      }
           
%token <si> ID LOGICOP RELOP ADDOP MULOP CONST_INT CONST_FLOAT
%type <vsi> declaration_list
%type<vpar>parameter_list
%type <str> var_declaration type_specifier func_declaration func_definition program unit func_param_scope_start func_param_end
%type <en> variable factor unary_expression term simple_expression rel_expression logic_expression expression expression_statement statement compound_statement statements
%type <ven> arguments argument_list

%%

start : program
	{
		//write your code in this block in all the similar blocks below
		printRule("start : program");
		symtab.printAllScopeTable(logfile);
		
		logfile<<endl<<endl;
		
		logfile<<"Total lines:"<< line_count<<endl;

		logfile<<"Total errors :"<< error_count<<endl;
		errorfile<<"Total errors :"<< error_count<<endl;

	}
	;

program : unit  {
                    $$ = new string;
                    *$$ = *$1 + "\n";
                    printRule("program : unit");
                    printCode(*$$);
                }
                
	   | program unit  {
                            $$ = new string;
                            *$$ = *$1;
                            *$$ += *$2 + "\n";
                            printRule("program : program unit");
                            printCode(*$$);
                       }
	  ;
	  
	  
	  
unit : var_declaration {
                    $$ = new string;
                    *$$ = *$1;
                    printRule("unit : var_declaration");
                    printCode(*$$);
                }
                
     | func_declaration {
                    $$ = new string;
                    *$$ = *$1;
                    printRule("unit : func_declaration");
                    printCode(*$$);
                }
                
     | func_definition {
                    $$ = new string;
                    *$$ = *$1;
                    printRule("unit : func_definition");
                    printCode(*$$);
                }
     ;
  
  
  
func_declaration : func_param_scope_start parameter_list RPAREN SEMICOLON {
		            $$ = new string;
		            *$$ = *$1 + getStrFromParamVector(*$2) + ");";

		            printRule("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
		            
		            SymbolInfo* si = symtab.Search(currentFunc);
	            
	                FunctionInformation* fi = si->getFuncInfo();
	                if(fi!=NULL)
	                {
	                    if(fi->isDeclared == true)
	                    {
	                        semanticError("Multiple declaration of "+currentFunc);
	                    }
	                    else
	                    {
	                        fi->isDeclared = true;
	                        fi->vpar_declaration = $2;
	                        fi->returnTypeDeclaration = getTypeSpecifier(*$1);
	                    }
	                    symtab.setFuncInfo(currentFunc,fi);
	                    
	                }
		            
		            printCode(*$$); 	
		            
                    symtab.exitScope();	   	        
		        }
		        
		| func_param_scope_start RPAREN SEMICOLON {
		            $$ = new string;
		            *$$ = *$1 + ");";

		            printRule("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON");
		            
		            SymbolInfo* si = symtab.Search(currentFunc);
		            
	                FunctionInformation* fi = si->getFuncInfo();
	                if(fi!=NULL)
	                {
	                    if(fi->isDeclared == true)
	                    {
	                        semanticError("Multiple declaration of "+currentFunc);
	                    }
	                    else
	                    {
	                        fi->isDeclared = true;
	                        fi->returnTypeDeclaration = getTypeSpecifier(*$1);
	                    }
	                    
	                    symtab.setFuncInfo(currentFunc,fi);
	                }
		            
		            
		            printCode(*$$); 		  
		            
                    symtab.exitScope();	         
		        }
		;
		 
func_definition : func_param_end compound_statement {
		            $$ = new string;
		            *$$ = *$1 + $2->srccode + "\n";
                                            
                    if($1->substr($1->length()-2,$1->length())=="()")
                    {
                        printRule("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
                    }
		            else 
		            {
		                printRule("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
		            }
		            printCode(*$$); 	      
		        
		        SymbolInfo* si = symtab.Search(currentFunc);
		        vector<param>* ParameterList = si->getFuncInfo()->vpar_definition;
		        
		        
		        asmstring[data_seg] += "    "+si->asmvar+" dw ?\n";
		        
		        
		        if(currentFunc=="main")
		        {
		            asmstring[currentFuncNo] += "main PROC\n\    mov ax, @data\n\    mov ds, ax\n";  
                    asmstring[currentFuncNo] += $2->asmcode;
                    asmstring[currentFuncNo] += "\n\n    mov ah, 4ch\n    int 21h\nmain ENDP\nEND main";                    
		        }
		        
		        else
		        {   		        
		            asmstring[currentFuncNo] += currentFunc+" PROC\n";
		            asmstring[currentFuncNo] +="    push bp\n    push ax\n    push bx\n    push cx\n    push dx\n";
		            
		            asmstring[currentFuncNo] +="    mov bp, sp\n";
		            
		            for(int i=ParameterList->size()-1,j=12;i>=0;i--,j+=2)
		            {
		                string varname = ParameterList->at(i).var->getname();
		                varname = varname+symtab.getCurrent()->getID();
		                //logfile<<varname<<endl;
		                asmstring[currentFuncNo] +="    mov cx, [bp+"+to_string(j)+"]\n";
		                asmstring[currentFuncNo] +="    mov "+varname+", cx\n";
		            }
		            
		            asmstring[currentFuncNo] += $2->asmcode;
		            asmstring[currentFuncNo] +="\n    pop dx\n    pop cx\n    pop bx\n    pop ax\n    pop bp\n";
		            
                    asmstring[currentFuncNo] += "    ret ";
                    if(ParameterList->size()!=0) asmstring[currentFuncNo] +=to_string(ParameterList->size()*2);
                    
                    asmstring[currentFuncNo] += "\n"+currentFunc+" ENDP\n\n";
		        }
		        
		        currentFuncNo++;
		        
		        
		        
                symtab.printAllScopeTable(logfile);
                symtab.exitScope();	 
                    
              }      
		
 		;				


/**extra rule**/
func_param_end : func_param_scope_start parameter_list RPAREN { 
                                $$ = new string;
                                *$$ = *$1 + getStrFromParamVector(*$2) + ")";
                                
                                SymbolInfo* si = symtab.Search(currentFunc);
                                
                                FunctionInformation* fi = si->getFuncInfo();
                                if(fi!=NULL)
                                {
                                    
                                    if(fi->isDefined==true)
                                    {
                                        semanticError("Multiple definition of "+currentFunc);
                                    }
                                    else
                                    {
                                        fi->isDefined=true;
                                        fi->returnTypeDefinition = getTypeSpecifier(*$1); 
                                        fi->vpar_definition = $2;
                                    }
                                    
                                    if(fi->isDeclared==true)
                                    {
                                        if(fi->returnTypeDeclaration != fi->returnTypeDefinition)
                                        {
                                            semanticError("Return type mismatch with function declaration in function "+currentFunc);
                                        }
                                        
                                        if($2->size()!=fi->vpar_declaration->size())
                                        {
                                            semanticError("Total number of parameters mismatch with declaration in function "+currentFunc);
                                        }
                                        else
                                        {
                                            for(int i=0;i<$2->size();i++)
                                            {
                                                if($2->at(i).dtype!=fi->vpar_declaration->at(i).dtype)
                                                {
                                                    semanticError(getCardinal(i+1)+" parameter mismatch in function "+currentFunc);
                                                }
                                            }
                                        }
                                    }
                                                                      
                                    
                                    symtab.setFuncInfo(currentFunc,fi);
                                }
                                
                                
                                
                                
                                for(int i=0;i<$2->size();i++)
                                {
                                    if($2->at(i).var==NULL) semanticError("parameter without id");
                                    else 
                                    {
                                        SymbolInfo* si = new SymbolInfo($2->at(i).var->getname(),$2->at(i).var->gettype());
                                        si->setDtype($2->at(i).dtype); 
                                        string varname = $2->at(i).var->getname()+symtab.getCurrent()->getID();
                         		        //si->asmcode = varname;
                         		        si->asmvar = varname;
                         		        asmstring[data_seg] += "    "+varname+" dw ?\n";
                                        symtab.Insert(si); 
                                     
                                    }
                                }
                            }
                            
                 | func_param_scope_start RPAREN { 
                                $$ = new string;
                                *$$ = *$1+")";
                                
                                SymbolInfo* si = symtab.Search(currentFunc);
                                
                                FunctionInformation* fi = si->getFuncInfo();
                                if(fi!=NULL)
                                {
                                    if(fi->isDefined==true)
                                    {
                                        semanticError("Multiple definition of "+currentFunc);
                                    }
                                    else
                                    {
                                        fi->isDefined=true;
                                        fi->returnTypeDefinition = getTypeSpecifier(*$1);
                                    }
                                    
                                    if(fi->isDeclared==true)
                                    {
                                        if(fi->returnTypeDeclaration != fi->returnTypeDefinition)
                                        {
                                            semanticError("Return type mismatch with function declaration in function "+currentFunc);
                                        }
                                        
                                        if(fi->vpar_declaration->size()!=0)
                                        {
                                            semanticError("Total number of parameters mismatch with declaration in function "+currentFunc);
                                        }
                                    }
                                    
                                    symtab.setFuncInfo(currentFunc,fi);
                                }
                          }
                 
                            ;



func_param_scope_start : type_specifier ID LPAREN { 
                                SymbolInfo* si = new SymbolInfo($2->getname(),$2->gettype());
                                
                                $$ = new string;
                                *$$ = *$1 + " " + $2->getname() + "(";
                                currentFunc = $2->getname();
                                bool f=symtab.Insert(si); //insert function name
                                
                                if(f) //successful insertion => a new function
                                {
                                    FunctionInformation* fi = new FunctionInformation();
                                    fi->returnType = *$1;
                                    symtab.setFuncInfo($2->getname(),fi);                                
                                }
                                else if(!f)
                                {
                                    si = symtab.Search($2->getname());
                                    if(si->getFuncInfo()==NULL)
                                    {
                                        semanticError("Multiple declaration of "+$2->getname());
                                    }                                
                                }
                                
                                symtab.enterScope(); //new scope for parameter variables
                                func_scope = 1;
                            }
            ;
            


parameter_list  : parameter_list COMMA type_specifier ID {
                    $$ = new vector<param>();
                    string s="";
                    
                    for(int i=0;i<$1->size();i++)
                    {
                        s += $1->at(i).getstr()+",";
                        $$->push_back($1->at(i));
                        
                        if($4->getname() == $1->at(i).var->getname())
                        {
                            $4->setMultiple(true);
                            semanticError("Multiple declaration of "+$4->getname()+" in parameter");
                        }
                    }


                    struct param p(*$3,$4);                    
                    s += p.getstr();
                    $$->push_back(p);
                    
                    printRule("parameter_list : parameter_list COMMA type_specifier ID");
                    printCode(s);
                    
                }
                
                
		| parameter_list COMMA type_specifier {
		            $$ = new vector<param>();
                    string s="";
                    struct param p(*$3);
                    
                    for(int i=0;i<$1->size();i++)
                    {
                        s += $1->at(i).getstr()+",";
                        $$->push_back($1->at(i));
                    }
                    
                    s += p.getstr();
                    $$->push_back(p);
                    
                    printRule("parameter_list : parameter_list COMMA type_specifier ID");
                    printCode(s);
		        }
		        
		        
 		| type_specifier ID  {
                                $$ = new vector<param>();
                                struct param p(*$1,$2);
                                $$->push_back(p);
                                printRule("parameter_list : type_specifier ID");
                                printCode(*$1+" "+$2->getname());
 		        
                             }
                         
                         
		| type_specifier {
                            $$ = new vector<param>();
                            struct param p(*$1);
                            $$->push_back(p);
                            printRule("parameter_list : type_specifier");
                            printCode(*$1);
	        
                         }
 		;

 		
compound_statement : scope_start statements scope_end {
                        $$ = new entity();
                        $$->srccode="{\n";
                        $$->srccode += $2->srccode + "}";
                        
                        printRule("compound_statement : LCURL statements RCURL");
                        printCode($$->srccode);
                        
                        $$->asmcode = $2->asmcode;
                        
                    }
                    
 		    | scope_start scope_end {
                        $$ = new entity();
                        $$->srccode="{\n}";          
                        
                        printRule("compound_statement : LCURL RCURL");
                        printCode($$->srccode);             
                        
                    }
 		    ;
 		    
/**extra rule**/
scope_start : LCURL { if(func_scope==0) symtab.enterScope(); else func_scope=0;}
            ;
            
scope_end : RCURL {  }
            ;
/**extra rule**/
 		    
 		    
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
                        printRule("var_declaration : type_specifier declaration_list SEMICOLON");
                        if(*$1=="void")
                            semanticError("Variable type cannot be void");
                        
                        $$ = new string;
                        string p=*$1+" ";
                        int i;
                        for(i=0;i<$2->size();i++)
                        {                            
                            if($2->at(i)->getMultiple() == false)
                            {
                                symtab.setDtype($2->at(i)->getOriginalName(),*$1);
                            }
                        }
                        
                        for(i=0;i<$2->size()-1;i++)
                        {
                            p+= $2->at(i)->getname()+",";
                        }
                        p+= $2->at(i)->getname()+";";
                        (*$$)=p;
                        printCode(*$$);
                 }
 		 ;
 		 
 		 
 		 
type_specifier	: FLOAT {
                         $$ = new string;
             		     (*$$)="float";
             		     printRule("type_specifier : FLOAT");
             		     printCode("float");
             		    }
 		| INT {
               $$ = new string;
 		       (*$$)="int";
 		       printRule("type_specifier : INT");
 		       printCode("int");
 		      }
 		| VOID {
                $$ = new string;
     		    (*$$)="void";
 		        printRule("type_specifier : VOID");
 		        printCode("void");
 		       }
 		;
 		

 		
declaration_list : declaration_list COMMA ID {
                                                string s="";
 		        
 		                                        SymbolInfo* si = new SymbolInfo($3->getname(),$3->gettype());
 		        
                                 		        string varname = $3->getname()+symtab.getCurrent()->getID();
                                 		        //si->asmcode = varname;
                                 		        si->asmvar = varname;
                                                asmstring[data_seg] += "    "+varname+" dw ?\n";
 		                                        
 		                                        $$ = new vector<SymbolInfo*>();
 		                                        
 		                                        int i;logfile<<endl;
 		                                        for(i=0;i<$1->size();i++)
 		                                        {
 		                                            $$->push_back($1->at(i));
                                                    //logfile<<$1->at(i)->getname()<<",";
                                                    s+=$1->at(i)->getname()+",";
 		                                        }
 		        
 		                                        bool f=symtab.Insert(si);
 		                                        if(!f) 
 		                                        {
 		                                            semanticError("Multiple declaration of "+$3->getname());
 		                                            si->setMultiple(true);
 		                                        }
 		                                        
                                                $$->push_back(si);
                                                
                                                s+=si->getname();
                                                
                                                printRule("declaration_list : declaration_list COMMA ID"); 
                                                printCode(s);
                                             }
                                             
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
 		                string s="";
 		            
         		        SymbolInfo* si = new SymbolInfo($3->getname(),$3->gettype());
         		        si->set_name_addon("["+$5->getname()+"]");
         		        si->setArrayStatus(true);
         		        
         		        string varname = $3->getname()+symtab.getCurrent()->getID();
         		        
         		        si->asmvar = varname;
                        asmstring[data_seg] += "    "+varname+" dw "+$5->getname()+" dup(?)\n";
         		        

 		        
                        $$ = new vector<SymbolInfo*>();
                        
                        int i;logfile<<endl;
                        for(i=0;i<$1->size();i++)
                        {
                            $$->push_back($1->at(i));
                            s+=$1->at(i)->getname()+",";
                        }
                        
                        bool f=symtab.Insert(si);
 		                if(!f) 
                        {
                            semanticError("Multiple declaration of "+$3->getname());
                            si->setMultiple(true);
                        }
 		                
                        $$->push_back(si);
                        s+=si->getname(); 		                
                        
                        printRule("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
                        printCode(s);
 		              }
 		              
 		  | ID { 	
 		        SymbolInfo* si = new SymbolInfo($1->getname(),$1->gettype());
 		        
 		        string varname = $1->getname()+symtab.getCurrent()->getID();
 		        //si->asmcode = varname;
 		        si->asmvar = varname;
                asmstring[data_seg] += "    "+varname+" dw ?\n";
 		         		  	        
 		        $$ = new vector<SymbolInfo*>();
 		        
 		        bool f=symtab.Insert(si);
 		        if(!f) 
                {
                    semanticError("Multiple declaration of "+$1->getname());
                    si->setMultiple(true);
                }
 		        $$->push_back(si);
 		        
 		        printRule("declaration_list : ID");
 		        printCode($1->getname());
 		       }
 		       
 		  | ID LTHIRD CONST_INT RTHIRD {
 		        SymbolInfo* si = new SymbolInfo($1->getname(),$1->gettype());
 		        si->set_name_addon("["+$3->getname()+"]");
         		si->setArrayStatus(true);
         		        
 		        string varname = $3->getname()+symtab.getCurrent()->getID();
 		        
 		        si->asmvar = varname;
                asmstring[data_seg] += "    "+varname+" dw "+$3->getname()+" dup(?)\n";
 		        
 		        $$ = new vector<SymbolInfo*>();
 		        
 		        bool f=symtab.Insert(si);
 		        if(!f) 
                {
                    semanticError("Multiple declaration of "+$1->getname());
                    si->setMultiple(true);
                }
 		        
 		        $$->push_back(si);
 		        
 		        printRule("declaration_list : ID LTHIRD CONST_INT RTHIRD");
 		        printCode(si->getname());
 		       }
 		  ;

statements : statement  {
                            $$ = new entity();
                            $$->srccode = $1->srccode + "\n";
                            printRule("statements : statement");
                            printCode($$->srccode);
                            
                            $$->asmcode = $1->asmcode;
                        }
	   | statements statement  {
                        $$ = new entity();
                        $$->srccode = $1->srccode;
                        $$->srccode += $2->srccode + "\n";
                        printRule("statements : statements statement");
                        printCode($$->srccode);
                        
                        $$->asmcode = $1->asmcode;
                        $$->asmcode += $2->asmcode;
                     }
	   ;
	   
	   
	   
statement : var_declaration  {
	                $$ = new entity();
	                $$->srccode = *$1;
                    printRule("statement : var_declaration");
                    printCode($$->srccode);
                 }
                 
	  | expression_statement  {
	                $$ = new entity();
	                $$->srccode = $1->srccode;
	                printRule("statement : expression_statement");
                    printCode($$->srccode);
                        
                    $$->asmcode = ";";
                    
                    for(int i=0;i<$$->srccode.length();i++)
                    {
                        if($$->srccode[i]=='\n') $$->asmcode+=";";
                        $$->asmcode += $$->srccode[i];
                    }
                    $$->asmcode +="\n";
                    
                    $$->asmcode += $1->asmcode;
                    
	             }
	  
	  | compound_statement  {
	                $$ = new entity();
	                $$->srccode = $1->srccode;
	                
	                symtab.printAllScopeTable(logfile);
                    symtab.exitScope();	 
                    
		            printRule("statement : compound_statement");
                    printCode($$->srccode);
                    
                    $$->asmcode += $1->asmcode;
	             }
	             
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement  {
	                $$ = new entity();
	                $$->srccode = "for(";	
	                $$->srccode += $3->srccode + $4->srccode + $5->srccode + ")" + $7->srccode;  	  
	                printRule("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
                    printCode($$->srccode);
                        
                    $$->asmcode = ";";
                    
                    string str="for("+$3->srccode + $4->srccode + $5->srccode + ")";
                    
                    for(int i=0;i<str.length();i++)
                    {
                        if(str[i]=='\n') $$->asmcode+=";";
                        $$->asmcode += str[i];
                    }
                    $$->asmcode +="\n";
                    
                    string lab1=newLabel();
                    string lab2=newLabel();
                    
                    $$->asmcode +=$3->asmcode+"\n";
                    
                    $$->asmcode +=lab1+":\n"; 
                    $$->asmcode +=$4->asmcode+"\n";
                    $$->asmcode +="    mov ax, "+$4->asmvar+"\n";
                    $$->asmcode +="    cmp ax, 0\n";
                    $$->asmcode +="    je "+lab2+"\n";
                    $$->asmcode +=$7->asmcode+"\n";
                    $$->asmcode +=$5->asmcode+"\n";
                    $$->asmcode +="    jmp "+lab1+"\n";
                    $$->asmcode +=lab2+":\n"; 
	             }
	  
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE  {
	                $$ = new entity();
	                $$->srccode="if ("+$3->srccode+")"+$5->srccode;
	                printRule("statement : IF LPAREN expression RPAREN statement");
                    printCode($$->srccode);
                        
                    $$->asmcode = ";";
                    
                    string str="if ("+$3->srccode+")";
                    
                    for(int i=0;i<str.length();i++)
                    {
                        if(str[i]=='\n') $$->asmcode+=";";
                        $$->asmcode += str[i];
                    }
                    $$->asmcode +="\n";
                    
                    string lab=newLabel();
                    
                    $$->asmcode +=$3->asmcode+"\n";
                    $$->asmcode +="    mov ax, "+$3->asmvar+"\n";
                    $$->asmcode +="    cmp ax, 0\n";
                    $$->asmcode +="    je "+lab+"\n";
                    $$->asmcode +=$5->asmcode+"\n";
                    $$->asmcode +=lab+":\n";  
                    
                    /*
                    mov ax,$3
                    cmp ax,0
                    je lab
                    statement
                    lab:
                    
                    */
                    
                    
                 }
	  | IF LPAREN expression RPAREN statement ELSE statement  {
	                $$ = new entity();
	                $$->srccode="if ("+$3->srccode+")"+$5->srccode+"\nelse\n"+$7->srccode;
	                printRule("statement : IF LPAREN expression RPAREN statement ELSE statement");
                    printCode($$->srccode);
                        
                    $$->asmcode = ";";
                    
                    string str="if ("+$3->srccode+")";
                    
                    for(int i=0;i<str.length();i++)
                    {
                        if(str[i]=='\n') $$->asmcode+=";";
                        $$->asmcode += str[i];
                    }
                    $$->asmcode +="\n";
                    
                    string lab1=newLabel();
                    string lab2=newLabel();
                    
                    $$->asmcode +=$3->asmcode+"\n";
                    $$->asmcode +="    mov ax, "+$3->asmvar+"\n";
                    $$->asmcode +="    cmp ax, 0\n";
                    $$->asmcode +="    je "+lab1+"\n";
                    $$->asmcode +=$5->asmcode+"\n";
                    $$->asmcode +="    jmp "+lab2+"\n";
                    $$->asmcode +=lab1+":\n";  
                    $$->asmcode +=$7->asmcode+"\n";
                    $$->asmcode +=lab2+":\n";  
                    
                    /*
                    mov ax,$3
                    cmp ax,0
                    je lab1
                    statement
                    jmp lab2
                    lab1:
                    statement2
                    lab2:
                    
                    */                    
                    
                    
                 }
	  
	  | WHILE LPAREN expression RPAREN statement  {
	                $$ = new entity();
	                $$->srccode = "while (" + $3->srccode + ")" + $5->srccode;  
	                printRule("statement : WHILE LPAREN expression RPAREN statement");
                    printCode($$->srccode);
                        
                    $$->asmcode = ";";
                    
                    string str="while("+$3->srccode+")";
                    
                    for(int i=0;i<str.length();i++)
                    {
                        if(str[i]=='\n') $$->asmcode+=";";
                        $$->asmcode += str[i];
                    }
                    $$->asmcode +="\n";
                    
                    string lab1=newLabel();
                    string lab2=newLabel();
                    
                    $$->asmcode +=lab1+":\n"; 
                    $$->asmcode +=$3->asmcode+"\n";
                    $$->asmcode +="    mov ax, "+$3->asmvar+"\n";
                    $$->asmcode +="    cmp ax, 0\n";
                    $$->asmcode +="    je "+lab2+"\n";
                    $$->asmcode +=$5->asmcode+"\n";
                    $$->asmcode +="    jmp "+lab1+"\n";
                    $$->asmcode +=lab2+":\n";   
                    
	             }
	  
	  
	  | PRINTLN LPAREN ID RPAREN SEMICOLON  {
	                $$ = new entity();
	                $$->srccode = "printf(";	
	                $$->srccode += $3->getname() + ");";  
                    
	                printRule("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
	                
	                SymbolInfo* si = symtab.Search($3->getname());
                    if(si==NULL) semanticError("Undeclared variable "+$3->getname());
                    
                    printCode($$->srccode);
                  
                    
                    $$->asmcode = ";"+$$->srccode+"\n";
                    $$->asmcode += "    mov ax, "+si->asmvar+"\n";
                    $$->asmcode += "    call print_proc\n";
	             }
	  
	  | RETURN expression SEMICOLON  {
	                $$ = new entity();
	                $$->srccode = "return " + $2->srccode + ";";
	                printRule("statement : RETURN expression SEMICOLON");
                    printCode($$->srccode);
                    
                    SymbolInfo* si = symtab.Search(currentFunc);
		            string retval = si->asmvar;
                    
                    $$->asmcode += ";"+$$->srccode+"\n";
                    $$->asmcode +=$2->asmcode+"\n";
                    $$->asmcode +="    mov ax, "+$2->asmvar+"\n";
                    $$->asmcode +="    mov "+retval+", ax\n";
                    //symtab.setAsmvar(currentFunc,retval);
	             }
	  ;
	  
	  
expression_statement : SEMICOLON  {
                                    $$ = new entity();
                                    $$->srccode = ";";
                                    printRule("expression_statement : SEMICOLON");
                                    printCode($$->srccode);
                                  }	
                                  		
                                  		
			| expression SEMICOLON  {
			        $$ = new entity();
                    $$->srccode = $1->srccode+";";
                    printRule("expression_statement : expression SEMICOLON");
                    printCode($$->srccode);
                        
                    $$->asmcode = $1->asmcode;
                    $$->asmvar = $1->asmvar;
                 } 
			;
			
	  
variable : ID {
                $$ = new entity();
                $$->srccode = $1->getname();
                $$->isArray = false;
                printRule("variable : ID"); 
                SymbolInfo* si = symtab.Search($1->getname());
                
                if(si==NULL) semanticError("Undeclared variable "+$1->getname());
                else
                {
                    $$->dtype = si->getDtype();//logfile<<si->getDtype()<<"pipipi"<<endl;
                    if(si->getArrayStatus()==true) semanticError("Type mismatch, "+$1->getname()+" is an array");
                   
                }
                printCode($$->srccode);
                
                //$$->asmcode = si->asmcode;
                $$->asmvar = si->asmvar;
                //cout<<"hereh\n";
                //cout<<$1->asmvar <<endl;
                
              }
              
              
	 | ID LTHIRD expression RTHIRD {
                    $$ = new entity();
                    $$->srccode = $1->getname()+"["+$3->srccode+"]";
                    $$->isArray = true;
                    printRule("variable : ID LTHIRD expression RTHIRD");  
                    
                    SymbolInfo* si = symtab.Search($1->getname());
                
                    if(si==NULL) semanticError("Undeclared variable "+$1->getname());
                    else
                    {
                        if(si->getArrayStatus()==false) semanticError($1->getname()+" not an array");
                        
                        if($3->dtype!="int") semanticError("Expression inside third brackets not an integer");
                        
                        if((si->getArrayStatus()==true)&&($3->dtype=="int")) $$->dtype = si->getDtype();
                    }
                    
                    printCode($$->srccode);
                    
                    string temp = newTemp();
                    asmstring[data_seg] += "    "+temp+" dw ?\n";
                    
                    $$->asmcode += $3->asmcode+"\n";
                    $$->asmcode += "    mov bx, " +$3->asmvar+"\n";
                    $$->asmcode += "    add bx, bx\n";
                    $$->asmcode += "    mov cx, "+si->asmvar+"[bx]\n";
                    $$->asmcode += "    mov "+temp+", cx\n";
                    
                    $$->asmvar = temp;//si->asmvar+"[bx]"; 
                    $$->asmvar_array = si->asmvar+"[bx]";
                    
              }
	 ;
	 
expression : logic_expression  {
                                    $$ = new entity();
                                    $$->srccode = $1->srccode;
                                    $$->dtype = $1->dtype;
                                    printRule("expression : logic_expression");
                                    printCode($$->srccode);
                        
                                    $$->asmcode = $1->asmcode;
                                    $$->asmvar = $1->asmvar;
                               } 
                               
	   | variable ASSIGNOP logic_expression  {
		                    $$ = new entity();
                            $$->srccode = $1->srccode + "=" + $3->srccode;
                            $$->dtype = $1->dtype;
                            printRule("expression : variable ASSIGNOP logic_expression");
                            
                            if(($1->dtype =="int" && $3->dtype =="float")) semanticError("Type Mismatch");
                            else if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                                
		                    printCode($$->srccode);
		                    
		                    $$->asmcode += $3->asmcode; 
                            $$->asmcode += "    mov ax, "+$3->asmvar+"\n";
		                    $$->asmcode += $1->asmcode; 
                            
		                    if($1->isArray == true)
		                    {
		                        $$->asmcode += "    mov "+$1->asmvar_array+", ax\n";
		                    }
		                    else
		                    {
                                $$->asmcode += "    mov "+$1->asmvar+", ax\n";
                            }
		                }
	   ;
	   
			
logic_expression : rel_expression  {
                                        $$ = new entity();
                                        $$->srccode = $1->srccode;
                                        $$->dtype = $1->dtype;
                                        printRule("logic_expression : rel_expression");
		                                printCode($$->srccode);
                        
                                        $$->asmcode = $1->asmcode;
                                        $$->asmvar = $1->asmvar;
                                        //asmstring[main_proc] +=$$->asmcode +"hmm\n";
                                        //logfile<<$$->asmcode<<"hmm\n";
                                   }
                                   

		 | rel_expression LOGICOP rel_expression  {
		                    $$ = new entity();
                            $$->srccode = $1->srccode + $2->getname() + $3->srccode;
                            $$->dtype = "int";
                            printRule("logic_expression : rel_expression LOGICOP rel_expression");
                            
                            if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                            
		                    printCode($$->srccode);
		                    
		                    string temp = newTemp();
                            asmstring[data_seg] += "    "+temp+" dw ?\n";
                            
                            string lab1 = newLabel();
                            string lab2 = newLabel();
		                    
		                    $$->asmcode += $1->asmcode; 
                            $$->asmcode += $3->asmcode;
                            
                                                       
                            if($2->getname()=="&&")
                            {
                                $$->asmcode +="    mov ax,"+$1->asmvar+"\n";
                                $$->asmcode +="    cmp ax,0\n";
                                $$->asmcode +="    je "+lab1+"\n";
                                $$->asmcode +="    mov ax, "+$3->asmvar+"\n";
                                $$->asmcode +="    cmp ax,0\n";
                                $$->asmcode +="    je "+lab1+"\n";
                                $$->asmcode +="    mov "+temp+", 1\n";
                                $$->asmcode +="    jmp "+lab2+"\n";
                                $$->asmcode +=lab1+":\n";
                                $$->asmcode +="    mov "+temp+", 0\n";
                                $$->asmcode +=lab2+":\n";
                                
                                /*
                                mov ax,$1
                                cmp ax,0
                                je lab1
                                mov ax,$3
                                cmp ax,0
                                je lab1
                                
                                mov temp,1
                                jmp lab2
                                lab1:
                                mov temp,0
                                lab2:
                                */
                            }
                            
                            else if($2->getname()=="||")
                            {
                                $$->asmcode +="    mov ax,"+$1->asmvar+"\n";
                                $$->asmcode +="    cmp ax,0\n";
                                $$->asmcode +="    jne "+lab1+"\n";
                                $$->asmcode +="    mov ax, "+$3->asmvar+"\n";
                                $$->asmcode +="    cmp ax,0\n";
                                $$->asmcode +="    jne "+lab1+"\n";
                                $$->asmcode +="    mov "+temp+", 0\n";
                                $$->asmcode +="    jmp "+lab2+"\n";
                                $$->asmcode +=lab1+":\n";
                                $$->asmcode +="    mov "+temp+", 1\n";
                                $$->asmcode +=lab2+":\n";
                                
                                /*
                                mov ax,$1
                                cmp ax,0
                                jne lab1
                                mov ax,$3
                                cmp ax,0
                                jne lab1
                                
                                mov temp,0
                                jmp lab2
                                lab1:
                                mov temp,1
                                lab2:
                                */
                            }
                            
                            $$->asmvar = temp; 
                            
                            
		               }
		 ;
		 
			
rel_expression : simple_expression  {
                                        $$ = new entity();
                                        $$->srccode = $1->srccode;
                                        $$->dtype = $1->dtype;
                                        printRule("rel_expression : simple_expression");
		                                printCode($$->srccode);
                        
                                        $$->asmcode = $1->asmcode;
                                        $$->asmvar = $1->asmvar;
                                        //asmstring[main_proc] +=$$->asmcode +"hmm\n";
                                        //logfile<<$$->asmcode<<"hmm\n";
                                    }


		| simple_expression RELOP simple_expression	 {
		                    $$ = new entity();
                            $$->srccode = $1->srccode+ $2->getname() + $3->srccode;
                            $$->dtype = "int";
                            printRule("rel_expression : simple_expression RELOP simple_expression");
                            
                            if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                            
		                    printCode($$->srccode);
		                    
		                    
		                    //"<"|"<="|">"|">="|"=="|"!=" 
		                    
		                    string temp = newTemp();
                            asmstring[data_seg] += "    "+temp+" dw ?\n";
                            
                            string lab1 = newLabel();
                            string lab2 = newLabel();
		                    
		                    $$->asmcode += $1->asmcode; 
                            $$->asmcode += $3->asmcode;
                            
                            $$->asmcode +="    mov ax,"+$1->asmvar+"\n";
                            $$->asmcode +="    cmp ax,"+$3->asmvar+"\n";
                            
                            if($2->getname()=="<")
                            {
                                $$->asmcode +="    jge "+lab1+"\n";
                                $$->asmcode +="    mov "+temp+", 1\n";
                                $$->asmcode +="    jmp "+lab2+"\n";
                                $$->asmcode +=lab1+":\n";
                                $$->asmcode +="    mov "+temp+", 0\n";
                                $$->asmcode +=lab2+":\n";
                                
                                /*
                                jge lab1
                                mov temp, 1
                                jmp lab2
                                lab1:
                                mov temp, 0
                                lab2:
                                */
                             }
                            
                            else if($2->getname()==">")
                            {
                                $$->asmcode +="    jle "+lab1+"\n";
                                $$->asmcode +="    mov "+temp+", 1\n";
                                $$->asmcode +="    jmp "+lab2+"\n";
                                $$->asmcode +=lab1+":\n";
                                $$->asmcode +="    mov "+temp+", 0\n";
                                $$->asmcode +=lab2+":\n";
                                
                                /*
                                jle lab1
                                mov temp, 1
                                jmp lab2
                                lab1:
                                mov temp, 0
                                lab2:
                                */
                             }
                            
                            else if($2->getname()=="<=")
                            {
                                $$->asmcode +="    jg "+lab1+"\n";
                                $$->asmcode +="    mov "+temp+", 1\n";
                                $$->asmcode +="    jmp "+lab2+"\n";
                                $$->asmcode +=lab1+":\n";
                                $$->asmcode +="    mov "+temp+", 0\n";
                                $$->asmcode +=lab2+":\n";
                                
                                /*
                                jg lab1
                                mov temp, 1
                                jmp lab2
                                lab1:
                                mov temp, 0
                                lab2:
                                */
                             }
                            
                            else if($2->getname()==">=")
                            {
                                $$->asmcode +="    jl "+lab1+"\n";
                                $$->asmcode +="    mov "+temp+", 1\n";
                                $$->asmcode +="    jmp "+lab2+"\n";
                                $$->asmcode +=lab1+":\n";
                                $$->asmcode +="    mov "+temp+", 0\n";
                                $$->asmcode +=lab2+":\n";
                                
                                /*
                                jl lab1
                                mov temp, 1
                                jmp lab2
                                lab1:
                                mov temp, 0
                                lab2:
                                */
                             }
                            
                            else if($2->getname()=="==")
                            {
                                $$->asmcode +="    jne "+lab1+"\n";
                                $$->asmcode +="    mov "+temp+", 1\n";
                                $$->asmcode +="    jmp "+lab2+"\n";
                                $$->asmcode +=lab1+":\n";
                                $$->asmcode +="    mov "+temp+", 0\n";
                                $$->asmcode +=lab2+":\n";
                                
                                /*
                                jne lab1
                                mov temp, 1
                                jmp lab2
                                lab1:
                                mov temp, 0
                                lab2:
                                */
                             }
                            
                            else if($2->getname()=="!=")
                            {
                                $$->asmcode +="    je "+lab1+"\n";
                                $$->asmcode +="    mov "+temp+", 1\n";
                                $$->asmcode +="    jmp "+lab2+"\n";
                                $$->asmcode +=lab1+":\n";
                                $$->asmcode +="    mov "+temp+", 0\n";
                                $$->asmcode +=lab2+":\n";
                                
                                /*
                                je lab1
                                mov temp, 1
                                jmp lab2
                                lab1:
                                mov temp, 0
                                lab2:
                                */
                             }
                             
                             $$->asmvar = temp;
		            }
		;
				
				
simple_expression : term  {
		                        $$ = new entity();
                                $$->srccode = $1->srccode;
                                $$->dtype = $1->dtype;
                                printRule("simple_expression : term");
                                printCode($$->srccode);
                        
                                $$->asmcode = $1->asmcode;
                                $$->asmvar = $1->asmvar;
                          }
                                
                                
		  | simple_expression ADDOP term  {
		            $$ = new entity();
                    $$->srccode = $1->srccode + $2->getname() + $3->srccode;; 
                    
                    if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                    else if($1->dtype=="int" && $3->dtype=="int") $$->dtype = "int";
                    else if($1->dtype=="float" || $3->dtype=="float") $$->dtype = "float";
                    
                    printRule("simple_expression : simple_expression ADDOP term");
                    printCode($$->srccode);           
                    
                    
                    string temp = newTemp();
                    asmstring[data_seg] += "    "+temp+" dw ?\n";
                    
                    $$->asmcode += $1->asmcode; 
                    $$->asmcode += $3->asmcode;
                    
                    $$->asmcode += "    mov ax, "+$1->asmvar+"\n";
                    if($2->getname()=="+") $$->asmcode += "    add ax, "+$3->asmvar+"\n";
                    else if($2->getname()=="-") $$->asmcode += "    sub ax, "+$3->asmvar+"\n";
                    $$->asmcode += "    mov "+temp+", ax\n";
                    
                    
                    $$->asmvar=temp;
               }
		  ;
					
term :	unary_expression  {
                                $$ = new entity();
                                $$->srccode = $1->srccode;
                                $$->dtype = $1->dtype;
                                printRule("term : unary_expression");
                                printCode($$->srccode);
                        
                                $$->asmcode = $1->asmcode;
                                $$->asmvar = $1->asmvar;
                          }
                          
                          
     |  term MULOP unary_expression  {
                    $$ = new entity();
                    $$->srccode = $1->srccode + $2->getname() + $3->srccode;
                    
                    printRule("term : term MULOP unary_expression");
                    
                    if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                    else
                    {
                        if($2->getname()=="%")
                        {
                            if($1->dtype=="float" || $3->dtype=="float") semanticError("Non-Integer operand on modulus operator");
                            else if($1->srccode=="0" || $3->srccode=="0") semanticError("Modulus by Zero");
                        }
                        else
                        {
                            if($1->dtype=="int" && $3->dtype=="int") $$->dtype = "int";
                            if($1->dtype=="float" || $3->dtype=="float") $$->dtype = "float";
                        }
                    }             
                    
                    printCode($$->srccode);
                    
                    
                    
                    string temp = newTemp();
                    asmstring[data_seg] += "    "+temp+" dw ?\n";
                    
                    $$->asmcode += $1->asmcode;
                    $$->asmcode += $3->asmcode;
                    
                    if($2->getname()=="*")
                    {
                        $$->asmcode += "    mov ax, "+$1->asmvar+"\n";
                        
                        if($3->asmvar==$3->srccode)
                        {
                            string temp = newTemp();
                            asmstring[data_seg] += "    "+temp+" dw ?\n";
                            $$->asmcode += "    mov "+temp+", "+$3->asmvar+"\n";
                            $$->asmcode += "    imul "+temp+"\n";
                        }
                        else $$->asmcode += "    imul "+$3->asmvar+"\n";
                        
                        $$->asmcode += "    mov "+temp+", ax\n";
                    }
                    
                    else if($2->getname()=="/")
                    {
                        $$->asmcode += "    mov ax, "+$1->asmvar+"\n"+"    cwd\n";
                        
                        if($3->asmvar==$3->srccode)
                        {
                            string temp = newTemp();
                            asmstring[data_seg] += "    "+temp+" dw ?\n";
                            $$->asmcode += "    mov "+temp+", "+$3->asmvar+"\n";
                            $$->asmcode += "    idiv "+temp+"\n";
                        }
                        else $$->asmcode += "   idiv "+$3->asmvar+"\n";
                        
                        $$->asmcode += "    mov "+temp+", ax\n";
                    }
                    
                    else if($2->getname()=="%")
                    {
                        $$->asmcode += "    mov ax, "+$1->asmvar+"\n"+"    cwd\n";
                        
                        if($3->asmvar==$3->srccode)
                        {
                            string temp = newTemp();
                            asmstring[data_seg] += "    "+temp+" dw ?\n";
                            $$->asmcode += "    mov "+temp+", "+$3->asmvar+"\n";
                            $$->asmcode += "    idiv "+temp+"\n";
                        }
                        else $$->asmcode += "   idiv "+$3->asmvar+"\n";
                        
                        $$->asmcode += "    mov "+temp+", dx\n";
                    }
                    
                    
                    $$->asmvar=temp;
                }
     ;


unary_expression : ADDOP unary_expression  {
                        $$ = new entity();
                        $$->srccode= $1->getname()+$2->srccode;
                        $$->dtype = $2->dtype;
                        printRule("unary_expression : ADDOP unary_expression");
                        
                        if($2->dtype=="void") semanticError("Void function used in expression");
                        
                        printCode($$->srccode);
                    
                        string temp = newTemp();
                        asmstring[data_seg] += "    "+temp+" dw ?\n";
                    
                        $$->asmcode += $2->asmcode;
                        
                        $$->asmcode += "    mov ax, "+$2->asmvar+"\n";
                        if($1->getname()=="-") $$->asmcode += "    neg ax\n";
                        $$->asmcode += "    mov "+temp+", ax\n";
                        
                        $$->asmvar = temp;
                    }  

		 | NOT unary_expression  {
		                            $$ = new entity();
                                    $$->srccode = "!"+$2->srccode;
                                    $$->dtype = $2->dtype;
                                    printRule("unary_expression : NOT unary_expression");
                                    
                                    if($2->dtype=="void") semanticError("Void function used in expression");
                                    
                                    printCode($$->srccode);
                    
                                    string temp = newTemp();
                                    asmstring[data_seg] += "    "+temp+" dw ?\n";
                                
                                    $$->asmcode += $2->asmcode;
                                    
                                    $$->asmcode += "    mov ax, "+$2->asmvar+"\n";
                                    $$->asmcode += "    not ax\n";
                                    $$->asmcode += "    mov "+temp+", ax\n";
                                    
                                    $$->asmvar = temp;
                                 }
		 
		 | factor  {
		                $$ = new entity();
                        $$->srccode = $1->srccode;
                        $$->dtype = $1->dtype;
                        printRule("unary_expression : factor");
                        printCode($$->srccode);
                        
                        $$->asmcode = $1->asmcode;
                        $$->asmvar=$1->asmvar;
                   }
		 ;
	
	
factor : variable  {
                        $$ = new entity();
                        $$->srccode = $1->srccode;
                        $$->dtype = $1->dtype;
                        printRule("factor : variable");
                        printCode($$->srccode);
                        
                        $$->asmcode = $1->asmcode;
                        $$->asmvar = $1->asmvar;
                   }
                   
	| ID LPAREN argument_list RPAREN  {
                    $$ = new entity();
                    $$->srccode = $1->getname() + "(" + getStrFromArgVector(*$3) + ")";

                    printRule("factor : ID LPAREN argument_list RPAREN");
                    
                    SymbolInfo* si = symtab.Search($1->getname());
                    if(si==NULL) 
                    {
                        semanticError("Undeclared function "+$1->getname());
                    }
                    else
                    {
                        FunctionInformation* fi = si->getFuncInfo();
                        if(fi==NULL)
                        {
                            semanticError($1->getname()+" is a non-function type identifier");
                        }
                        else if(fi->isDeclared==true && fi->isDefined==false)
                        {
                            semanticError("Undefined function "+$1->getname());
                        }
                        else
                        {
                            $$->dtype = fi->returnTypeDefinition;
                            if($3->size()!=fi->vpar_definition->size())
                            {
                                semanticError("Total number of arguments mismatch in function "+$1->getname());
                            }
                            else
                            {
                                for(int i=0;i<$3->size();i++)
                                {                         
                                    if($3->at(i)->dtype!=fi->vpar_definition->at(i).dtype)
                                    {
                                        semanticError(getCardinal(i+1)+" argument mismatch in function "+$1->getname());
                                        
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    
                    printCode($$->srccode);
                    
                    for(int i=0;i<$3->size();i++)
                    {
                        entity* en = $3->at(i);
                        $$->asmcode += en->asmcode; 
                        $$->asmcode += "    mov ax, "+en->asmvar+"\n";
                        $$->asmcode += "    push ax\n";
                    }
                    
                    $$->asmcode += "    call "+$1->getname()+"\n";
                    
                    $$->asmvar = si->asmvar;
                    
                 }
                 
	| LPAREN expression RPAREN  {
                    $$ = new entity();
                    $$->srccode = "(" + $2->srccode + ")";
                    //$$->dtype = $2->dtype; expressn er type
                    printRule("factor : LPAREN expression RPAREN");
                    printCode($$->srccode);

                    $$->asmcode=$2->asmcode;
                    $$->asmvar=$2->asmvar;
                 }
                 
	
	| CONST_INT  {
	                $$ = new entity();
                    $$->srccode = $1->getname();
                    $$->dtype = "int";
                    printRule("factor : CONST_INT");
                    printCode($$->srccode);

                    //$$->asmcode=$1->getname();    
                    $$->asmvar=$1->getname();
                    
                            
                    /*string temp = newTemp();
                    $$->asmcode="mov "+temp+", "+$1->getname()+"\n";
                    asmstring[1]+="    "+temp+" dw ?\n";*/
                 }
                 
	| CONST_FLOAT  {
	                    $$ = new entity();
                        $$->srccode = $1->getname();
                        $$->dtype = "float";
                        printRule("factor : CONST_FLOAT");
                        printCode($$->srccode);
                   }
                   
	| variable INCOP  {
                        $$ = new entity();
                        $$->srccode = $1->srccode+"++";
                        $$->dtype = $1->dtype;
                        printRule("factor : variable INCOP");
                        printCode($$->srccode);
                        
                        $$->asmcode += $1->asmcode;
                        
                        string temp = newTemp();
                        asmstring[data_seg] += "    "+temp+" dw ?\n";
                        
                        $$->asmcode += "    mov ax, "+$1->asmvar+"\n";
                        $$->asmcode += "    mov "+temp+", ax\n";
                        
                        $$->asmvar = temp;
                        $$->asmcode += "    inc "+$1->asmvar+"\n";
                        
                        if($1->isArray == true)
	                    {
	                        $$->asmcode += "    mov ax, "+$1->asmvar+"\n";
	                        $$->asmcode += "    mov "+$1->asmvar_array+", ax\n";
	                    }
                        
                      }  
                   
	| variable DECOP  {
                        $$ = new entity();
                        $$->srccode = $1->srccode+"--";
                        $$->dtype = $1->dtype;
                        printRule("factor : variable DECOP");
                        printCode($$->srccode);
                        
                        $$->asmcode += $1->asmcode;
                        
                        string temp = newTemp();
                        asmstring[data_seg] += "    "+temp+" dw ?\n";
                        
                        $$->asmcode += "    mov ax, "+$1->asmvar+"\n";
                        $$->asmcode += "    mov "+temp+", ax\n";
                        
                        $$->asmvar = temp;
                        $$->asmcode += "    dec "+$1->asmvar+"\n";
                        
                        if($1->isArray == true)
	                    {
	                        $$->asmcode += "    mov ax, "+$1->asmvar+"\n";
	                        $$->asmcode += "    mov "+$1->asmvar_array+", ax\n";
	                    }
                      } 
	;
	
argument_list : arguments  {
                        $$ = new vector<entity*>();
                        *$$ = *$1;                        
                        printRule("argument_list : arguments");
                        printCode(getStrFromArgVector(*$$));
                    }
                    
			  |  {
			          $$ = new vector<entity*>();
			          printRule("argument_list : ");
			     }
			  ;
	
	
arguments : arguments COMMA logic_expression  {
                        $$ = new vector<entity*>();;
                        *$$ = *$1;
                        $$->push_back($3);
                        printRule("arguments : arguments COMMA logic_expression");
                        printCode(getStrFromArgVector(*$$));
                     }
                     
	      | logic_expression  {	
                        $$ = new vector<entity*>();;
                        $$->push_back($1);
                        printRule("arguments : logic_expression");
                        printCode(getStrFromArgVector(*$$));
                     }
	      ;
 

%%




int main(int argc,char *argv[])
{        
    logfile.open("log.txt");
    errorfile.open("error.txt");
    asmfile.open("code.asm");
    optimizedfile.open("optimized_code.asm");
    
  	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Can't open specified file\n");
		return 0;
	}
	
	
  
    
    asmstring[init_seg]=".MODEL SMALL\n\
.STACK 100H\n\n";
    
    asmstring[data_seg]=".DATA\n\
CR EQU 0DH\n\
LF EQU 0AH\n";

asmstring[print_proc]=".CODE\n\
    print_proc PROC         ;OUTPUT VALUE OF AX\n\
    PUSH AX\n\
    PUSH BX\n\
    PUSH CX\n\
    PUSH DX\n\
    PUSH AX\n\
    \n\
    POP AX     ;GET AX ORIGINAL VALUE\n\
    CMP AX,0   ;CHECK IF NEGATIVE\n\
    JGE POSITIVE\n\
    ;THEN\n\
    PUSH AX\n\
    MOV AH,2\n\
    MOV DL,'-'\n\
    INT 21H\n\
    POP AX     ;GET AX ORIGINAL VALUE\n\
    NEG AX\n\
    \n\
POSITIVE:\n\
    ;DIVIDEND = RESULT*10 + QUOTIENT\n\
    MOV BX,10  ;HOLDS THE DIVISOR\n\
    MOV CX,0   ;COUNT NUMBER OF DIGITS\n\
    \n\
    REPEAT:\n\
    MOV DX,0  ; CLEAR DX\n\
    DIV BX    ; DIVIDE (DX:AX)/BX\n\
    PUSH DX   ;REMAINDER STORED IN DX\n\
    INC CX\n\
    \n\
    ;UNTIL\n\
    CMP AX,0   ;STOP WHEN QUOTIENT IS 0\n\
    JNE REPEAT  \n\
    \n\
    MOV AH,2\n\
    \n\
    PRINT_LOOP:\n\
    POP DX\n\
    ADD DL,30H\n\
    INT 21H\n\
    LOOP PRINT_LOOP\n\
    \n\
    MOV AH,2\n\
    MOV DL,CR\n\
    INT 21H \n\
    MOV DL,LF\n\
    INT 21H \n\
    \n\
    POP DX\n\
    POP CX\n\
    POP BX   \n\
    POP AX\n\
    RET\n\
    \n\
print_proc ENDP\n\n\n\n";
    
        
        
    	
	yyin= fin;
	yyparse();

	
    for(int i=0;i<30;i++)
        asmfile<<asmstring[i]<<"\n";
        
    for(int j=0;j<30;j++)
    {
        string str=asmstring[j];
        string line1="",line2="",com=""; //optimizedfile<<asmstring[j];
        
        for(int i=0;i<str.length();i++)
        {
            while(i<str.length())
            {
                line1+=str[i];
                if(str[i]=='\n')
                {
                    i++;
                    break;
                }
                i++;
            }
            if(str[i]==';')
            {
                while(i<str.length())
                {
                    com+=str[i];
                    if(str[i]=='\n')
                    {
                        i++;
                        break;
                    }
                    i++;
                }
            }
            while(i<str.length())
            {
                line2+=str[i];
                if(str[i]=='\n')
                {
                    //i++;
                    break;
                }
                i++;
            }
            
            bool f=check(line1,line2);
            if(f) optimizedfile<<line1<<com;
            else optimizedfile<<line1<<com<<line2;
            line1="";line2="";com="";
        }
        
    }
    
	
	if(error_count!=0 || syntax_error==1)
    {
        asmfile.close();
        optimizedfile.close();
        asmfile.open("code.asm",std::ofstream::out | std::ofstream::trunc);
        optimizedfile.open("code.asm",std::ofstream::out | std::ofstream::trunc);
    }
    
    
	fclose(yyin);
    logfile.close();
    errorfile.close();
    asmfile.close();
    optimizedfile.close();
	return 0;
}
