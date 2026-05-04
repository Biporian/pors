#include "intermediate.h"
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define INITIAL_BLOCK_CAPACITY 4
#define INITIAL_FUNC_ARG_CAPACITY 4


SymbolTableEntry* symbolTable = NULL;

SymbolTableEntry* SymbolTableAdd(const char* name){
    SymbolTableEntry* entry;
    entry = malloc(sizeof(* entry));
    entry->name = strdup(name);
    HASH_ADD_KEYPTR(hh, symbolTable, entry->name, strlen(entry->name), entry);
    return entry;
}

SymbolTableEntry* SymbolTableFind(const char* name){
    SymbolTableEntry *entry;

    HASH_FIND_STR(symbolTable, name, entry);
    return entry;
}

ASTNode* createASTNode(ASTNodeType type){
    ASTNode* node;
    node = malloc(sizeof(* node));
    node->type = type;
    return node;
}

ASTNode* createConstantNode(int value){
    ASTNode* node = createASTNode(AST_CONST);
    node->data.constant.value = value;
    return node;
}

ASTNode* createVariableNode(const char* name){
    ASTNode* node = createASTNode(AST_VAR);
    node->data.variable.name = strdup(name);
    node->data.variable.sym_entry = NULL;
    return node;
}

ASTNode* createStringNode(const char* value){
    ASTNode* node = createASTNode(AST_STRING);
    node->data.string.value = strdup(value);
    return node;
}

ASTNode* createBinOpNode(int op, ASTNode* left, ASTNode* right){
    ASTNode* node = createASTNode(AST_BINOP);
    node->data.binop.op = op;
    node->data.binop.left = left;
    node->data.binop.right = right;
    return node;
}

ASTNode* createUnaryNode(int op, ASTNode* operand){
    ASTNode* node = createASTNode(AST_UNARY);
    node->data.unary.op = op;
    node->data.unary.operand = operand;
    return node;
}

ASTNode* createAssignNode(ASTNode* var, int assignment_op, ASTNode* value){
    ASTNode* node = createASTNode(AST_ASSIGN);
    node->data.assign.var = var;
    node->data.assign.assignment_op = assignment_op;
    node->data.assign.value = value;
    return node;
}

ASTNode* createIfNode(ASTNode* condition, ASTNode* if_body, ASTNode* else_branch){
    ASTNode* node = createASTNode(AST_IF);
    node->data.if_stmt.condition = condition;
    node->data.if_stmt.if_body = if_body;
    node->data.if_stmt.else_branch = else_branch;
    return node;
}

ASTNode* createForNode(ASTNode* init, ASTNode* condition, ASTNode* increment, ASTNode* body){
    ASTNode* node = createASTNode(AST_FOR);
    node->data.for_stmt.init = init;
    node->data.for_stmt.condition = condition;
    node->data.for_stmt.increment = increment;
    node->data.for_stmt.body = body;
    return node;
}

ASTNode* createWhileNode(ASTNode* condition, ASTNode* body){
    ASTNode* node = createASTNode(AST_WHILE);
    node->data.while_stmt.condition = condition;
    node->data.while_stmt.body = body;
    return node;
}

ASTNode* createBlockNode(){
    ASTNode* node = createASTNode(AST_BLOCK);
    node->data.block.statements = malloc(sizeof(ASTNode*) * INITIAL_BLOCK_CAPACITY);
    node->data.block.count = 0;
    node->data.block.capacity = INITIAL_BLOCK_CAPACITY;
    return node;
}


ASTNode* createFunctionCallNode(const char* func_name, ASTNode* args){
    ASTNode* node = createASTNode(AST_FUNC_CALL);
    node->data.function_call.func_name = strdup(func_name);
    node->data.function_call.args = args;
    return node;
}

ASTNode* createReturnNode(ASTNode* return_value){
    ASTNode* node = createASTNode(AST_RETURN);
    node->data.return_stmt.return_value = return_value;
    return node;
}

ASTNode* createEnumConstNode(const char* name, ASTNode* value){
    ASTNode* node = createASTNode(AST_ENUM_CONST);
    node->data.enum_const.name = name ? strdup(name) : NULL;
    node->data.enum_const.value = value;
    return node;
}

ASTNode* createTypeNode(BaseType type, const char* name, int flags){
    ASTNode* node = createASTNode(AST_TYPE);
    node->data.type_container.type = type;
    node->data.type_container.name = name ? strdup(name) : NULL;
    node->data.type_container.flags = flags;
    return node;
}

ASTNode* createSimpleTypeNode(BaseType type, int flags){
    return createTypeNode(type, NULL, flags);
}

ASTNode* createTypeDefNode(const char* name, BaseType type, int flags){
    return createTypeNode(type, name, flags);
}

