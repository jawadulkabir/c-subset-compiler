
//#ifndef SYMBOL_TABLE
// #define SYMBOL_TABLE


/******************************************************************************************


* SymbolInfo class start


******************************************************************************************/


class SymbolInfo
{
    string name;
    string type;
    SymbolInfo* next;
    
    string name_addon;
    string dtype;
    bool isMultiple;
    bool isArray;
    struct FunctionInformation* funcinfo;
public:
    SymbolInfo()
    {
        this->name = "";
        this->type = "";
        this->name_addon = "";
        this->dtype = "";
        next=NULL;
        isMultiple=false;
        isArray=false;
        funcinfo=NULL;
    }
    SymbolInfo(string a,string b)
    {
        this->name = a;
        this->type = b;
        this->name_addon = "";
        this->dtype = "";
        next=NULL;
        isMultiple=false;
        isArray=false;
    }
    SymbolInfo* getnext()
    {
        return next;
    }
    void setnext(SymbolInfo* ptr)
    {
        next=ptr;
    }
    string getname()
    {
        return name+name_addon;
    }
    string gettype()
    {
        return type;
    }
    void set_name_addon(string x)
    {        
        this->name_addon = x;
    }
    void setDtype(string x)
    {        
        this->dtype = x;
    }
    string getOriginalName()
    {
        return name;
    }
    string getDtype()
    {
        return dtype;
    }
    void setMultiple(bool f)
    {
        isMultiple = f;
    }
    bool getMultiple()
    {
        return isMultiple;
    }
    void setArrayStatus(bool f)
    {
        isArray = f;
    }
    bool getArrayStatus()
    {
        return isArray;
    }
    void setFuncInfo(FunctionInformation* f)
    {
        funcinfo = f;
    }
    FunctionInformation* getFuncInfo()
    {
        return funcinfo;
    }
    ~SymbolInfo()
    {
        //delete next;
    }

};




struct param{
    string dtype;
    SymbolInfo* var;
    
    param(string a)
    {
        dtype=a;
        var=NULL;
    }
    
    param(string a, SymbolInfo* b)
    {
        dtype=a;
        var=b;
    }
    
    string getstr()
    {
        string s=dtype;
        if(var!=NULL)
        {
            s += " "+var->getname();
        }
        return s;
    }
  };
  
struct entity{
    string dtype;
    string code;
    bool isArray;
    
    entity()
    {
        dtype="";
        code="";
        isArray=false;
    }
    entity(string a, string b)
    {
        dtype=a;
        code=b;
    }
  };
  
  
struct FunctionInformation{
    bool isDeclared;
    bool isDefined;
    vector<param>* vpar_declaration;
    vector<param>* vpar_definition;
    string returnType;
    string returnTypeDeclaration;
    string returnTypeDefinition;
    string returnedVarType;
    
    FunctionInformation()
    {
        vpar_declaration = new vector<param>();
        vpar_definition = new vector<param>();
        isDeclared = false;
        isDefined = false;
        returnType = "";
        returnedVarType = "";
        returnTypeDeclaration = "";
        returnTypeDefinition = "";
    }
    };

/******************************************************************************************


* ScopeTable class start


******************************************************************************************/


