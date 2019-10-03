import sys
import os
import re
from operator import itemgetter

#KindAxiom = 0
#KindUsedIn = 1
#KindSkip = 2

d = dict()

name = "N/A"
used_count = 0

def finish_one():
    global d, name, used_count
    assert name != "N/A"
    old = 0
    if name in d:
        old = d[name]
    toAdd = 1
    if used_count > 0:
        toAdd = used_count
    d[name] = old + toAdd
    name = "N/A"
    used_count = 0

def print_stats():
    global d
    print("Admit stats:")
    tot = 0
    for name, count in sorted(d.items(), key=itemgetter(1), reverse=True):
        tot += count
        print("%5d %s" % (count, name))
    print("%5d %s" % (tot, "TOTAL"))

def main():
    global name, used_count

    filepath = sys.argv[1]

    if not os.path.isfile(filepath):
        print("File path {} does not exist. Exiting...".format(filepath))
        sys.exit()

    is_first = True

    with open(filepath) as fp:
        line = fp.readline()
        assert line.rstrip() == "Axioms:"
        for line in fp:
            m = re.match("^    .*", line)
            if m:
                assert not is_first
            else:
                m = re.match("^ used in .*", line)
                if m:
                    assert not is_first
                    used_count += 1
                else:
                    m = re.match("^[^ :]*?([^ .:]+) :", line)
                    if m:
                        if not is_first:
                            finish_one()
                        name = m.group(1)
                    else:
                        print("Unexpected line: {}".format(line))
                        sys.exit()
            is_first = False

    if not is_first:
        finish_one()

    print_stats()

if __name__ == '__main__':
   main()
