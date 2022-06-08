bison -d -y 1705062.y
echo '1'
g++ -w -c -o y.o y.tab.c
echo '2'
flex -o lex.yy.cpp 1705062.l
echo '3'
g++ -w -c -o l.o lex.yy.cpp
echo '4'
g++ y.o l.o -lfl 
echo '5'
./a.out $1
