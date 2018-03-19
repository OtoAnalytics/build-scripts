#!/usr/bin/env python

# Given coveralls API JSON piped into stdin, will exit with code 1 if coverage is less than
# 80% or has decreased more than 3%, will exit with code 255 if coveralls is still processing
# the build, and will exit with code 0 otherwise

import json;
import sys;

report = json.load(sys.stdin);
if report['covered_percent'] is None:
    sys.exit(255)
else:
    print "Build for repo '%s' had %g%% code coverage, an increase/decrease of %g from the last build" % \
        (report['repo_name'], report['covered_percent'], report['coverage_change'])
    if report['covered_percent'] < 80 or report['coverage_change'] < -3:
        sys.exit(1)
    else:
        sys.exit(0)