ASTNode* createVarDeclNode(const char* name, int flags, int pointer_count, BaseType type, ASTNode* init_value){
    ASTNode* node = createASTNode(AST_VAR_DECL);
    node->data.variable_decl.name = strdup(name);
    node->data.variable_decl.flags = flags;
    node->data.variable_decl.pointer_count = pointer_count;
    node->data.variable_decl.type = type;
    node->data.variable_decl.init_value = init_value;
    return node;
}

ASTNode* createFunctionDeclNode(const char* name, int flags, int pointer_count, BaseType return_type, ASTNode* args){
    ASTNode* node = createASTNode(AST_FUNCTION_DECL);
    node->data.function_decl.name = strdup(name);
    node->data.function_decl.flags = flags;
    node->data.function_decl.pointer_count = pointer_count;
    node->data.function_decl.return_type = return_type;

    node->data.function_decl.args = args;
    return node;
}

ASTNode* createFunctionDefNode(ASTNode* declaration, ASTNode* body){
    ASTNode* node = createASTNode(AST_FUNCTION_DEF);
    node->data.function_def.declaration = declaration;
    node->data.function_def.body = body;
    return node;
}

ASTNode* createStructDefNode(const char* name, int is_union, ASTNode* body){
    ASTNode* node = createASTNode(AST_STRUCT_DEF);
    node->data.struct_def.name = name ? strdup(name) : NULL;
    node->data.struct_def.body = body;
    node->data.struct_def.is_union = is_union;
    return node;
}

ASTNode* createEnumDefNode(const char* name, ASTNode* body){
    ASTNode* node = createASTNode(AST_ENUM_DEF);
    node->data.enum_def.name = name ? strdup(name) : NULL;
    node->data.enum_def.body = body;
    return node;
}

ASTNode* createMemberAccessNode(ASTNode* parent, const char* field, int is_pointer){
    ASTNode* node = createASTNode(AST_MEMBER_ACCESS);
    node->data.member_access.parent = parent;
    node->data.member_access.field = strdup(field);
    node->data.member_access.is_pointer = is_pointer;
    return node;
}


void addObjectToBlockArray(ASTNode* blockNode, ASTNode* object){
    int count = blockNode->data.block.count;
    int capacity = blockNode->data.block.capacity;
    if (count >= capacity) {
        capacity *= 2;
        blockNode->data.block.statements = realloc(blockNode->data.block.statements, sizeof(ASTNode*) * capacity);
        blockNode->data.block.capacity = capacity;
    }
    blockNode->data.block.statements[(blockNode->data.block.count)++] = object;
}

