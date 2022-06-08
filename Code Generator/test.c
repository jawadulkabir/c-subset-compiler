int a;
int func(int fred)
{
    if(fred==0) return 1;
    else return func(fred-1)*fred;
}

int main(){
    int a,b,c[7]; int x;
    x=100;
    a=3+23;{int b; b=62*43; printf(b);}
    
    
    c[0]=12;
    x=c[0];
    printf(x);
    
    printf(a);
    c[5]=a>7;
    println(b);
    if(a>30) x=600;
    else x=812;
    printf(x);
    
    x++;
    printf(x);
    
    c[4]++;

    c[2]=c[5]+c[4];
    
    x=c[2];
    printf(x);
    
    x=5;
    while(x<33){
        printf(x);
        x = x+7;
    }
    
    int i;
    for(i=0;i<5;i++)
    {printf(i);}
    
    int jaw;
    jaw=34;
    x=jaw++;
    printf(x);
    printf(jaw);
    
    x=jaw--;
    printf(x);
    printf(jaw);
    
    int xx;
    x=500;
    printf(x);
    xx=-x;
    printf(xx);
    
    int y;
    y=y+x;
    printf(y);
    
    y=y*y;
    printf(y);
}
