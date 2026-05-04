%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "intermediate.h"

char *input_filename = NULL;
char *output_filename = "a.c";

int yylex();
void yyerror(const char *s);
ASTNode* finalAST;

%}

%union {
	int int_val;
	char* str_val;
	ASTNode* ast_node;
	// SymbolTableEntry*  symb_entry;
}


%token <str_val> IDENTIFIER STRING_LITERAL TYPE_NAME
%token <int_val> CONSTANT
%token SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN

%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%type <ast_node> primary_expression postfix_expression argument_expression_list unary_expression
%type <ast_node> cast_expression constant_expression direct_abstract_declarator labeled_statement 
%type <ast_node> struct_declarator enumerator direct_declarator struct_declarator_list struct_declaration
%type <ast_node> struct_or_union_specifier struct_declaration_list type_specifier declaration_specifiers
%type <ast_node> multiplicative_expression additive_expression shift_expression relational_expression 
%type <ast_node> equality_expression and_expression exclusive_or_expression inclusive_or_expression 
%type <ast_node> logical_and_expression logical_or_expression conditional_expression enumerator_list
%type <ast_node> assignment_expression expression declaration specifier_qualifier_list enum_specifier
%type <ast_node> statement statement_list selection_statement iteration_statement compound_statement 
%type <ast_node> function_definition external_declaration translation_unit type_name declarator
%type <ast_node> init_declarator abstract_declarator parameter_declaration init_declarator_list 
%type <ast_node> parameter_list parameter_type_list expression_statement initializer declaration_list
%type <ast_node> jump_statement initializer_list identifier_list

%type <int_val> type_qualifier storage_class_specifier unary_operator type_qualifier_list assignment_operator pointer struct_or_union 

%start translation_unit
%%

primary_expression
	: IDENTIFIER {$$ = createVariableNode($1);}
	| CONSTANT {$$ = createConstantNode($1);}
	| STRING_LITERAL {$$ = createStringNode($1);}
	| '(' expression ')' {$$ = $2;}
	;

postfix_expression
	: primary_expression {$$ = $1;}
	| postfix_expression '[' expression ']' {$$ = createBinOpNode('[', $1, $3);}
	| postfix_expression '(' ')' { $$ = createFunctionCallNode($1->data.variable.name, createBlockNode()); }
	| postfix_expression '(' argument_expression_list ')' { $$ = createFunctionCallNode($1->data.variable.name, $3); }
	| postfix_expression '.' IDENTIFIER {$$ = createMemberAccessNode($1, $3, 0);}
	| postfix_expression PTR_OP IDENTIFIER {$$ = createMemberAccessNode($1, $3, 1);}
	| postfix_expression INC_OP {$$ = createUnaryNode(INC_OP, $1);}
	| postfix_expression DEC_OP {$$ = createUnaryNode(DEC_OP, $1);}
	;

argument_expression_list
	: assignment_expression { $$ = createBlockNode(); 
	addObjectToBlockArray($$, $1); }
	| argument_expression_list ',' assignment_expression { addObjectToBlockArray($1, $3); $$ = $1;}
	;

unary_expression
	: postfix_expression {$$ = $1;}
	| INC_OP unary_expression {$$ = createUnaryNode(INC_OP, $2);}
	| DEC_OP unary_expression {$$ = createUnaryNode(DEC_OP, $2);}
	| unary_operator cast_expression {$$ = createUnaryNode($1, $2);}
	| SIZEOF unary_expression {$$ = createUnaryNode(SIZEOF, $2);}
	| SIZEOF '(' type_name ')' {$$ = createUnaryNode(SIZEOF, $3);}
	;

unary_operator
	: '&' {$$ = '&';}
	| '*' {$$ = '*';}
	| '+' {$$ = '+';}
	| '-' {$$ = '-';}
	| '~' {$$ = '~';}
	| '!' {$$ = '!';}
	;