class ScopeTable
{
    int SIZE;
    string ID;
    vector<SymbolInfo*>linkedlist;
    ScopeTable* parentscope;
    int ChildScopeCount;

public:
    
ScopeTable(int n) //constructor for global scope
{
    SIZE=n;
    ID="1";
    parentscope=NULL;
    ChildScopeCount=0;
    for(int i=0;i<SIZE;i++) linkedlist.push_back(NULL);
}

ScopeTable(int n, ScopeTable* parent) //constructor for all the other scopes
{
    SIZE=n;
    parentscope=parent;
    ChildScopeCount=0;
    parentscope->setChildCount(parentscope->getChildCount()+1);
    ID=parentscope->getID()+"."+to_string(parentscope->getChildCount());
    for(int i=0;i<SIZE;i++) linkedlist.push_back(NULL);

}


int h(string str)
{
    int c,i=0,sum=0;
    while (i<str.length())
    {
        c=str[i]; //cout<<endl;cout<<c;
        sum+=c; //print(hash);
        sum%=SIZE;
        i++;
    }
    return sum;;
}


bool Insert(string key,string val)
{
    int idx=h(key); //print(idx);
    int ChainPos=0;

    SymbolInfo* temp;
    temp = new SymbolInfo(key,val);

    SymbolInfo* head=linkedlist[idx];

    if(head==NULL)
    {
        linkedlist[idx]=temp;
    }
    else
    {
        SymbolInfo* temp2;
        temp2=head;
        ChainPos++;
        if(head->getOriginalName()==key)
        {
            ///cout<<"< "<<key<<", "<<val<<" > already exists in current ScopeTable"<<endl;
            return false;
        }
        while(temp2->getnext()!=NULL)
        {
            temp2=temp2->getnext();
            ChainPos++;
            if(temp2->getOriginalName()==key)
            {
                ///cout<<"< "<<key<<", "<<val<<" > already exists in current ScopeTable"<<endl;
                return false;
            }
        }
        temp2->setnext(temp);
    }

    ///cout<<"Inserted in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
    return true;

}


bool Insert(SymbolInfo* si)
{
    string key=si->getOriginalName();
    string val=si->gettype();
    
    int idx=h(key); //print(idx);
    int ChainPos=0;

    SymbolInfo* temp;
    temp = si;

    SymbolInfo* head=linkedlist[idx];

    if(head==NULL)
    {
        linkedlist[idx]=temp;
    }
    else
    {
        SymbolInfo* temp2;
        temp2=head;
        ChainPos++;
        if(head->getOriginalName()==key)
        {
            ///cout<<"< "<<key<<", "<<val<<" > already exists in current ScopeTable"<<endl;
            return false;
        }
        while(temp2->getnext()!=NULL)
        {
            temp2=temp2->getnext();
            ChainPos++;
            if(temp2->getOriginalName()==key)
            {
                ///cout<<"< "<<key<<", "<<val<<" > already exists in current ScopeTable"<<endl;
                return false;
            }
        }
        temp2->setnext(temp);
    }

    ///cout<<"Inserted in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
    return true;
}



SymbolInfo* Search(string str)
{
    int idx=h(str); //print(idx);
    int ChainPos=0;

    SymbolInfo* head=linkedlist[idx];

    if(head==NULL)
    {
        //cout<<"Not found"<<endl;
        return NULL;
    }
    else
    {
        SymbolInfo* temp;
        temp=head;
        if(temp->getOriginalName()==str)
        {
            ///cout<<"Found in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
            return temp;
        }

        while(temp->getnext()!=NULL)
        {
            temp=temp->getnext();
            ChainPos++;
            if(temp->getOriginalName()==str)
            {
                ///cout<<"Found in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
                return temp;
            }
        }
        //cout<<"Not found"<<endl;
        return NULL;
    }

}


void setDtype(string str,string dtype)
{
    int idx=h(str); //print(idx);
    int ChainPos=0;

    SymbolInfo* head=linkedlist[idx];

    
    SymbolInfo* temp;
    temp=head;
    if(temp->getOriginalName()==str)
    {
        ///cout<<"Found in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
        temp->setDtype(dtype);
        return;
    }

    while(temp->getnext()!=NULL)
    {
        temp=temp->getnext();
        ChainPos++;
        if(temp->getOriginalName()==str)
        {
            ///cout<<"Found in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
            temp->setDtype(dtype);
            return;
        }
    }
}



void setFuncInfo(string str,FunctionInformation* f)
{
    int idx=h(str); //print(idx);
    int ChainPos=0;

    SymbolInfo* head=linkedlist[idx];

    
    SymbolInfo* temp;
    temp=head;
    if(temp->getOriginalName()==str)
    {
        ///cout<<"Found in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
        temp->setFuncInfo(f);
        return;
    }

    while(temp->getnext()!=NULL)
    {
        temp=temp->getnext();
        ChainPos++;
        if(temp->getOriginalName()==str)
        {
            ///cout<<"Found in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
            temp->setFuncInfo(f);
            return;
        }
    }
}

bool Delete(string str)
{
    //Search(str);
    int idx=h(str); //print(idx);
    int ChainPos=0;

    SymbolInfo* head=linkedlist[idx];

    if(head==NULL)
    {
        ///cout<<str<<" not found"<<endl;
        return false;
    }
    else
    {
        SymbolInfo* temp;
        SymbolInfo* par;
        temp=head;
        if(temp->getOriginalName()==str)
        {
            linkedlist[idx]=temp->getnext();
            delete temp;
            ///cout<<"Deleted Entry "<<idx<<", "<<ChainPos<<" from current ScopeTable"<<endl;
            return true;
        }
        while(temp->getnext()!=NULL)
        {
            par=temp;
            temp=temp->getnext();
            ChainPos++;
            if(temp->getOriginalName()==str)
            {
                par->setnext(temp->getnext());
                delete temp;
                ///cout<<"Deleted Entry "<<idx<<", "<<ChainPos<<" from current ScopeTable"<<endl;
                return true;
            }
        }
        ///cout<<str<<" not found"<<endl;
        return false;
    }
}

ScopeTable* getparent()
{
    return parentscope;
}


string getID()
{
    return ID;
}

void setChildCount(int c)
{
    ChildScopeCount=c;
}

int getChildCount()
{
    return ChildScopeCount;
}

void printScopeTable(ofstream& file)
{
    file<<"ScopeTable # "<<ID<<endl;
    for(int i=0;i<SIZE;i++)
    {
        //file<<i<<" -->  ";
        SymbolInfo* temp=linkedlist[i];
        
        if(temp==NULL) continue;
        file<<" "<<i<<" --> ";

        while(temp!=NULL)
        {
            file<<"< "<<temp->getOriginalName()<<" , "<<temp->gettype()<<" >  ";
            temp=temp->getnext();
        }
        file<<endl;

    }
    file<<endl;
}

~ScopeTable()
{
    for(int i=0;i<SIZE;i++)
    {
        SymbolInfo* temp = linkedlist[i];
        SymbolInfo* temp2;
        while(temp!=NULL)
        {
            temp2=temp;
            temp=temp->getnext();
            delete temp2;
        }
    }

}   
};




