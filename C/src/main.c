#include <stdio.h>
#include <string.h>
#include <sys/time.h>

#include "grid.h"

float timedifference_msec(struct timeval t0, struct timeval t1) {
    return (t1.tv_sec - t0.tv_sec) * 1000.0f + (t1.tv_usec - t0.tv_usec) / 1000.0f;
}

int main(int argc, char *argv[]) {
	struct timeval t0;
	struct timeval t1;
	float elapsed;
	init_structures();
	//set("4.27.6...........656..1..7.....5.21.1.......8.87.9.....3..7..658...........9.84.1");
	set("800000000003600000070090200050007000000045700000100030001000068008500010090000400");
	if (argc > 1) {
		if (
			( strlen(argv[1]) == 81 )
		) {
			reinit();
			set(argv[1]);
		}
	}
	//set("080000000205003600300820700000600001004138500900007000002065009001700205000000040");
	printf("\n===================\n    Input Grid\n===================\n");
	print();
	init_stack();
	gettimeofday(&t0, 0);
	solve();
	gettimeofday(&t1, 0);
	printf("\n===================\n     Solution\n===================\n");
	print();
	elapsed = timedifference_msec(t0, t1);
	printf("\ntime in miliseconds: %3.6f", elapsed );
    return 0;
}
