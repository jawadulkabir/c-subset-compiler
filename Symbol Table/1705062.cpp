#include<iostream>
#include<cstdio>
#include<string>
#include<cmath>
#include<cstdlib>
#include<bits/stdc++.h>
#include<cstring>
#include<cstdio>
#define print(a) cout<< #a <<" --> "<<(a)<<endl

 using namespace std;

class SymbolInfo
{
    string name;
    string type;
    SymbolInfo* next;
public:
    SymbolInfo(string a,string b)
    {
        this->name = a;
        this->type = b;
        next=NULL;
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
        return name;
    }
    string gettype()
    {
        return type;
    }
    ~SymbolInfo()
    {
        //delete next;
    }

};


class ScopeTable
{
    int SIZE;
    string ID;
    vector<SymbolInfo*>linkedlist;
    ScopeTable* parentscope;
    int ChildScopeCount;

public:
    ScopeTable(int);
    ScopeTable(int,ScopeTable*);
    ~ScopeTable();
    bool Insert(string,string);
    bool Delete(string);
    SymbolInfo* Search(string);
    int h(string);
    ScopeTable* getparent();
    string getID();
    void setChildCount(int);
    int getChildCount();
    void printScopeTable();
};


ScopeTable::ScopeTable(int n) //constructor for global scope
{
    SIZE=n;
    ID="1";
    parentscope=NULL;
    ChildScopeCount=0;
    for(int i=0;i<SIZE;i++) linkedlist.push_back(NULL);
}

ScopeTable::ScopeTable(int n, ScopeTable* parent) //constructor for all the other scopes
{
    SIZE=n;
    parentscope=parent;
    ChildScopeCount=0;
    parentscope->setChildCount(parentscope->getChildCount()+1);
    ID=parentscope->getID()+"."+to_string(parentscope->getChildCount());
    for(int i=0;i<SIZE;i++) linkedlist.push_back(NULL);

}


int ScopeTable::h(string str)
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


bool ScopeTable::Insert(string key,string val)
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
        if(head->getname()==key)
        {
            cout<<"< "<<key<<", "<<val<<" > already exists in current ScopeTable"<<endl;
            return false;
        }
        while(temp2->getnext()!=NULL)
        {
            temp2=temp2->getnext();
            ChainPos++;
            if(temp2->getname()==key)
            {
                cout<<"< "<<key<<", "<<val<<" > already exists in current ScopeTable"<<endl;
                return false;
            }
        }
        temp2->setnext(temp);
    }

    cout<<"Inserted in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
    return true;

}


SymbolInfo* ScopeTable::Search(string str)
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
        if(temp->getname()==str)
        {
            cout<<"Found in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
            return temp;
        }

        while(temp->getnext()!=NULL)
        {
            temp=temp->getnext();
            ChainPos++;
            if(temp->getname()==str)
            {
                cout<<"Found in ScopeTable# "<<ID<<" at position "<<idx<<", "<<ChainPos<<endl;
                return temp;
            }
        }
        //cout<<"Not found"<<endl;
        return NULL;
    }

}

bool ScopeTable::Delete(string str)
{
    //Search(str);
    int idx=h(str); //print(idx);
    int ChainPos=0;

    SymbolInfo* head=linkedlist[idx];

    if(head==NULL)
    {
        cout<<str<<" not found"<<endl;
        return false;
    }
    else
    {
        SymbolInfo* temp;
        SymbolInfo* par;
        temp=head;
        if(temp->getname()==str)
        {
            linkedlist[idx]=temp->getnext();
            delete temp;
            cout<<"Deleted Entry "<<idx<<", "<<ChainPos<<" from current ScopeTable"<<endl;
            return true;
        }
        while(temp->getnext()!=NULL)
        {
            par=temp;
            temp=temp->getnext();
            ChainPos++;
            if(temp->getname()==str)
            {
                par->setnext(temp->getnext());
                delete temp;
                cout<<"Deleted Entry "<<idx<<", "<<ChainPos<<" from current ScopeTable"<<endl;
                return true;
            }
        }
        cout<<str<<" not found"<<endl;
        return false;
    }
}