/******************************************************************************************


* SymbolTable class start


******************************************************************************************/


class SymbolTable
{
    int ScopeTableSize;
    ScopeTable* current;
    stack<ScopeTable*>stk;
public:
   
SymbolTable(int x) //create the global scope when symbol table is created //no parent scope for global scope
{
    ScopeTableSize=x;
    ScopeTable *scp = new ScopeTable(ScopeTableSize);
    current=scp;
    stk.push(current);
    ///cout<<"symboltable created\n";
}

void enterScope() //create all the other scopes
{
    ScopeTable *parent=stk.top();
    ScopeTable *scp = new ScopeTable(ScopeTableSize,parent);
    current=scp;
    stk.push(current);
    ///cout<<"New ScopeTable with id "<<current->getID()<<" created"<<endl;
}

void exitScope()
{
    ///cout<<"ScopeTable with id "<<current->getID()<<" removed"<<endl;
    delete current;
    stk.pop();
    current=stk.top();
}

bool Insert(string key,string val)
{
    bool flag = current->Insert(key,val);
    return flag;
}
bool Insert(SymbolInfo* si)
{
    bool flag = current->Insert(si);
    return flag;
}


bool Delete(string str)
{
    bool flag = current->Delete(str);
    return flag;
}

SymbolInfo* Search(string str)
{
    ScopeTable* now=current;
    while(now!=NULL)
    {
        SymbolInfo* x= now->Search(str);
        if(x!=NULL) return x;
        now=now->getparent();
    }
    ///cout<<"Not found"<<endl;
    return NULL;
}



void setDtype(string str,string dtype)
{
    ScopeTable* now=current;
    while(now!=NULL)
    {
        SymbolInfo* x= now->Search(str);
        if(x!=NULL) 
        {
            now->setDtype(str,dtype);
            return;
        }
        now=now->getparent();
    }
}


void setFuncInfo(string str,FunctionInformation* f)
{
    ScopeTable* now=current;
    while(now!=NULL)
    {
        SymbolInfo* x= now->Search(str);
        if(x!=NULL) 
        {
            now->setFuncInfo(str,f);
            return;
        }
        now=now->getparent();
    }
}


void printCurrentScopeTable(ofstream& file)
{
    current->printScopeTable(file);
}

void printAllScopeTable(ofstream& file)
{
    ScopeTable* now=current;
    while(now!=NULL)
    {
        now->printScopeTable(file);
        now=now->getparent();
    }

}

~SymbolTable()
{
    while(!stk.empty())
    {
        ScopeTable* temp= stk.top();
        stk.pop();
        delete temp;
    }
}

};






//#endif // SYMBOL_TABLE