cast_expression
	: unary_expression {$$ = $1;}
	| '(' type_name ')' cast_expression {$$ = createBinOpNode('(', $2, $4);}
	;

multiplicative_expression
	: cast_expression {$$ = $1;}
	| multiplicative_expression '*' cast_expression {$$ = createBinOpNode('*', $1, $3);}
	| multiplicative_expression '/' cast_expression {$$ = createBinOpNode('/', $1, $3);}
	| multiplicative_expression '%' cast_expression {$$ = createBinOpNode('%', $1, $3);}
	;

additive_expression
	: multiplicative_expression {$$ = $1;}
	| additive_expression '+' multiplicative_expression {$$ = createBinOpNode('+', $1, $3);}
	| additive_expression '-' multiplicative_expression {$$ = createBinOpNode('-', $1, $3);}
	;

shift_expression
	: additive_expression {$$ = $1;}
	| shift_expression LEFT_OP additive_expression {$$ = createBinOpNode(LEFT_OP, $1, $3);}
	| shift_expression RIGHT_OP additive_expression {$$ = createBinOpNode(RIGHT_OP, $1, $3);}
	;

relational_expression
	: shift_expression {$$ = $1;}
	| relational_expression '<' shift_expression {$$ = createBinOpNode('<', $1, $3);}
	| relational_expression '>' shift_expression {$$ = createBinOpNode('>', $1, $3);}
	| relational_expression LE_OP shift_expression {$$ = createBinOpNode(LE_OP, $1, $3);}
	| relational_expression GE_OP shift_expression {$$ = createBinOpNode(GE_OP, $1, $3);}
	;

equality_expression
	: relational_expression {$$ = $1;}
	| equality_expression EQ_OP relational_expression {$$ = createBinOpNode(EQ_OP, $1, $3);}
	| equality_expression NE_OP relational_expression {$$ = createBinOpNode(NE_OP, $1, $3);}
	;

and_expression
	: equality_expression {$$ = $1;}
	| and_expression '&' equality_expression {$$ = createBinOpNode('&', $1, $3);}
	;

exclusive_or_expression
	: and_expression {$$ = $1;}
	| exclusive_or_expression '^' and_expression {$$ = createBinOpNode('^', $1, $3);}
	;

inclusive_or_expression
	: exclusive_or_expression {$$ = $1;}
	| inclusive_or_expression '|' exclusive_or_expression {$$ = createBinOpNode('|', $1, $3);}
	;

logical_and_expression
	: inclusive_or_expression {$$ = $1;}
	| logical_and_expression AND_OP inclusive_or_expression {$$ = createBinOpNode(AND_OP, $1, $3);}
	;

logical_or_expression
	: logical_and_expression {$$ = $1;}
	| logical_or_expression OR_OP logical_and_expression {$$ = createBinOpNode(OR_OP, $1, $3);}
	;

conditional_expression
	: logical_or_expression {$$ = $1;}
	| logical_or_expression '?' expression ':' conditional_expression {$$ = createIfNode($1, $3, $5);} // probably needs fixing
	;

assignment_expression
	: conditional_expression {$$ = $1;}
	| unary_expression assignment_operator assignment_expression {$$ = createAssignNode($1, $2, $3);} 
	;

assignment_operator
	: '='{$$ = '=';}
	| MUL_ASSIGN {$$ = MUL_ASSIGN;}
	| DIV_ASSIGN {$$ = DIV_ASSIGN;}
	| MOD_ASSIGN {$$ = MOD_ASSIGN;}
	| ADD_ASSIGN {$$ = ADD_ASSIGN;}
	| SUB_ASSIGN {$$ = SUB_ASSIGN;}
	| LEFT_ASSIGN {$$ = LEFT_ASSIGN;}
	| RIGHT_ASSIGN {$$ = RIGHT_ASSIGN;}
	| AND_ASSIGN {$$ = AND_ASSIGN;}
	| XOR_ASSIGN {$$ = XOR_ASSIGN;}
	| OR_ASSIGN {$$ = OR_ASSIGN;}
	;

