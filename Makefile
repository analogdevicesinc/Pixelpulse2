main: Plot/libPlot.so SMU/libSMU.so

Plot/libPlot.so: Plot/*.h Plot/*.cpp
	(cd Plot; qmake .)
	$(MAKE) -C Plot

SMU/libSMU.so: SMU/*.h SMU/*.cpp libsmu/smu.a libsmu/libsmu.hpp
	(cd SMU; qmake .)
	$(MAKE) -C SMU

libsmu/smu.a: libsmu/*.hpp libsmu/*.cpp
	$(MAKE) -C libsmu
	rm -f SMU/libSMU.so # so it rebuilds
