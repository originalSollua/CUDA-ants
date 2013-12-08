/**
 * Copyright 1993-2012 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 */
#include <stdio.h>
#include <stdlib.h>
#include <GL/glut.h>
#include "space.h"
#include <math.h>
#include <time.h>
using namespace std;

int gRand(int);
#define CUDA_CHECK_RETURN(value) {											\
	cudaError_t _m_cudaStat = value;										\
	if (_m_cudaStat != cudaSuccess) {										\
		fprintf(stderr, "Error %s at line %d in file %s\n",					\
				cudaGetErrorString(_m_cudaStat), __LINE__, __FILE__);		\
		exit(1);															\
	} }

__global__ void bug(int cur_row, int cur_col, int d_mrow, int d_mcol, space* d_board, bool path, int dir)
{
	int id =threadIdx.x;
	//printf("%d %d \n", id, id-d_mcol);
	//id is position
	//id +1 = next col over
	//id -1 is to the left
	// id+d_mcol is one row down

	double sN =0;
	double sE =0;
	double sS =0;
	double sW =0;

	bool N =false;
	bool S = false;
	bool E = false;
	bool W = false;


		if(id-d_mcol >= 0)
		{
			if(!d_board[id-d_mcol].is_blocked)
				sN = d_board[id-d_mcol].scent;
			else
				sN = -1;
		}
		if(id+1 < d_mcol)
		{
			if(!d_board[id+1].is_blocked)
				sE = d_board[(id+1)].scent;
			else
				sE = -1;
		}
		if(id+d_mcol < d_mrow)
		{
			if(!d_board[id+d_mcol].is_blocked)
				sS = d_board[id+d_mcol].scent;
			else
				sS = -1;
		}
		if(id-1 >=0)
		{
			if(!d_board[id-1].is_blocked)
				sW = d_board[id-1].scent;
			else
				sW = -1;
		}
		if(sN > sS)
			N = true;
		else
			S = true;
		if(sE > sW)
			E = true;
		else
			W = true;

		if(N && E)
		{
			if(sN > sE)
			{
				N = true;
				E = false;
			}
			else
			{
				N = false;
				E = true;
			}
		}
		else if(N && W)
		{
			if(sN > sW)
			{
				N = true;
				W = false;
			}
			else
			{
				N = false;
				W = true;
			}
		}
		else if (S && E)
		{
			if(sS > sE)
			{
				S = true;
				E = false;
			}
			else
			{
				E = true;
				S = false;
			}
		}
		else
		{
			if(sS > sW)
			{
				S = true;
				W = false;
			}
			else
			{
				S = false;
				W = true;
			}
		}
	if(d_board[id].num_ants > 0)
	{
		double chance = d_board[id].scent;
		double go = dir%((int)chance);
		if(dir%5 ==0)
		{
			if(dir%4 == 0 && sN > 0)
			{
				int *loc = &(d_board[id].num_ants);
				atomicSub(loc, 1);
				(d_board[id].scent)++;
				loc = &(d_board[id-d_mcol].num_ants);
				atomicAdd(loc, 1);
				//printf("north");
			}
			else if(dir%4 == 1 && sE > 0)
			{
				int *loc = &(d_board[id].num_ants);
				atomicSub(loc, 1);
				(d_board[id].scent)++;
				loc = &(d_board[id+1].num_ants);
				atomicAdd(loc, 1);
				//	printf("east");
			}
			else if(dir%4 == 2 && sS > 0)
			{
				int *loc = &(d_board[id].num_ants);
				atomicSub(loc, 1);

				loc = &(d_board[id+d_mcol].num_ants);
				atomicAdd(loc, 1);
				//printf("south");
			}
			else if(dir%4 == 3 && sW > 0)
			{
				int *loc = &(d_board[id].num_ants);
				atomicSub(loc, 1);
				(d_board[id].scent)++;

				loc = &(d_board[id-1].num_ants);
				atomicAdd(loc, 1);
				//	printf("west");
			}
			else
			{

			}
		}
		if(N)
		{
			int *loc = &(d_board[id].num_ants);

			atomicSub(loc, 1);
			(d_board[id].scent)++;
			loc = &(d_board[id-d_mcol].num_ants);
			atomicAdd(loc, 1);
			//printf("north");

		}
		else if(S)
		{
			int *loc = &(d_board[id].num_ants);
			atomicSub(loc, 1);
			(d_board[id].scent)++;

			loc = &(d_board[id+d_mcol].num_ants);
			atomicAdd(loc, 1);
			//printf("south");
		}

		else if(E)
		{
			int *loc = &(d_board[id].num_ants);
			atomicSub(loc, 1);
			(d_board[id].scent)++;
			loc = &(d_board[id+1].num_ants);
			atomicAdd(loc, 1);
		//	printf("east");
		}
		else if(W)
		{
			int *loc = &(d_board[id].num_ants);
			atomicSub(loc, 1);
			(d_board[id].scent)++;
			loc = &(d_board[id-1].num_ants);
			atomicAdd(loc, 1);
		//	printf("west");

		}
		else
		{
			printf("WAT /n");
		}

		printf("%d moved to %d %d\n", id, cur_row, cur_col);

		if((d_board[(cur_row)*(d_mcol)+cur_col].food_count >=0))
		{
			int *locfood = &(d_board[(cur_row)*(d_mcol)+cur_col].food_count);
			d_board[(cur_row)*(d_mcol)+cur_col].food_count=atomicSub(locfood, 1);

		}

	//printf("food left: %d\n", d_board[(cur_row)*(d_mcol)+cur_col].food_count);
	}

}