expression
	: assignment_expression {$$ = createBlockNode(); addObjectToBlockArray($$, $1);}
	| expression ',' assignment_expression {addObjectToBlockArray($1, $3); $$ = $1;}
	;

constant_expression
	: conditional_expression {$$ = $1;}
	;

declaration
	: declaration_specifiers ';' {$$ = $1}
	| declaration_specifiers init_declarator_list ';' 
	
		{ for (int i = 0; i < $2->data.block.count; i++) {
		ASTNode* decl = $2->data.block.statements[i];
		
		if (decl->type == AST_ASSIGN) {
			decl->data.assign.var->data.variable_decl.type = $1->data.type_container.type;
			decl->data.assign.var->data.variable_decl.flags |= $1->data.type_container.flags;
		} else {
			decl->data.variable_decl.type = $1->data.type_container.type;
			decl->data.variable_decl.flags |= $1->data.type_container.flags;
		}
		} 
      $$ = $2;}


	;

declaration_specifiers
	: storage_class_specifier {$$ = createSimpleTypeNode(TYPE_INT, $1);}
	| storage_class_specifier declaration_specifiers {$2->data.type_container.flags |= $1; $$ = $2;}
	| type_specifier {$$ = $1;}
	| type_specifier declaration_specifiers {$2->data.type_container.type = $1->data.type_container.type; $$ = $2;}
	| type_qualifier {$$ = createSimpleTypeNode(TYPE_INT, $1);}
	| type_qualifier declaration_specifiers {$2->data.type_container.flags |= $1; $$ = $2;}
	;

init_declarator_list
	: init_declarator {$$ = createBlockNode(); addObjectToBlockArray($$, $1);}
	| init_declarator_list ',' init_declarator {addObjectToBlockArray($1, $3); $$ = $1;}
	;

init_declarator
    : declarator { $$ = $1; }
    | declarator '=' initializer 
      {$1->data.variable_decl.init_value = $3; $$ = createAssignNode($1, '=', $3);}
    ;

storage_class_specifier
	: TYPEDEF {$$ = FLAG_TYPEDEF;}
	| EXTERN {$$ = FLAG_EXTERN;}
	| STATIC {$$ = FLAG_STATIC;}
	| AUTO {$$ = FLAG_AUTO;}
	| REGISTER {$$ = FLAG_REGISTER;}
	;

type_specifier
	: VOID {$$ = createSimpleTypeNode(TYPE_VOID, 0);}
	| CHAR {$$ = createSimpleTypeNode(TYPE_CHAR, 0);}
	| SHORT {$$ = createSimpleTypeNode(TYPE_SHORT, 0);}
	| INT {$$ = createSimpleTypeNode(TYPE_INT, 0);}
	| LONG {$$ = createSimpleTypeNode(TYPE_LONG, 0);}
	| FLOAT {$$ = createSimpleTypeNode(TYPE_FLOAT, 0);}
	| DOUBLE {$$ = createSimpleTypeNode(TYPE_DOUBLE, 0);}
	| SIGNED {$$ = createSimpleTypeNode(TYPE_SIGNED, 0);}
	| UNSIGNED {$$ = createSimpleTypeNode(TYPE_UNSIGNED, 0);}
	| struct_or_union_specifier {$$ = $1;}
	| enum_specifier {$$ = $1;}
	| TYPE_NAME {$$ = createTypeNode(TYPE_ALIAS, $1, 0);}
	;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}' {$$ = createStructDefNode($2, $1, $4)}
	| struct_or_union '{' struct_declaration_list '}' {$$ = createStructDefNode(NULL, $1, $3);}
	| struct_or_union IDENTIFIER {$$ = createStructDefNode($2, $1, NULL);} 
	;

struct_or_union
	: STRUCT {$$ = 0}
	| UNION {$$ = 1}
	;

