%{
	#include <stdio.h>
	#include <iostream>
	#include <string>
	#include <vector>
	#include <map>
	using namespace std;
	#include "y.tab.h"
	extern FILE 			*yyin;
	extern int			yylex();
	void				yyerror(string s);
	void 				adjustIndentationAndBraces(string str);
	void				add_variable_name(string &vars, string str, string element, int status);
	void			        adjustOpenIfVector(int num_of_tabs, int& maximum_number_of_tabs_required, std::vector<bool>& open_if_vector, bool add_one);
	bool				search(string str, string ctrl);
	int				num_of_tabs=0;
	int				linenum=1;
	int				maximum_number_of_tabs_required = 0;
	bool 				isValidStructure = false;
	vector<bool> 			open_if_vector;
	string             	        int_vars = "";
	string				float_vars = "";
	string				string_vars = "";
	map<string, int>		valids;
	bool				is_plus;
	string				unaryOperationSign;
	int				status[2];
	string				cpp = "void main()\n{\n";
	string				tmp = "";
	string				assignment = "";
	string				elm;
%}

%union
{
	char	*str;
}

%token <str> IDENT STRING PLUS MINUS MULTIPLY DIVIDE INT FLOAT EQUAL IF ELIF ELSE COMPARISON NEWLINE COLON TAB

%%

	program:
		statements
		|
		newlines statements
		;

	newline:
		NEWLINE {linenum++;};

	newlines:
		newline
		|
		newline newlines
		;

	statements:
		|
		statement
		|
		statement newlines statements
		;

	indentation_level:
		TAB {num_of_tabs++;};

	comparison_operator:
		COMPARISON
		{
			string element($1);
			free($1);
			tmp += " " + element;
		}
		;

	statement:
		indentation_level statement
		|
		
		IF { adjustIndentationAndBraces("if ("); } unary_operator {
		tmp += unaryOperationSign;
		} 
		expression{
		status[0] = status[1]; tmp += elm; if (unaryOperationSign != "" && status[0] == 3) {
					cout << "type inconsistency in line " << linenum << endl;
					exit(1);
				}
		} 
		comparison_operator unary_operator {
				tmp += unaryOperationSign;} 
		expression {
			tmp += elm + ")\n";} 
		COLON {
			for (int i = 0; i <= num_of_tabs; i++)
				tmp += "\t";
			tmp += "{\n";
			if ((isValidStructure && num_of_tabs != maximum_number_of_tabs_required) || num_of_tabs > maximum_number_of_tabs_required) {
				cout << "there is a tab inconsistency in line " << linenum << endl;
				exit(1);
			}
			if (num_of_tabs >= open_if_vector.size())
				open_if_vector.push_back(true);
			else
				open_if_vector[num_of_tabs] = true;
			adjustOpenIfVector(num_of_tabs, maximum_number_of_tabs_required, open_if_vector, true);

			maximum_number_of_tabs_required++;
			isValidStructure = true;
			num_of_tabs = 0;
			if ((status[0] == 3 || status[1] == 3) && ((status[0] != 3 || status[1] != 3) || (unaryOperationSign != "" && status[1] == 3)))
			{
				cout << "type inconsistency in line " << linenum << endl;
				exit(1);
			}
			if (status[0] == 1 && status[1] == 2)
				status[0] = 2;
		}
		|
		ELIF {adjustIndentationAndBraces("else if (");} unary_operator{tmp += unaryOperationSign;} expression {status[0] = status[1]; tmp += elm; if (unaryOperationSign != "" && status[0] == 3) {
					cout << "type inconsistency in line " << linenum << endl;
					exit(1);
				}} comparison_operator unary_operator{tmp += unaryOperationSign;} expression {tmp += elm + ")\n";} COLON
		{
			for (int i = 0; i <= num_of_tabs; i++)
				tmp += "\t";
			tmp += "{\n";
			if (isValidStructure || num_of_tabs > maximum_number_of_tabs_required) {
				cout << "there is a tab inconsistency in line " << linenum << endl;
				exit(1);
			}
			adjustOpenIfVector(num_of_tabs, maximum_number_of_tabs_required, open_if_vector, true);

			if (num_of_tabs >= open_if_vector.size() ||  !open_if_vector[num_of_tabs]) {
				cout << "if/else consistency in line " << linenum << endl;
				exit(1);
			}
			maximum_number_of_tabs_required++;
			isValidStructure = true;
			num_of_tabs = 0;
			if ((status[0] == 3 || status[1] == 3) && ((status[0] != 3 || status[1] != 3) || (unaryOperationSign != "" && status[1] == 3)))
			{
				cout << "type inconsistency in line " << linenum << endl;
				exit(1);
			}
			if (status[0] == 1 && status[1] == 2)
				status[0] = 2;
		}
		|
		ELSE
		{
			adjustIndentationAndBraces("else\n");
			if (isValidStructure || num_of_tabs > maximum_number_of_tabs_required) {
				cout << "there is a tab inconsistency in line " << linenum << endl;
				exit(1);
			}
			adjustOpenIfVector(num_of_tabs, maximum_number_of_tabs_required, open_if_vector, true);

			for (int i = 0; i <= num_of_tabs; i++)
				tmp += "\t";
			tmp += "{\n";
			if (num_of_tabs >= open_if_vector.size() ||  !open_if_vector[num_of_tabs]) {
				cout << "if/else consistency in line " << linenum << endl;
				exit(1);
			}
			open_if_vector[num_of_tabs] = false;
			maximum_number_of_tabs_required++;
			isValidStructure = true;
			num_of_tabs = 0;
		}
		|
		IDENT{ adjustIndentationAndBraces(""); assignment = "";} EQUAL unary_operator{assignment += unaryOperationSign;} assignment_expression
		{
			string	element($1);
			free($1);
			if ((isValidStructure && num_of_tabs != maximum_number_of_tabs_required) || num_of_tabs > maximum_number_of_tabs_required) {
				cout << "there is a tab inconsistency in line " << linenum << endl;
				exit(1);
			}
			adjustOpenIfVector(num_of_tabs, maximum_number_of_tabs_required, open_if_vector, false);

			isValidStructure = false;
			num_of_tabs = 0;
			if (status[0] == 1)
				add_variable_name(int_vars, "_int", element, 1);
			else if (status[0] == 2)
				add_variable_name(float_vars, "_flt", element, 2);
			else if (status[0] == 3) {
				if (unaryOperationSign != "") {
					cout << "type inconsistency in line " << linenum << endl;
					exit(1);
				}
				add_variable_name(string_vars, "_str", element, 3);
			}
			tmp += assignment + ";\n";
		}
		;

	assignment_expression:
		expression {status[0] = status[1];}
		|
		assignment_expression operator expression
		{
			if ((status[0] == 3 || status[1] == 3) && (status[0] != 3 || status[1] != 3 || !is_plus)) {
				cout << "type inconsistency in line " << linenum << endl;
				exit(1);
			}
			if (status[0] == 1 && status[1] == 2)
					status[0] = 2;
		}
		;

	expression:
		IDENT {
			status[1] = valids[$1];
			if (!status[1]) {
				cout << "name '" << $1 << "' is not defined in line " << linenum << endl;
				free($1);
				exit(1);
			}
			else if (status[1] == 1) 
				elm = " " + string($1) + "_int";
			
			else if (status[1] == 2)
				elm = " " + string($1) + "_flt";
			else if (status[1] == 3)
				elm = " " + string($1) + "_str";
			assignment += elm;
			free($1);
		}
		|
		INT {
			elm = " " + string($1);
			assignment += elm;
			free($1);
			status[1] = 1;
		}
		|
		FLOAT {
			elm = " " + string($1);
			assignment += elm;
			free($1);
			status[1] = 2;
		}
		|
		STRING {
			elm = " " + string($1);
			assignment += elm;
			free($1);
			status[1] = 3;
		}
		;





	unary_operator:
		{unaryOperationSign = "";}
		|
		PLUS {unaryOperationSign = " +";}
		|
		MINUS {unaryOperationSign = " -";}
		;





	operator:
		PLUS {is_plus = true; assignment += " +";}
		|
		MINUS {is_plus = false; assignment += " -";}
		|
		MULTIPLY {is_plus = false; assignment += " *";}
		|
		DIVIDE {is_plus = false; assignment += " /";}
		;