int main(int argc,char** argv) {

	printf("Hello Wrold\n");
	// these valuse dictate most of the behaviors.
	int row = 10;
	int col = 10;
	int start_ants = 4;	//this many ants thrown at the board to begin with

	srand(time(NULL));
	int hr = gRand(row/2); // row pos of home space make it random
	int hc = gRand(col/2); // col pos of home space make it random
	int br = gRand(row); // row pos of blocked start point. make it random
	int bc = gRand(col); // col pos of blocked start point. make it random


	int x = gRand(row-1);	//address the one d array with 2 d offset values.
	int y = gRand(col-1);

	//*** address formula cats[xpos*col+ypos]

	// board created below

	space* cats = new space[row*col];

	// populate the board
	cats[hr*col+hc].set_home();
	cats[(row-1)*col+(col-1)].food_mod(1000); // hypothetically, passing a negative number will decriment food count.
	cats[hr*col+hc].many_ants(start_ants);		//works


	if(br>= hr && bc >= hc)
	{
		int count = 3;
		for(int i = br; i < row; i++)
		{
				int roll = gRand(10);
				if(roll == 5 && count > 0)
				{
					count--;
				}
				else
				{
					cats[(i)*col+(bc)].waller();
				}

		}
		count = 3;
		for(int i = bc; i < col; i++)
		{
			int roll = gRand(10);
			printf("%d ", roll);
			if(roll == 5 && count > 0)
			{
				count--;
			}
			else
			{
				cats[(br)*col+(i)].waller();
			}
		}
		count = 3;

	}
		// bugs launched knowing home position, max rows, max cols, and the board in shared memory

	for(int i = 0; i < row; i++)
	{
		for(int j = 0; j < col; j++)
		{
			int pos = i*col+j;
			double s = sqrt((i*i)+(j*j));
			cats[pos].scent = s;
		}
	}
	for(int i = 0; i< row; i++)
			{
				for(int j = 0; j < col; j++)
				{
					printf("%d ",cats[i*col+j].num_ants);
				}
				printf("\n");
			}

	printf("%d \n", cats[(row-1)*col+(col-1)].food_count);
	printf("\nhome: %d,%d wallstart: %d, %d\n", hr, hc, br, bc);
	int count = 200;
//	while(cats[(row-1)*col+(col-1)].food_count ==1000)
	while(count > 0)
	{
	int* cur_row;
	int* cur_col;
	int* d_row;
	int* d_col;

	space* d_board;
	space* h_board = &cats[0];


	CUDA_CHECK_RETURN(cudaMalloc(&cur_col, sizeof(int)));
	CUDA_CHECK_RETURN(cudaMalloc(&d_row, sizeof(int)));
	CUDA_CHECK_RETURN(cudaMalloc(&d_col, sizeof(int)));
	CUDA_CHECK_RETURN(cudaMalloc(&cur_row, sizeof(int)));
	CUDA_CHECK_RETURN(cudaMalloc(&d_board, sizeof(space)*row*col));


	CUDA_CHECK_RETURN(cudaMemcpy(cur_row, &hr, sizeof(int), cudaMemcpyHostToDevice));
	CUDA_CHECK_RETURN(cudaMemcpy(cur_col, &hc, sizeof(int), cudaMemcpyHostToDevice));
	CUDA_CHECK_RETURN(cudaMemcpy(d_row, &row, sizeof(int), cudaMemcpyHostToDevice));
	CUDA_CHECK_RETURN(cudaMemcpy(d_col, &col, sizeof(int), cudaMemcpyHostToDevice));
	CUDA_CHECK_RETURN(cudaMemcpy(d_board, h_board, sizeof(space)*row*col, cudaMemcpyHostToDevice));
	dim3 grid(1, 1, 1);
	dim3 block(10, 10, 1);
	bool path = true;
	int dir = gRand(101);
	bug<<<1, row*col>>>(hr, hc, row, col, d_board, path, dir);

	CUDA_CHECK_RETURN(cudaThreadSynchronize());	// Wait for the GPU launcint a = board[0].get_ants();hed work to complete
	CUDA_CHECK_RETURN(cudaGetLastError());

	CUDA_CHECK_RETURN(cudaMemcpy(h_board, d_board, sizeof(space)*row*col, cudaMemcpyDeviceToHost));
	//CUDA_CHECK_RETURN(cudaMemcpy(&posr, cur_row, sizeof(int), cudaMemcpyDeviceToHost));
	//CUDA_CHECK_RETURN(cudaMemcpy(&posc, cur_col, sizeof(int), cudaMemcpyDeviceToHost));

	CUDA_CHECK_RETURN(cudaFree((void*)cur_row));
	CUDA_CHECK_RETURN(cudaFree((void*)cur_col));
	CUDA_CHECK_RETURN(cudaFree((void*)d_row));
	CUDA_CHECK_RETURN(cudaFree((void*)d_col));
	CUDA_CHECK_RETURN(cudaDeviceReset());
	count--;
	for(int i = 0; i< row; i++)
			{
				for(int j = 0; j < col; j++)
				{
					if(cats[i*col+j].num_ants < 0)
					{
						cats[i*col+j].num_ants = 0;
					}
					if(cats[i*col+j].num_ants < 1)
					{
						cats[i*col+j].scent = (cats[i*col+j].scent)*.90;
					}
				}
			}
	}

	for(int i = 0; i< row; i++)
		{
			for(int j = 0; j < col; j++)
			{
				if(cats[i*col+j].is_blocked)
				{
					printf("B ");
				}
				else
				printf("%d ",(int)cats[i*col+j].scent);
			}
			printf("\n");
		}
	//printf("\n %d %d\n", posr, posc);
	return 0;
}

int gRand(int max){

	int r = (int)rand()%max;
	return r;
}