ScopeTable* ScopeTable::getparent()
{
    return parentscope;
}


string ScopeTable::getID()
{
    return ID;
}

void ScopeTable::setChildCount(int c)
{
    ChildScopeCount=c;
}

int ScopeTable::getChildCount()
{
    return ChildScopeCount;
}

void ScopeTable::printScopeTable()
{
    cout<<"ScopeTable # "<<ID<<endl;
    for(int i=0;i<SIZE;i++)
    {
        cout<<i<<" -->  ";
        SymbolInfo* temp=linkedlist[i];

        while(temp!=NULL)
        {
            cout<<"< "<<temp->getname()<<" : "<<temp->gettype()<<" >  ";
            temp=temp->getnext();
        }
        cout<<endl;

    }
    cout<<endl<<endl;;
}

ScopeTable::~ScopeTable()
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



class SymbolTable
{
    int ScopeTableSize;
    ScopeTable* current;
    stack<ScopeTable*>stk;
public:
    SymbolTable(int);
    ~SymbolTable();
    void enterScope();
    void exitScope();
    bool Insert(string,string);
    bool Delete(string);
    SymbolInfo* Search(string);
    void printCurrentScopeTable();
    void printAllScopeTable();
};

SymbolTable::SymbolTable(int x) //create the global scope when symbol table is created //no parent scope for global scope
{
    ScopeTableSize=x;
    ScopeTable *scp = new ScopeTable(ScopeTableSize);
    current=scp;
    stk.push(current);
}

void SymbolTable::enterScope() //create all the other scopes
{
    ScopeTable *parent=stk.top();
    ScopeTable *scp = new ScopeTable(ScopeTableSize,parent);
    current=scp;
    stk.push(current);
    cout<<"New ScopeTable with id "<<current->getID()<<" created"<<endl;
}

void SymbolTable::exitScope()
{
    cout<<"ScopeTable with id "<<current->getID()<<" removed"<<endl;
    delete current;
    stk.pop();
    current=stk.top();
}

bool SymbolTable::Insert(string key,string val)
{
    bool flag = current->Insert(key,val);
    return flag;
}

bool SymbolTable::Delete(string str)
{
    bool flag = current->Delete(str);
    return flag;
}

SymbolInfo* SymbolTable::Search(string str)
{
    ScopeTable* now=current;
    while(now!=NULL)
    {
        SymbolInfo* x= now->Search(str);
        if(x!=NULL) return x;
        now=now->getparent();
    }
    cout<<"Not found"<<endl;
    return NULL;
}

void SymbolTable::printCurrentScopeTable()
{
    current->printScopeTable();
}

void SymbolTable::printAllScopeTable()
{
    ScopeTable* now=current;
    while(now!=NULL)
    {
        now->printScopeTable();
        now=now->getparent();
    }
}

SymbolTable::~SymbolTable()
{
    while(!stk.empty())
    {
        ScopeTable* temp= stk.top();
        stk.pop();
        delete temp;
    }
}



int main()
{
    freopen("input.txt","r",stdin);
    freopen("output.txt","w",stdout);

    int N; //N -->bucket size
    cin>>N;
    SymbolTable symtab(N);

    char c;
    string name,type;
    while(scanf("%c",&c)!=EOF)
    {
        if(c=='I')
        {
            cin>>name>>type;
            symtab.Insert(name,type);
        }
        else if(c=='L')
        {
            cin>>name;
            symtab.Search(name);
        }
        else if(c=='D')
        {
            cin>>name;
            symtab.Delete(name);
        }
        else if(c=='P')
        {
            char c2;
            cin>>c2;
            if(c2=='A') symtab.printAllScopeTable();
            else if(c2=='C') symtab.printCurrentScopeTable();
        }
        else if(c=='S')
        {
            symtab.enterScope();
        }
        else if(c=='E')
        {
            symtab.exitScope();
        }

    }
}