%%

void adjustIndentationAndBraces(string str)
{
	for (int i = maximum_number_of_tabs_required; i >= num_of_tabs + 1; i--) {
		for (int j = 0; j < i; j++)
			tmp += "\t";
		tmp += "}\n";
	}
	for (int i = 0; i <= num_of_tabs; i++)
		tmp += "\t";
	tmp += str;
}


void	add_variable_name(string &vars, string str, string element, int status)
{
	if (!search(vars, element + str)) {
		if (vars.length())
			vars += ",";
		vars += element + str;
	}
	tmp += element + str + " =";
	valids[element] = status;
}

void adjustOpenIfVector(int num_of_tabs, int& maximum_number_of_tabs_required, std::vector<bool>& open_if_vector, bool add_one) {
    if (num_of_tabs < maximum_number_of_tabs_required) {
        int target_size = add_one ? num_of_tabs + 1 : num_of_tabs;
        while (open_if_vector.size() != target_size)
            open_if_vector.pop_back();
        maximum_number_of_tabs_required = num_of_tabs;
    }
}



bool	search(string str, string ctrl)
{
	int	len = 0;
	for (int i = 0; i < str.length(); i++) {
		if (len < ctrl.length() && str[i] == ctrl[len])
			len++;
		else {
			if (len == ctrl.length() && str[i] == ',')
				return true;
			len = 0;
			while (i < str.length() && str[i] != ',')
				i++;
		}
	}

	return len == ctrl.length();
}

void	yyerror(string s){
	cerr<<"Error at line: "<<linenum<<endl;
}

int	yywrap(){
	return 1;
}

int	main(int argc, char *argv[])
{
    /* Call the lexer, then quit. */
    yyin=fopen(argv[1],"r");
    yyparse();
    fclose(yyin);
	if (int_vars.length())
		cpp += "\tint " + int_vars + ";\n";
	if (float_vars.length())
		cpp += "\tfloat " + float_vars + ";\n";
	if (string_vars.length())
		cpp += "\tstring " + string_vars + ";\n";
	cpp += "\n";
	cpp += tmp;
	for (int i = maximum_number_of_tabs_required; i >= num_of_tabs + 1; i--) {
		for (int j = 0; j < i; j++)
			cpp += "\t";
		cpp += "}\n";
	}
	cpp += "}";
	cout << cpp << endl;
    return 0;
}