void printAST(ASTNode* node, int parent_id, FILE* out) {
    if (!node) return; 

    static int id_counter = 0;
    int my_id = ++id_counter;

    switch (node->type) {
        case AST_CONST:
            fprintf(out, "node%d [label=\"const %d\"]\n", my_id, node->data.constant.value);
            break;
        case AST_VAR:
            fprintf(out, "node%d [label=\"var %s\"]\n", my_id, node->data.variable.name);
            break;
        case AST_STRING:
            fprintf(out, "node%d [label=\"string %s\"]\n", my_id, node->data.string.value);
            break;
        case AST_BINOP:
            if (node->data.binop.op == LEFT_OP)
                fprintf(out, "node%d [label=\"binop <<\"]\n", my_id);
            else if (node->data.binop.op == RIGHT_OP)
                fprintf(out, "node%d [label=\"binop >>\"]\n", my_id);
            else if (node->data.binop.op == LE_OP)
                fprintf(out, "node%d [label=\"binop <=\"]\n", my_id);
            else if (node->data.binop.op == GE_OP)
                fprintf(out, "node%d [label=\"binop >=\"]\n", my_id);
            else if (node->data.binop.op == EQ_OP)
                fprintf(out, "node%d [label=\"binop ==\"]\n", my_id);
            else if (node->data.binop.op == NE_OP)
                fprintf(out, "node%d [label=\"binop !=\"]\n", my_id);
            else
                fprintf(out, "node%d [label=\"binop %c\"]\n", my_id, node->data.binop.op);
            break;
        case AST_UNARY:
            if (node->data.unary.op == INC_OP)
                fprintf(out, "node%d [label=\"unary ++\"]\n", my_id);
            else if (node->data.unary.op == DEC_OP)
                fprintf(out, "node%d [label=\"unary --\"]\n", my_id);
            else if (node->data.unary.op == SIZEOF)
                fprintf(out, "node%d [label=\"unary sizeof\"]\n", my_id);
            else
            fprintf(out, "node%d [label=\"unary %c\"]\n", my_id, node->data.unary.op);
            break;
        case AST_ASSIGN:
            fprintf(out, "node%d [label=\"assign op %c\"]\n", my_id, node->data.assign.assignment_op);
            break;
        case AST_IF:
            fprintf(out, "node%d [label=\"if\"]\n", my_id);
            break;
        case AST_FOR:
            fprintf(out, "node%d [label=\"for\"]\n", my_id);
            break;
        case AST_WHILE:
            fprintf(out, "node%d [label=\"while\"]\n", my_id);
            break;
        case AST_BLOCK:
            fprintf(out, "node%d [label=\"block\"]\n", my_id);
            break;
        case AST_FUNC_CALL:
            fprintf(out, "node%d [label=\"func call %s\"]\n", my_id, node->data.function_call.func_name);
            break;
        case AST_RETURN:
            fprintf(out, "node%d [label=\"return\"]\n", my_id);
            break;
        case AST_ENUM_CONST:
            fprintf(out, "node%d [label=\"enum const %s\"]\n", my_id, node->data.enum_const.name);
            break;
        case AST_FUNCTION_DECL:
            fprintf(out, "node%d [label=\"function decl %s\"]\n", my_id, node->data.function_decl.name);
            break;
        case AST_FUNCTION_DEF:
            fprintf(out, "node%d [label=\"function def\"]\n", my_id);
            break;
        case AST_STRUCT_DEF:
            fprintf(out, "node%d [label=\"struct def %s\"]\n", my_id, node->data.struct_def.name);
            break;
        case AST_TYPE:
            fprintf(out, "node%d [label=\"type %s\"]\n", my_id, node->data.type_container.name ? node->data.type_container.name : getTypeName(node->data.type_container.type));
            break;
        case AST_MEMBER_ACCESS:
            fprintf(out, "node%d [label=\"member access %s\"]\n", my_id,      node->data.member_access.field);
            break;
        case AST_VAR_DECL:
            fprintf(out, "node%d [label=\"var decl %s\"]\n", my_id, node->data.variable_decl.name);
            break;
        case AST_ENUM_DEF:
            fprintf(out, "node%d [label=\"enum def %s\"]\n", my_id, node->data.enum_def.name);
            break;          

        default:
            fprintf(out, "node%d [label=\"unknown %d\"]\n", my_id, node->type);
    }

    if (parent_id != 0) {
        fprintf(out, "node%d -> node%d\n", parent_id, my_id);

    }
    if (node->type == AST_BINOP) {
        printAST(node->data.binop.left, my_id, out);
        printAST(node->data.binop.right, my_id, out);
    } else if (node->type == AST_UNARY) {
        printAST(node->data.unary.operand, my_id, out);
    } else if (node->type == AST_ASSIGN) {
        printAST(node->data.assign.var, my_id, out);
        printAST(node->data.assign.value, my_id, out);
    } else if (node->type == AST_IF) {
        printAST(node->data.if_stmt.condition, my_id, out);
        printAST(node->data.if_stmt.if_body, my_id, out);
        printAST(node->data.if_stmt.else_branch, my_id, out);
    } else if (node->type == AST_FOR) {
        printAST(node->data.for_stmt.init, my_id, out);
        printAST(node->data.for_stmt.condition, my_id, out);
        printAST(node->data.for_stmt.increment, my_id, out);
        printAST(node->data.for_stmt.body, my_id, out);
    } else if (node->type == AST_WHILE) {
        printAST(node->data.while_stmt.condition, my_id, out);
        printAST(node->data.while_stmt.body, my_id, out);
    } else if (node->type == AST_BLOCK) {
        for (int i = 0; i < node->data.block.count; i++) {
            printAST(node->data.block.statements[i], my_id, out);
        }
    } else if (node->type == AST_FUNC_CALL) {
        printAST(node->data.function_call.args, my_id, out);
    } else if (node->type == AST_RETURN) {
        printAST(node->data.return_stmt.return_value, my_id, out);
    } else if (node->type == AST_FUNCTION_DEF) {
        printAST(node->data.function_def.declaration, my_id, out);
        printAST(node->data.function_def.body, my_id, out);
    } else if (node->type == AST_STRUCT_DEF) {
        printAST(node->data.struct_def.body, my_id, out);
    } else if (node->type == AST_ENUM_DEF) {
        printAST(node->data.enum_def.body, my_id, out);
    } else if (node->type == AST_FUNCTION_DECL) {
        printAST(node->data.function_decl.args, my_id, out);
    }
    
}

const char* getTypeName(BaseType type) {
    switch (type) {
        case TYPE_INT: return "int";
        case TYPE_CHAR: return "char";
        case TYPE_FLOAT: return "float";
        case TYPE_DOUBLE: return "double";
        case TYPE_VOID: return "void";
        default: return "unknown";
    }
}