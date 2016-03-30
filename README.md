Diaspora Federation Behavior Tests
==================================

This is automated test suite for federation of [diaspora*](https://diasporafoundation.org/) pods.

The testsuite uses the modified diaspora-replica to provision and deploy diaspora pods and then runs a test suite. Now the testsuite consists of only simple user sharing requests, but I’ll extend it later. The test examples communicate with the pods using my [diaspora_api](https://github.com/cmrd-senya/diaspora-api) gem, which now uses internal unofficial API, but I plan to support the official API along with it. Thus, it’ll be able to test new pods with API support along with the old pods in the same set.

The documentation is not ready yet and the tests are in early development state. For any questions, especially if you want to try the testsuite contact me: @cmrd-senya on github or [senya@socializer.cc](https://socializer.cc/u/senya) on diaspora*.
