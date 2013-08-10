CC		:=	gcc -m32
CC_FLAGS	:=	-Wall -g
ASM		:=	nasm
ASM_FLAGS	:=	-f elf -g
LINK		:=	ld

SRC_DIR		:=	src
OBJ_DIR		:=	obj
LIST_DIR	:=	list
BIN_DIR		:=	bin

all: corwars

corwars: $(OBJ_DIR)/main.o $(OBJ_DIR)/ass3.o $(OBJ_DIR)/sched.o
	$(CC) -o $(BIN_DIR)/corwars $(OBJ_DIR)/main.o $(OBJ_DIR)/ass3.o $(OBJ_DIR)/sched.o

# .c/.s compile rules
$(OBJ_DIR)/%.o : $(SRC_DIR)/%.c
	$(CC) -c $(CC_FLAGS) $< -o $@

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.s
	$(ASM) $(ASM_FLAGS) $< -o $@ -l $(subst .o,.lst,$(subst $(OBJ_DIR),$(LIST_DIR),$@))

clean:
	rm $(BIN_DIR)/*.* $(OBJ_DIR)/*.o $(LIST_DIR)/*.lst
