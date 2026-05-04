#ifndef INTERMEDIATE_H
#define INTERMEDIATE_H

#define FLAG_CONST 1
#define FLAG_VOLATILE 2
#define FLAG_TYPEDEF 4
#define FLAG_EXTERN 8
#define FLAG_STATIC 16
#define FLAG_AUTO 32
#define FLAG_REGISTER 64


#include "uthash.h"
#include <stdio.h>


typedef enum {
    TYPE_VOID,
    TYPE_CHAR,
    TYPE_SHORT,
    TYPE_INT,
    TYPE_LONG,
    TYPE_FLOAT,
    TYPE_DOUBLE,
    TYPE_SIGNED,
    TYPE_UNSIGNED,
    TYPE_STRUCT,
    TYPE_UNION,
    TYPE_ENUM,
    TYPE_ALIAS
} BaseType;

typedef enum {
    AST_VAR,
    AST_FOR, 
    AST_ASSIGN, 
    AST_IF,
    AST_WHILE,
    AST_BLOCK,
    AST_UNARY,
    AST_CONST,
    AST_STRING,
    AST_BINOP,
    AST_FUNC_CALL,
    AST_RETURN,
    AST_ENUM_CONST, // For future use when we add enum support
    AST_FUNCTION_DECL,
    AST_FUNCTION_DEF,
    AST_STRUCT_DEF,
    AST_TYPE,
    AST_MEMBER_ACCESS,
    AST_VAR_DECL,
    AST_ENUM_DEF
} ASTNodeType;

typedef struct SymbolTableEntry{
    char* name;  
    // To be extended later, for now we just store the variable name
    UT_hash_handle hh;
} SymbolTableEntry;

typedef struct ASTNode ASTNode;

struct ASTNode {

    ASTNodeType type; 
    union {
        struct {BaseType type; char* name; int flags;} type_container; // 
        struct {int value;} constant; // 
        struct {char* name; SymbolTableEntry* sym_entry;} variable; //
        struct {char* value;} string; // 
        struct {int op; ASTNode* left; ASTNode* right;} binop; //
        struct {int op; ASTNode* operand;} unary; //
        struct {ASTNode* var; int assignment_op; ASTNode* value;} assign; // 
        struct {ASTNode* condition; ASTNode* if_body; ASTNode* else_branch;} if_stmt; // 
        struct {ASTNode* init; ASTNode* condition; ASTNode* increment; ASTNode* body;} for_stmt; // 
        struct {ASTNode* condition; ASTNode* body;} while_stmt; // 
        struct {ASTNode** statements; int count; int capacity;} block; // 
        struct {char* func_name; ASTNode* args;} function_call; // 
        struct {ASTNode* return_value;} return_stmt; // 
        struct {char* name; ASTNode* value;} enum_const; // 
        struct {char* name; int flags; int pointer_count; BaseType type; ASTNode* init_value;} variable_decl;  //
        struct {char* name; int flags; int pointer_count; ASTNode* args; BaseType return_type;} function_decl; // 
        struct {ASTNode* declaration; ASTNode* body;} function_def; // 
        struct {char* name; ASTNode* body; int is_union;} struct_def; // 
        struct {char* name; ASTNode* body;} enum_def; // 
        struct {ASTNode *parent; char* field; int is_pointer;} member_access; // 
    } data; 
};


extern SymbolTableEntry* symbolTable;


void addObjectToBlockArray(ASTNode* blockNode, ASTNode* object);
ASTNode* createAssignNode(ASTNode* var, int assignment_op, ASTNode* value);
ASTNode* createASTNode(ASTNodeType type);
ASTNode* createBinOpNode(int op, ASTNode* left, ASTNode* right);
ASTNode* createBlockNode();
ASTNode* createConstantNode(int value);
ASTNode* createEnumConstNode(const char* name, ASTNode* value);
ASTNode* createEnumDefNode(const char* name, ASTNode* body);
ASTNode* createForNode(ASTNode* init, ASTNode* condition, ASTNode* increment, ASTNode* body);
ASTNode* createFunctionDeclNode(const char* name, int flags, int pointer_count, BaseType return_type, ASTNode* args);
ASTNode* createFunctionDefNode(ASTNode* declaration, ASTNode* body);
ASTNode* createFunctionCallNode(const char* func_name, ASTNode* args);
ASTNode* createIfNode(ASTNode* condition, ASTNode* if_body, ASTNode* else_branch);
ASTNode* createMemberAccessNode(ASTNode* parent, const char* field, int is_pointer);
ASTNode* createReturnNode(ASTNode* return_value);
ASTNode* createSimpleTypeNode(BaseType type, int flags);
ASTNode* createStringNode(const char* value);
ASTNode* createStructDefNode(const char* name, int is_union, ASTNode* body);
ASTNode* createTypeDefNode(const char* name, BaseType type, int flags);
ASTNode* createTypeNode(BaseType type, const char* name, int flags);
ASTNode* createUnaryNode(int op, ASTNode* operand);
ASTNode* createVarDeclNode(const char* name, int flags, int pointer_count, BaseType type, ASTNode* init_value);
ASTNode* createVariableNode(const char* name);
ASTNode* createWhileNode(ASTNode* condition, ASTNode* body);
SymbolTableEntry *SymbolTableAdd(const char* name);
SymbolTableEntry *SymbolTableFind(const char* name);
void printAST(ASTNode* node, int parent_id, FILE* out);
const char* getTypeName(BaseType type);


#endif