struct_declaration_list
	: struct_declaration {$$ = createBlockNode(); addObjectToBlockArray($$, $1);}
	| struct_declaration_list struct_declaration {$$ = $1; addObjectToBlockArray($$, $2);}
	;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
		{	
		ASTNode* type_info = $1;
		ASTNode* decl_list = $2;
		for (int i = 0; i < decl_list->data.block.count; i++) {
			ASTNode* decl = decl_list->data.block.statements[i];
			
			decl->data.variable_decl.type = type_info->data.type_container.type;
			decl->data.variable_decl.flags |= type_info->data.type_container.flags;
		
		}
		$$ = $2;}
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list {$1->data.type_container.flags |= $2->data.type_container.flags; $$ = $1; }
	| type_specifier 
	| type_qualifier specifier_qualifier_list {$2->data.type_container.flags |= $1; $$ = $2; }
	| type_qualifier {$$ = createSimpleTypeNode(TYPE_INT, $1); }
	;

struct_declarator_list
	: struct_declarator {$$ = createBlockNode(); addObjectToBlockArray($$, $1);}
	| struct_declarator_list ',' struct_declarator {$$ = $1; addObjectToBlockArray($$, $3);}
	;

struct_declarator
	: declarator {
        $$ = createVarDeclNode($1->data.variable.name, 0, 0, TYPE_VOID, NULL);}
	| ':' constant_expression {
        $$ = createVarDeclNode("anonymous_bitfield", 0, 0, TYPE_INT, NULL);}
	| declarator ':' constant_expression {
        $$ = createVarDeclNode($1->data.variable.name, 0, 0, TYPE_INT, NULL);}
	;

enum_specifier
	: ENUM '{' enumerator_list '}' {$$ = createEnumDefNode(NULL, $3);}
	| ENUM IDENTIFIER '{' enumerator_list '}' {$$ = createEnumDefNode($2, $4);}
	| ENUM IDENTIFIER {$$ = createEnumDefNode($2, NULL);}
	;

enumerator_list
	: enumerator {$$ = createBlockNode(); addObjectToBlockArray($$, $1); }
	| enumerator_list ',' enumerator {$$ = $1; addObjectToBlockArray($$, $3);}
	;

enumerator
	: IDENTIFIER {$$ = createEnumConstNode($1, NULL);}
	| IDENTIFIER '=' constant_expression {$$ = createEnumConstNode($1, $3);}
	;

type_qualifier
	: CONST {$$ = FLAG_CONST;}
	| VOLATILE {$$ = FLAG_VOLATILE;}
	;

declarator
    : pointer direct_declarator 
      {$$ = createVarDeclNode($2->data.variable.name, 0, $1, TYPE_VOID, NULL);}
    | direct_declarator 
      {$$ = createVarDeclNode($1->data.variable.name, 0, 0, TYPE_VOID, NULL);}
    ;

direct_declarator
    : IDENTIFIER 
      {SymbolTableAdd($1); $$ = createVariableNode($1);}
    | '(' declarator ')' { $$ = $2; }
    | direct_declarator '[' constant_expression ']' { $$ = $1; /* Array support placeholder */ }
    | direct_declarator '[' ']' { $$ = $1; }
    | direct_declarator '(' parameter_type_list ')' { $$ = $1; }
    | direct_declarator '(' identifier_list ')' { $$ = $1; }
    | direct_declarator '(' ')' { $$ = $1; }
    ;

pointer
    : '*'  {$$ = 1;}
    | '*' type_qualifier_list {$$ = 1;}
    | '*' pointer {$$ = $2 + 1;}
    | '*' type_qualifier_list pointer {$$ = $3 + 1; }
    ;

type_qualifier_list
    : type_qualifier 
    | type_qualifier_list type_qualifier { $$ = $1 | $2; }
    ;

parameter_type_list
    : parameter_list { $$ = $1; }
    | parameter_list ',' ELLIPSIS { $$ = $1; } /* Placeholder for variadic support */
    ;

