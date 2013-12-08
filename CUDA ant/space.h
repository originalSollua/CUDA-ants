/*
 * space.h
 *
 *  Created on: Nov 7, 2013
 *      Author: hpc
 */

#ifndef SPACE_H_
#define SPACE_H_

/*
 *
 */
class space {
public:
	space();

	void add_ant(){
		num_ants++;
	}
	void many_ants(int num)
	{
		num_ants = num; // make this many ants be at ths space. useful for initial populate.
	}
	void remove_ants(){
		num_ants--;
	}
	void set_home(){
		is_nest = true;
	}
	bool home_yet(){
		return is_nest;
	}
	int get_ants(){
		return num_ants;
	}
	int get_food(){
		return food_count;
	}
	void set_scent(int a){
		scent = a;
	}
	void food_mod(int amt)
	{
		food_count = food_count+ amt;
	}
	void waller(){
		is_blocked = true;
	}

	virtual ~space();
	int num_ants;		//number of ants at the space
	int food_count;
	double scent;		//im[plement his later
	bool is_nest;		//marks the space as a spawn point / return point
	bool is_blocked;	//ants cant be on blocked spaces.
};

#endif /* SPACE_H_ */
