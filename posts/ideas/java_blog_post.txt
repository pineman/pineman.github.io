In gitlab ci running on kubernetes:
Aborted (core dumped)
surefire: [ERROR] The forked VM terminated without properly saying goodbye. VM crash or System.exit called?
core dump in jvm
also pods randomly disappearing?? Killed? think it's 100% of resource usage.
exfiltrate dumpstream/hs_err/coredumps
inspect coredump with gdb, and jhsdb hsdb and jstack
https://docs.oracle.com/javase/9/tools/jhsdb.htm#JSWOR-GUID-0345CAEB-71CE-4D71-97FE-AA53A4AB028E
https://download.java.net/java/early_access/panama/docs/specs/man/jhsdb.html
https://bugs.openjdk.org/browse/JDK-8257993
https://bugs.openjdk.org/browse/JDK-6962688
in the end, switching to oracle jdk fixed it ¯\_(ツ)_/¯
