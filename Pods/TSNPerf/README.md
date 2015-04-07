TSNPerf
=============
TSNPerf is a high-resolution performance measurement utility class.

Using TSNPerf
-------------
Simply add TSNPerf to your podfile.
```
pod 'TSNPerf'
```
And install it using:
```
pod install
```
Usage Example
-------------
Capturing the performance of a single operation:
```
// Allocate and initialize TSNPerf.
TSNPerf * perf = [[TSNPerf alloc] init];

// Start performance measurement.
[perf start];

// Perform operation(s) to be measured.

// Capture performance measurement.
[perf capture];

// Display performance.
NSLog(@"The operation took %@", [perf stringWithElapsedTime]);
```
Capturing the performance of multiple operations:
```
// Allocate and initialize TSNPerf.
TSNPerf * perf = [[TSNPerf alloc] init];

// Start performance measurement of operation A.
[perf start];

// Perform operation A to be measured.

// Capture performance measurement of operaiton A.
[perf capture];

// Display performance of operation A.
NSLog(@"Operation A took %@", [perf stringWithElapsedTime]);

// Start performance measurement of operation B.
[perf start];

// Perform operation B to be measured.

// Capture performance measurement of operation B.
[perf capture];

// Display performance of operation B.
NSLog(@"Operation B took %@", [perf stringWithElapsedTime]);
```
License
-------
TSNPerf is released under an MIT license, meaning you're free to use it in both closed and open source projects. However, even in a closed source project, please include a publicly-accessible copy of TSNPerf's copyright notice, which you can find in the LICENSE file.

Feedback
--------
If you have any questions, suggestions, or contributions to TSNPerf, please [contact me](mailto:brianlambert@softwarenerd.org).
