# Test process

This process contains various tests to verify to validate the program behavior.  
Those tests can be done manually using the web interface.
By default, not specified fields are considered as in automatic mode.

---------------------

## Test 1
**Testing target heading, when hitting maximum distance from route (>20.0m) on the left.**

Fixed conditions:  

* *GPS* : 0, -0.000179865  
* *Target Position* : 1, 0

Expected results:

* *Target heading* : 31deg

---------------------

## Test 2
**Testing target heading, when hitting maximum distance from route (>20.0m) on the right.**

Fixed conditions:  

* *GPS* : 0, 0.000179865  
* *Target Position* : 1, 0

Expected results:

* *Target heading* : 329deg

---------------------

## Test {{TEST_NUMBER}}
**{{DESCRIPTION}}**

Fixed conditions:  

* *{{PARAM_NAME}}* : {{VALUE}}

Expected results:

* *{{PARAM_NAME}}* : {{VALUE}}
