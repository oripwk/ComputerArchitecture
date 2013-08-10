#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

extern uint32_t tabSize;

void init_co_from_c(uint32_t index, uint8_t type);
void start_sched_from_c(void);
void allocate_table(void);
void free_table(void);
void init_sched_from_c(void);


int main(int argc, char **argv) {
  
    int i;
    int len;
    
    if (argc != 2) {
	printf("Error: invalid number of arguments.\n");
	return EXIT_FAILURE;
    }
    
    for (i = 0; argv[1][i] != '\0'; ++i)
	if (argv[1][i] != 'd'
	    && argv[1][i] != 'k'
            && argv[1][i] != 's') {
	    printf("Error: invalid input string.\n");
	    return EXIT_FAILURE;
	}
    
    len = i;
    tabSize = 3*len + 1;
    
    allocate_table();
    
    init_sched_from_c();
    
    /* Initalize participants in table */
    for (i = 1; i < len+1; ++i)
	init_co_from_c(i, argv[1][i-1]);
    
    /* Put dummy participants in the rest of the table */
    for (; i < tabSize; ++i)
	init_co_from_c(i, 0xFF);
    
    start_sched_from_c();
    
    free_table();
    
    return EXIT_SUCCESS;
}