parameter_list
    : parameter_declaration 
      { 
        $$ = createBlockNode(); 
        addObjectToBlockArray($$, $1); 
      }
    | parameter_list ',' parameter_declaration 
      { 
        addObjectToBlockArray($1, $3); 
        $$ = $1; 
      }
    ;

parameter_declaration
    : declaration_specifiers declarator 
      {
        /* Using createVarDeclNode to represent the parameter */
        $$ = createVarDeclNode($2->data.variable.name, $1->data.type_container.flags, 0, $1->data.type_container.type, NULL);
      }
    | declaration_specifiers abstract_declarator { $$ = $1; }
    | declaration_specifiers { $$ = $1; }
    ;

identifier_list
    : IDENTIFIER 
      { 
        $$ = createBlockNode(); 
        addObjectToBlockArray($$, createVariableNode($1)); 
      }
    | identifier_list ',' IDENTIFIER 
      { 
        addObjectToBlockArray($1, createVariableNode($3)); 
        $$ = $1; 
      }
    ;

type_name
    : specifier_qualifier_list { $$ = $1; }
    | specifier_qualifier_list abstract_declarator { $$ = $1; }
    ;

abstract_declarator
    : pointer { $$ = createConstantNode($1); } /* Returns indirection level as a constant[cite: 2] */
    | direct_abstract_declarator { $$ = $1; }
    | pointer direct_abstract_declarator { $$ = $2; }
    ;

direct_abstract_declarator
    : '(' abstract_declarator ')' { $$ = $2; }
    | '[' ']' { $$ = createBlockNode(); }
    | '[' constant_expression ']' { $$ = $2; }
    | direct_abstract_declarator '[' ']' { $$ = $1; }
    | direct_abstract_declarator '[' constant_expression ']' { $$ = $1; }
    | '(' ')' { $$ = createBlockNode(); }
    | '(' parameter_type_list ')' { $$ = $2; }
    | direct_abstract_declarator '(' ')' { $$ = $1; }
    | direct_abstract_declarator '(' parameter_type_list ')' { $$ = $1; }
    ;

initializer
    : assignment_expression { $$ = $1; }
    | '{' initializer_list '}' { $$ = $2; }
    | '{' initializer_list ',' '}' { $$ = $2; }
    ;

initializer_list
    : initializer 
      { 
        $$ = createBlockNode(); 
        addObjectToBlockArray($$, $1); 
      }
    | initializer_list ',' initializer 
      { 
        addObjectToBlockArray($1, $3); 
        $$ = $1; 
      }
    ;

statement
    : labeled_statement | compound_statement | expression_statement 
    | selection_statement | iteration_statement | jump_statement
    ;

labeled_statement
    : IDENTIFIER ':' statement { $$ = $3; }
    | CASE constant_expression ':' statement { $$ = $4; }
    | DEFAULT ':' statement { $$ = $3; }
    ;

compound_statement
    : '{' '}' { $$ = createBlockNode(); }
    | '{' statement_list '}' { $$ = $2; }
    | '{' declaration_list '}' { $$ = $2; }
    | '{' declaration_list statement_list '}' 
      { 
        /* Merge declaration block into the statement block */
        for(int i = 0; i < $3->data.block.count; i++) {
            addObjectToBlockArray($2, $3->data.block.statements[i]);
        }
        $$ = $2;
      }
    ;

declaration_list
    : declaration 
      { 
        $$ = createBlockNode(); 
        addObjectToBlockArray($$, $1); 
      }
    | declaration_list declaration 
      { 
        addObjectToBlockArray($1, $2); 
        $$ = $1; 
      }
    ;

statement_list
    : statement 
      { 
        $$ = createBlockNode(); 
        addObjectToBlockArray($$, $1); 
      }
    | statement_list statement 
      { 
        addObjectToBlockArray($1, $2); 
        $$ = $1; 
      }
    ;

