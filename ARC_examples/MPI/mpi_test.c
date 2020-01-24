#include <stdio.h>
#include <string.h> 
#include <mpi.h> // knjižnica MPI 

int main(int argc, char *argv[]) 
{ 
	int my_rank; // rank (oznaka) procesa 
	int num_of_processes; // število procesov 
	int source; // rank pošiljatelja 
	int destination; // rank sprejemnika 
	int tag = 0; // zaznamek sporoèila 
	char message[100]; // rezerviran prostor za sporoèilo 
	MPI_Status status; // status sprejema 

	MPI_Init(&argc, &argv); // inicializacija MPI okolja 
	MPI_Comm_rank(MPI_COMM_WORLD, &my_rank); // poizvedba po ranku procesa 
	MPI_Comm_size(MPI_COMM_WORLD, &num_of_processes); // poizvedba po številu procesov 

	if( my_rank != 0 ) // procesi z rankom != 0 imajo enako funkcijo 
	{ 
		sprintf(message, "Poroces %d posilja pozdrav!", my_rank); 
		destination = 0; 
		MPI_Send(message, (int)strlen(message)+1, MPI_CHAR, 
			destination, tag, MPI_COMM_WORLD); 
	} 
	else // proces z rankom == 0 se obnaša drugaèe 
	{ 
		printf("Pozdrav tudi vam!\n\n"); 
		fflush(stdout); 
		for( source = 1; source < num_of_processes; source++) 
		{ 
			MPI_Recv(message, 100, MPI_CHAR, source, tag, MPI_COMM_WORLD, &status); 
			printf("%s\n", message); 
			fflush(stdout); 
		} 
	} 
	MPI_Finalize(); 

	return 0; 
} 
