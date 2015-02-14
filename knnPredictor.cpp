// Netflix dataset KNN classifier. 

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream> 
#include <cmath>
#include <map>
#include <ctime>

using namespace std;

class UserRating {
	public:
		int user, numRatings;
};
bool comparesize (UserRating i,UserRating j) { return (i.numRatings>j.numRatings); }
class MovieRating {
	public:
		int movie, rating;
};
bool comparemovie (MovieRating i,MovieRating j) { return (i.movie<j.movie); }
class Parsons {
	public:
		int user;
		float p;
};
bool compareparsons (Parsons i,Parsons j) { return (i.p>j.p); }

int main() {
	string s;
	fstream exampleFile("data1.dta", ios::in);
	fstream queryFile("qual.dta", ios::in);
	ofstream out;
 	out.open ("predictions.txt");
	int n=0;
	double sum=0;

	//each point stores movieid, rating
	int numUsers=460000;
	int numMovies=18000;
	int Q=1000;
	int K=100;
	vector< vector<MovieRating> > userMovies; //stores lists of movies rated by a user
	for (int i=0; i<=numUsers; i++) {
		userMovies.push_back(vector<MovieRating>());
	}

	//storage is like arr[user][movie]=rating
	vector< map<int,int> > userMovieRatings = vector< map<int,int> >(); 
	for(int i=0; i<=numUsers; i++) {
		userMovieRatings.push_back( map<int,int>() );
	}

	// parse input file
	int count=0;
	while (exampleFile.good()) {
		count++;
		if (count%100000==0) {cout << yu << endl;}
		//tokenize line
		getline(exampleFile, s);
		if(count%3==0) { continue; } //TEMP debug
		if (s=="") { continue; }
		string delimiter=" ";
		size_t pos = s.find(delimiter);
		int user,movie,rating;
		string token = s.substr(0, pos);
		istringstream(token) >> user;
		s.erase(0, pos + delimiter.length());
		pos = s.find(delimiter);
		token = s.substr(0, pos);
		istringstream(token) >> movie;
		s.erase(0, pos + delimiter.length());
		pos = s.find(delimiter);
		token = s.substr(0, pos);
		s.erase(0, pos + delimiter.length());
		pos = s.find(delimiter);
		token = s.substr(0, pos);
		istringstream(token) >> rating;
		s.erase(0, pos + delimiter.length());
		MovieRating r; r.movie=movie; r.rating=rating;
		userMovies[user].push_back(r);
		userMovieRatings[user][movie]=rating;
	}

	for(int user=0; user<=numUsers; user++) {
		sort(userMovies[user].begin(),userMovies[user].end(),comparemovie);
	}

	//calculate user rating average and stdev
	vector<float> useravg, userstd;
	useravg.push_back(0); userstd.push_back(0);
	for(int i=1; i<=numUsers; i++) {
		if (userMovies[i].size()==0) {
			useravg.push_back(0); userstd.push_back(0);
			continue;
		}
		float sum=0;
		for(int j=0; j<userMovies[i].size(); j++) {
			sum+=userMovies[i][j].rating;
		}
		useravg.push_back( sum/userMovies[i].size() );
		float sqrsum=0;
		for(int j=0; j<userMovies[i].size(); j++) {
			float d=(userMovies[i][j].rating-useravg[i]);
			sqrsum+=d*d;
		}
		userstd.push_back( sqrt( sqrsum/userMovies[i].size() ) );
	}

	///select Q people who have rated the most movies
	vector<UserRating> userratings;
	for(int i=1; i<=numUsers; i++) {
		UserRating pair;
		pair.user=i;
		pair.numRatings=userMovies[i].size();
		userratings.push_back(pair);
	}
	sort(userratings.begin(),userratings.end(),comparesize);
	int usersComparingAgainst[Q];
	for(int i=0; i<Q; i++) {
		usersComparingAgainst[i]=userratings[i].user;
	}

	//set up query storage representations
	vector< vector<int> > queryusermovies;
	vector< vector<int> > queryusermoviespos; //stores query position of movie
	for(int i=0; i<=numUsers; i++) {
		queryusermovies.push_back(vector<int>());
		queryusermoviespos.push_back(vector<int>());
	}

	// parse test data
	int linenum=0;
	while (queryFile.good()) {
		//tokenize line
		getline(queryFile, s);
		if(s=="") continue;
		string delimiter=" ";
		size_t pos = s.find(delimiter);
		int user,movie;
		string token = s.substr(0, pos);
		istringstream(token) >> user;
		s.erase(0, pos + delimiter.length());
		pos = s.find(delimiter);
		token = s.substr(0, pos);
		istringstream(token) >> movie;
		queryusermovies[user].push_back(movie);
		queryusermoviespos[user].push_back(linenum);
		linenum++;
	}


	// stores the predictions
	vector<float> answers;
	for(int i=0; i<linenum; i++) {
		answers.push_back(0);
	}

	// loop through users
	for(int user=1; user<=numUsers; user++) {
		//if(user==5000) { break; } //TEMP
		if (user%100==0) {
			cout << user << endl;
		}

		// user has no movies
		if(queryusermovies[user].size()==0) {
			continue;
		}

		//compute p for all possible neighbors
		vector<float> p;
		for(int i=0; i<Q; i++) {
			int user2=usersComparingAgainst[i];
			if (user2==user) {
				p.push_back(0);
				continue;
			}

			//find common movies rated
			float sum=0, sqrsum1=0, sqrsum2=0;
			float n=0;
			int j=0, k=0;
			int movie1=0, movie2=0;
			while(true) {
				if (j>=userMovies[user].size() || k>=userMovies[user2].size()) {
					break;
				}
				movie1=userMovies[user][j].movie;
				movie2=userMovies[user2][k].movie;
				if (movie2<movie1) { k=k+1; }
				else if (movie1<movie2) { j=j+1; }
				else {
					// make calculations that allow for computation of variance and mean
					float d1=userMovies[user][j].rating-useravg[user];
					float d2=userMovies[user2][k].rating-useravg[user2];
					sum+=d1*d2;
					sqrsum1+=d1*d1;
					sqrsum2+=d2*d2;
					n++; j++; k++;
					if(n>5) { break; }
				}
			}

			//compute pearsons from our summations in the last step
			float e=sum/n;
			float std1=sqrt(sqrsum1/n);
			float std2=sqrt(sqrsum2/n);
			float ppre=e/(std1*std2);
			if(std1==0 || std2==0) {
				p.push_back(0); 
			}
			else { 
				p.push_back((1+ppre)/2); 
			}

		}
		//time_t t2= time(0);
		//time1 += t2-t1;

		//attach each userid to the pearson calculations and sort on the pearson score
		vector<Parsons> parsons;
		for(int i=1; i<=Q; i++) {
			Parsons pair;
			pair.p=p[i];
			pair.user=i;
			parsons.push_back(pair);
		}
		sort(parsons.begin(),parsons.end(),compareparsons);

		//loop user's movies
		for(int j=0; j<queryusermovies[user].size(); j++) {
			int movie=queryusermovies[user][j];
			float numerator=0, denominator=0;
			int numused=0;

			//loop the users we want to compare against
			for(int i=0; i<Q; i++) {
				float pp=parsons[i].p;
				int user2=parsons[i].user;
				if(pp<0.1) { break; }
				if(numused>=K) { break; }
				//int rating2=userMovieRatings[user2][movie];
				if( userMovieRatings[user2].count(movie) == 0) { continue; }
				int rating2 = userMovieRatings[user2][movie];
    			//std::map<int,char>::const_iterator search = userMovieRatings[user2].find(movie);
    			//if(search == userMovieRatings[user2].end()) {
    			//	continue;
    			//}
    			//int rating2 = search->first;

    			//calculate basically a normalized weighted average for the two users
				numerator+=(rating2-useravg[user2])*pp;
				denominator+=pp;
				numused++;
			}

			// make a prediction for the given user's rating of a given movie based off of the information
			// we've extracted from similar user's ratings of that movie.
			float dstd=numerator/denominator;
			float ans=dstd*userstd[user]+useravg[user];
			if(dstd!=dstd) { ans=useravg[user]; }
			ans=max(1.0f,ans);
			ans=min(ans,5.0f);
			int index=queryusermoviespos[user][j];
			answers[index]=ans;
		}
		//time3 += time(0)-t3;
	}
	//cout << time1 << " " << time2 << " " << time3 << endl;

	// print predictions
	cout << "ANSWERS" << endl;
	for(int i=0; i<linenum; i++) {
		out << answers[i] << endl;
	}

	exampleFile.close();
	out.close();
	return 0;
} 
