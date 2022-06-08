%{
#include<bits/stdc++.h>
 using namespace std;
 
#include "symbol_table.h"

#define BUCKET_SIZE 30

int yylex(void);
extern FILE *yyin;
ofstream logfile;
ofstream errorfile;

extern int line_count;
extern int error_count;

SymbolTable symtab(BUCKET_SIZE);

int func_scope=0;
string currentFunc;;


void yyerror(char *s)
{
	//write your code
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
        s += varg.at(i)->code+",";
    }
    s += varg.at(i)->code;
    
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
%type <str> var_declaration type_specifier expression_statement statement compound_statement statements func_declaration func_definition program unit func_param_scope_start func_param_end
%type <en> variable factor unary_expression term simple_expression rel_expression logic_expression expression
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
		            *$$ = *$1 + *$2 + "\n";
                        
                    symtab.printAllScopeTable(logfile);
                    symtab.exitScope();	 
                    
                    if($1->substr($1->length()-2,$1->length())=="()")
                    {
                        printRule("func_definition : type_specifier ID LPAREN RPAREN compound_statement");
                    }
		            else 
		            {
		                printRule("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
		            }
		            printCode(*$$); 	      
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
                        $$ = new string;
                        *$$="{\n";
                        *$$ += *$2 + "}";
                        
                        printRule("compound_statement : LCURL statements RCURL");
                        printCode(*$$);
                        
                    }
                    
 		    | scope_start scope_end {
                        $$ = new string;
                        *$$="{\n}";          
                        
                        printRule("compound_statement : LCURL RCURL");
                        printCode(*$$);             
                        
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
                            $$ = new string;
                            *$$ = *$1 + "\n";
                            printRule("statements : statement");
                            printCode(*$$);
                        }
	   | statements statement  {
                        $$ = new string;
                        *$$ = *$1;
                        *$$ += *$2 + "\n";
                        printRule("statements : statements statement");
                        printCode(*$$);
                     }
	   ;
	   
	   
	   
statement : var_declaration  {
	                $$ = new string;
	                *$$ = *$1;
                    printRule("statement : var_declaration");
                    printCode(*$$);
                 }
                 
	  | expression_statement  {
	                $$ = new string;
	                *$$ = *$1;
	                printRule("statement : expression_statement");
                    printCode(*$$);
	             }
	  
	  | compound_statement  {
	                $$ = new string;
	                *$$ = *$1;
	                
	                symtab.printAllScopeTable(logfile);
                    symtab.exitScope();	 
                    
		            printRule("statement : compound_statement");
                    printCode(*$$);
	             }
	             
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement  {
	                $$ = new string;
	                *$$ = "for(";	
	                *$$ += *$3 + *$4 + $5->code + ")" + *$7;  	  
	                printRule("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");
                    printCode(*$$);
	             }
	  
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE  {
	                $$ = new string;
	                *$$="if ("+$3->code+")"+*$5;
	                printRule("statement : IF LPAREN expression RPAREN statement");
                    printCode(*$$);
                 }
	  | IF LPAREN expression RPAREN statement ELSE statement  {
	                $$ = new string;
	                *$$="if ("+$3->code+")"+*$5+"\nelse\n"+*$7;
	                printRule("statement : IF LPAREN expression RPAREN statement ELSE statement");
                    printCode(*$$);
                 }
	  
	  | WHILE LPAREN expression RPAREN statement  {
	                $$ = new string;
	                *$$ = "while (" + $3->code + ")" + *$5;  
	                printRule("statement : WHILE LPAREN expression RPAREN statement");
                    printCode(*$$);
	             }
	  
	  
	  | PRINTLN LPAREN ID RPAREN SEMICOLON  {
	                $$ = new string;
	                *$$ = "printf(";	
	                *$$ += $3->getname() + ");";  
                    
	                printRule("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");
	                
	                SymbolInfo* si = symtab.Search($3->getname());
                    if(si==NULL) semanticError("Undeclared variable "+$3->getname());
                    
                    printCode(*$$);
	             }
	  
	  | RETURN expression SEMICOLON  {
	                $$ = new string;
	                *$$ = "return " + $2->code + ";";
	                printRule("statement : RETURN expression SEMICOLON");
                    printCode(*$$);
	             }
	  ;
	  
	  
expression_statement : SEMICOLON  {
                                    $$ = new string;
                                    *$$ = ";";
                                    printRule("expression_statement : SEMICOLON");
                                    printCode(*$$);
                                  }	
                                  		
                                  		
			| expression SEMICOLON  {
			        $$ = new string;
			        *$$ = $1->code+";";
                    printRule("expression_statement : expression SEMICOLON");
                    printCode(*$$);
                 } 
			;
			
	  
variable : ID {
                $$ = new entity();
                $$->code = $1->getname();
                printRule("variable : ID"); 
                SymbolInfo* si = symtab.Search($1->getname());
                
                if(si==NULL) semanticError("Undeclared variable "+$1->getname());
                else
                {
                    $$->dtype = si->getDtype();//logfile<<si->getDtype()<<"pipipi"<<endl;
                    if(si->getArrayStatus()==true) semanticError("Type mismatch, "+$1->getname()+" is an array");
                   
                }
                printCode($$->code);
              }
              
              
	 | ID LTHIRD expression RTHIRD {
                    $$ = new entity();
                    $$->code = $1->getname()+"["+$3->code+"]";
                    printRule("variable : ID LTHIRD expression RTHIRD");  
                    
                    SymbolInfo* si = symtab.Search($1->getname());
                
                    if(si==NULL) semanticError("Undeclared variable "+$1->getname());
                    else
                    {
                        if(si->getArrayStatus()==false) semanticError($1->getname()+" not an array");
                        
                        if($3->dtype!="int") semanticError("Expression inside third brackets not an integer");
                        
                        if((si->getArrayStatus()==true)&&($3->dtype=="int")) $$->dtype = si->getDtype();
                    }
                    
                    printCode($$->code);
              }
	 ;
	 
expression : logic_expression  {
                                    $$ = new entity();
                                    $$->code = $1->code;
                                    $$->dtype = $1->dtype;
                                    printRule("expression : logic_expression");
                                    printCode($$->code);
                               } 
                               
	   | variable ASSIGNOP logic_expression  {
		                    $$ = new entity();
                            $$->code = $1->code + "=" + $3->code;
                            $$->dtype = $1->dtype;
                            printRule("expression : variable ASSIGNOP logic_expression");
                            
                            if(($1->dtype =="int" && $3->dtype =="float")) semanticError("Type Mismatch");
                            else if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                                
		                    printCode($$->code);
		                    
		                }
	   ;
	   
			
logic_expression : rel_expression  {
                                        $$ = new entity();
                                        $$->code = $1->code;
                                        $$->dtype = $1->dtype;
                                        printRule("logic_expression : rel_expression");
		                                printCode($$->code);
                                   }
                                   

		 | rel_expression LOGICOP rel_expression  {
		                    $$ = new entity();
                            $$->code = $1->code + $2->getname() + $3->code;
                            $$->dtype = "int";
                            printRule("logic_expression : rel_expression LOGICOP rel_expression");
                            
                            if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                            
		                    printCode($$->code);
		               }
		 ;
		 
			
rel_expression : simple_expression  {
                                        $$ = new entity();
                                        $$->code = $1->code;
                                        $$->dtype = $1->dtype;
                                        printRule("rel_expression : simple_expression");
		                                printCode($$->code);
                                    }


		| simple_expression RELOP simple_expression	 {
		                    $$ = new entity();
                            $$->code = $1->code+ $2->getname() + $3->code;
                            $$->dtype = "int";
                            printRule("rel_expression : simple_expression RELOP simple_expression");
                            
                            if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                            
		                    printCode($$->code);
		            }
		;
				
				
simple_expression : term  {
		                        $$ = new entity();
                                $$->code = $1->code;
                                $$->dtype = $1->dtype;
                                printRule("simple_expression : term");
                                printCode($$->code);
                          }
                                
                                
		  | simple_expression ADDOP term  {
		            $$ = new entity();
                    $$->code = $1->code + $2->getname() + $3->code;; 
                    
                    if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                    else if($1->dtype=="int" && $3->dtype=="int") $$->dtype = "int";
                    else if($1->dtype=="float" || $3->dtype=="float") $$->dtype = "float";
                    
                    printRule("simple_expression : simple_expression ADDOP term");
                    printCode($$->code);
               }
		  ;
					
term :	unary_expression  {
                                $$ = new entity();
                                $$->code = $1->code;
                                $$->dtype = $1->dtype;
                                printRule("term : unary_expression");
                                printCode($$->code);
                          }
                          
                          
     |  term MULOP unary_expression  {
                    $$ = new entity();
                    $$->code = $1->code + $2->getname() + $3->code;
                    
                    printRule("term : term MULOP unary_expression");
                    
                    if($1->dtype=="void"||$3->dtype=="void")  semanticError("Void function used in expression");
                    else
                    {
                        if($2->getname()=="%")
                        {
                            if($1->dtype=="float" || $3->dtype=="float") semanticError("Non-Integer operand on modulus operator");
                            else if($1->code=="0" || $3->code=="0") semanticError("Modulus by Zero");
                        }
                        else
                        {
                            if($1->dtype=="int" && $3->dtype=="int") $$->dtype = "int";
                            if($1->dtype=="float" || $3->dtype=="float") $$->dtype = "float";
                        }
                    }
                                       
                    
                    printCode($$->code);
                }
     ;


unary_expression : ADDOP unary_expression  {
                        $$ = new entity();
                        $$->code= $1->getname()+$2->code;
                        $$->dtype = $2->dtype;
                        printRule("unary_expression : ADDOP unary_expression");
                        
                        if($2->dtype=="void") semanticError("Void function used in expression");
                        
                        printCode($$->code);
                    }  

		 | NOT unary_expression  {
		                            $$ = new entity();
                                    $$->code = "!"+$2->code;
                                    $$->dtype = $2->dtype;
                                    printRule("unary_expression : NOT unary_expression");
                                    
                                    if($2->dtype=="void") semanticError("Void function used in expression");
                                    
                                    printCode($$->code);
                                 }
		 
		 | factor  {
		                $$ = new entity();
                        $$->code = $1->code;
                        $$->dtype = $1->dtype;
                        printRule("unary_expression : factor");
                        printCode($$->code);
                   }
		 ;
	
factor : variable  {
                        $$ = new entity();
                        $$->code = $1->code;
                        $$->dtype = $1->dtype;
                        printRule("factor : variable");
                        printCode($$->code);
                   }
                   
	| ID LPAREN argument_list RPAREN  {
                    $$ = new entity();
                    $$->code = $1->getname() + "(" + getStrFromArgVector(*$3) + ")";

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
                    
                    printCode($$->code);
                 }
                 
	| LPAREN expression RPAREN  {
                    $$ = new entity();
                    $$->code = "(" + $2->code + ")";
                    //$$->dtype = $2->dtype; expressn er type
                    printRule("factor : LPAREN expression RPAREN");
                    printCode($$->code);
                 }
                 
	
	| CONST_INT  {
	                $$ = new entity();
                    $$->code = $1->getname();
                    $$->dtype = "int";
                    printRule("factor : CONST_INT");
                    printCode($$->code);
                 }
                 
	| CONST_FLOAT  {
	                    $$ = new entity();
                        $$->code = $1->getname();
                        $$->dtype = "float";
                        printRule("factor : CONST_FLOAT");
                        printCode($$->code);
                   }
                   
	| variable INCOP  {
                        $$ = new entity();
                        $$->code = $1->code+"++";
                        $$->dtype = $1->dtype;
                        printRule("factor : variable INCOP");
                        printCode($$->code);
                      }  
                   
	| variable DECOP  {
                        $$ = new entity();
                        $$->code = $1->code+"--";
                        $$->dtype = $1->dtype;
                        printRule("factor : variable DECOP");
                        printCode($$->code);
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
	yyparse();
	fclose(yyin);
	return 0;
}
