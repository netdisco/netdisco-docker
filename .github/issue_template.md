<!---
STOP! If your ticket is about a device not being detected correctly,
see SNMP::Info instead:
https://github.com/netdisco/snmp-info/issues/new

STOP! If you have new MIBs to submit,
see netdisco-mibs instead:
https://github.com/netdisco/netdisco-mibs/issues/new

everything else about Netdisco's docker behaviour is good, here :-D

when including netdisco config snippets, whitespace matters since it's a yaml file
for github issues it really helps if you include the relevant config parts in a codeblock (code fencing)
see the "code" subject on https://guides.github.com/features/mastering-markdown/ for that)
this should preserve spaces in the issue tracker and make troubleshooting quicker
-->


<!--- Provide a general summary of the issue in the Title above -->

## Expected Behavior
<!--- If you're describing a bug, tell us what should happen -->
<!--- If you're suggesting a change/improvement, tell us how it should work -->

## Current Behavior
<!--- If describing a bug, tell us what happens instead of the expected behavior -->
<!--- If suggesting a change/improvement, explain the difference from current behavior -->

## Possible Solution
<!--- Not obligatory, but suggest a fix/reason for the bug, -->
<!--- or ideas how to implement the addition or change -->

## Steps to Reproduce (for bugs)
<!--- Provide a link to a live example, or an unambiguous set of steps to -->
<!--- reproduce this bug. Include code to reproduce, if relevant, or attach screenshots -->
1. 
2. 
3. 
4. 

## Context
<!--- How has this issue affected you? What are you trying to accomplish? -->
<!--- Providing context helps us come up with a solution that is most useful in the real world -->

## Your Environment
<!--- Include as many relevant details about the environment you experienced the bug in -->
* netdisco container versions: 
  * netdisco-postgresql: 
  * netdisco-backend: 
  * netdisco-web: 
* docker engine version: 
* docker-compose version: 
* host operating system: 

## Device information
<!---
if the issue relates to specific devices their info would be usefull
do note that the following command might contain sensitive info, you can
remove this but let us know if you did so
change 1.1.1.1 in the below example with the problematic device's ip

a containerized version of netdisco-do is available:
  curl -Ls -o dc-netdisco-do.yml https://raw.githubusercontent.com/netdisco/netdisco-docker/master/dc-netdisco-do.yml
  docker-compose -f dc-netdisco-do.yml run netdisco-do show -d 1.1.1.1 -e specify -DI
-->
