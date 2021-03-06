%{
	#include <node.h>
	#include <cstdio>
	#include <cstdlib>
	NBlock *programBlock;

	extern int yylex();
	void yyerror(const char *s){std::printf("[COMPILATION FAILED] %s\n", s); std::exit(1);}
%}

//Define what is what
%union{
	Node *node;
	NBlock *block;
	NExpression *expr;
	NStatement *stmt;
	NIdentifier *ident;
	NVariableDeclaration *var_decl;
	std::vector<NVariableDeclaration*> *varvec;
	std::vector<NExpression*> *exprvec;
	std::string *string;
	int token;
}

//Lexemes from lex
%token <string> TIDENTIFIER TINTEGER TDOUBLE TSTRING TTRUE TFALSE
%token <token> TCEQ TCNE TCLT TCLE TCGT TCGE TEQUAL
%token <token> TLPAREN TRPAREN TLBRACE TRBRACE TCOMMA TDOT
%token <token> TPLUS TMINUS TMUL TDIV TMOD
%token <token> TSEMI
%token <token> TIF TELSE TWHILE TFOR TRETURN

//Type of each token
%type <ident> ident
%type <expr> numeric expr addsub_expr multdiv_expr mod_expr primary_expression comparison_expr string boolean
%type <varvec> func_decl_args
%type <exprvec> call_args
%type <block> program stmts block
%type <stmt> stmt var_decl func_decl if_stmt while_stmt for_stmt return_stmt
%type <token> comparison


%left TCEQ TCNE TCLT TCLE TCGT TCGE TEQUAL
%left TPLUS TMINUS
%left TMUL TDIV
%left TMOD

%start program

%%

program
	: stmts {programBlock=$1;}
	;

stmts
	: stmt {$$=new NBlock(); $$->statements.push_back($<stmt>1);}
	| stmts stmt {$1->statements.push_back($<stmt>2);}
	;

stmt
	: var_decl TSEMI | func_decl | if_stmt | while_stmt | for_stmt | return_stmt TSEMI
	| expr TSEMI {$$=new NExpressionStatement(*$1);}
	;

block
	: TLBRACE stmts TRBRACE {$$=$2;}
	| TLBRACE TRBRACE {$$=new NBlock();}
	;

if_stmt
	: TIF TLPAREN expr TRPAREN block {$$=new NIfStatement(*$3, *$5);}
	| TIF TLPAREN expr TRPAREN block TELSE block {$$=new NIfStatement(*$3, *$5, $7);}
	;

while_stmt
	: TWHILE TLPAREN expr TRPAREN block {$$=new NWhileStatement(*$3, *$5);}
	;

return_stmt
	: TRETURN expr {$$=new NReturnStatement(*$2);}
	;

for_stmt
	: TFOR TLPAREN expr TSEMI expr TSEMI expr TRPAREN block 
		{$$=new NForStatement($3, $5, $7, *$9);}
	;

var_decl
	: ident ident {$$=new NVariableDeclaration(*$1, *$2);}
	| ident ident TEQUAL expr {$$=new NVariableDeclaration(*$1, *$2, $4);}
	;

func_decl
	: ident ident TLPAREN func_decl_args TRPAREN block 
		{$$=new NFunctionDeclaration(*$1, *$2, *$4, *$6); delete $4;}
	;

func_decl_args
	: {$$=new VariableList();}
	| var_decl {$$=new VariableList(); $$->push_back($<var_decl>1);}
	| func_decl_args TCOMMA var_decl {$1->push_back($<var_decl>3);}
	;

ident
	: TIDENTIFIER {$$=new NIdentifier(*$1); delete $1;}
	;

numeric
	: TINTEGER {$$=new NInteger(atol($1->c_str())); delete $1;}
	| TDOUBLE {$$=new NDouble(atof($1->c_str())); delete $1;}
	;

boolean : TTRUE {$$=new NBoolean(true);}
	| TFALSE {$$=new NBoolean(false);}
	;

string
	: TSTRING {$$=new NString(*$1); delete $1;}
	;

expr
	: ident TEQUAL expr {$$=new NAssignment(*$<ident>1, *$3);}
	| comparison_expr
	;

comparison_expr
	: addsub_expr
	| comparison_expr comparison addsub_expr {$$=new NBinaryOperator(*$1, $2, *$3);}
	;

addsub_expr
	: multdiv_expr
	| addsub_expr TPLUS multdiv_expr {$$=new NBinaryOperator(*$1, $2, *$3);}
	| addsub_expr TMINUS multdiv_expr {$$=new NBinaryOperator(*$1, $2, *$3);}
	;

multdiv_expr
	: mod_expr
	| multdiv_expr TMUL mod_expr {$$=new NBinaryOperator(*$1, $2, *$3);}
	| multdiv_expr TDIV mod_expr {$$=new NBinaryOperator(*$1, $2, *$3);}
	;

mod_expr
	: primary_expression
	| mod_expr TMOD primary_expression {$$=new NBinaryOperator(*$1, $2, *$3);}

primary_expression
	: ident TLPAREN call_args TRPAREN {$$=new NMethodCall(*$1, *$3); delete $3;}
	| ident {$<ident>$=$1;}
	| numeric
	| string
	| boolean
	| TLPAREN expr TRPAREN {$$=$2;}
	;

call_args : {$$=new ExpressionList();}
	| expr {$$=new ExpressionList(); $$->push_back($1);}
	| call_args TCOMMA expr {$1->push_back($3);}
	;

comparison : TCEQ | TCNE | TCLT | TCLE | TCGT | TCGE
	;

%%