expression_statement
    : ';' { $$ = createBlockNode(); }
    | expression ';' { $$ = $1; }
    ;

selection_statement
    : IF '(' expression ')' statement 
      { $$ = createIfNode($3, $5, NULL); }
    | IF '(' expression ')' statement ELSE statement 
      { $$ = createIfNode($3, $5, $7); }
    | SWITCH '(' expression ')' statement { $$ = $5; }
    ;

iteration_statement
    : WHILE '(' expression ')' statement 
      { $$ = createWhileNode($3, $5); }
    | DO statement WHILE '(' expression ')' ';' 
      { $$ = createWhileNode($5, $2); }
    | FOR '(' expression_statement expression_statement ')' statement 
      { $$ = createForNode($3, $4, NULL, $6); }
    | FOR '(' expression_statement expression_statement expression ')' statement 
      { $$ = createForNode($3, $4, $5, $7); }
    ;

jump_statement
    : GOTO IDENTIFIER ';' { $$ = createVariableNode($2); }
    | CONTINUE ';' { $$ = createASTNode(AST_BLOCK); }
    | BREAK ';' { $$ = createASTNode(AST_BLOCK); }
    | RETURN ';' { $$ = createReturnNode(NULL); }
    | RETURN expression ';' { $$ = createReturnNode($2); }
    ;

translation_unit
    : external_declaration 
      { 
        finalAST = createBlockNode(); 
        addObjectToBlockArray(finalAST, $1); 
        $$ = finalAST;
      }
    | translation_unit external_declaration 
      { 
        addObjectToBlockArray(finalAST, $2); 
        $$ = finalAST; 
      }
    ;

external_declaration
    : function_definition { $$ = $1; }
    | declaration { $$ = $1; }
    ;

function_definition
    : declaration_specifiers declarator compound_statement
      { 
        ASTNode* decl = createFunctionDeclNode($2->data.variable_decl.name, 
                                               $1->data.type_container.flags, 
                                               $2->data.variable_decl.pointer_count, 
                                               $1->data.type_container.type, NULL);
        $$ = createFunctionDefNode(decl, $3); 
      }
    ;

%%
#include <stdio.h>

extern char yytext[];
extern int column;

void yyerror(const char *s)
  {
    fflush(stdout);
    printf("\n%*s\n%*s\n", column, "^", column, s);
  }

int main(int argc, char **argv)
{
  int i;

  for(i=1;i<argc;i++) {
    if (*argv[i]=='-') {
      switch(*(argv[i]+1)) {
        /* output option */
        case 'o':
          output_filename=argv[i]+2;
          break;

        default:
          fprintf(stderr,"%s: unknown argument option\n",argv[0]);
          exit(1);
      }
    } else {
      if (input_filename != NULL) {
        fprintf(stderr,"%s: only one input file allowed\n",argv[0]);
        exit(1);
        }
      input_filename = argv[i];
    }
  }

  if (input_filename != NULL) {
    if ((freopen(input_filename, "r",stdin))==NULL) {
      fprintf(stderr,"%s: cannot open input file %s\n",argv[0],input_filename);

      exit(1);
    }
  }

  i=yyparse();
  printf("\n--- Symbol Table ---\n");
  SymbolTableEntry *s;
  for (s = symbolTable; s != NULL; s = s->hh.next) {
    printf("Name: %s\n", s->name);
  }

  if (i==0){
    FILE* out = fopen("tree.dot", "w");
    fprintf(out, "digraph AST {\n");
    fprintf(stderr,"\nNo errors detected.\n");
    for (int j = 0; j < finalAST->data.block.count; j++) {
      ASTNode* node = finalAST->data.block.statements[j];
      printAST(node, 0, out);
    }
    fprintf(out, "}\n");
    fclose(out);
  }
  else {
    fprintf(stderr,"\nErrors detected.\n");
  }
  exit(i);
}

