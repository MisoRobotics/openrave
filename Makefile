CMAKE_BUILD_TYPE=$(shell if [ $(DEBUG) ]; then echo Debug; else echo RelWithDebInfo; fi)

BUILD_DIR=build

all:
	@mkdir -p $(BUILD_DIR); rm -f $(BUILD_DIR)/CMakeCache.txt
	@if [ $(prefix) ]; then \
		cd $(BUILD_DIR) && cmake -DCMAKE_INSTALL_PREFIX=$(prefix) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) ..; \
	else \
		cd $(BUILD_DIR) && cmake -DCMAKE_VERBOSE_MAKEFILE=OFF -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) ..; \
	fi
	cd $(BUILD_DIR) && $(MAKE) $(PARALLEL_JOBS)

install:
	cd $(BUILD_DIR) && $(MAKE) $(PARALLEL_JOBS) install

uninstall:
	cd $(BUILD_DIR) && $(MAKE) uninstall

test: all
	cd $(BUILD_DIR) && $(MAKE) $(PARALLEL_JOBS) install
	export PATH=`sh $(BUILD_DIR)/openrave-config --prefix`/bin:$(PATH) && export PYTHONPATH=`openrave-config --python-dir`:$(PYTHONPATH) && export LD_LIBRARY_PATH=`openrave-config --prefix`/lib:$(LD_LIBRARY_PATH) && cd test && python run_tests.py $PARALLEL_JOBS

docs: all
	cd $(BUILD_DIR) && $(MAKE) $(PARALLEL_JOBS) install
	export PATH=`sh $(BUILD_DIR)/openrave-config --prefix`/bin:$(PATH) && export PYTHONPATH=`openrave-config --python-dir`:$(PYTHONPATH) && export LD_LIBRARY_PATH=`openrave-config --prefix`/lib:$(LD_LIBRARY_PATH) && cd docs && ./build.sh

clean:
	-cd $(BUILD_DIR) && $(MAKE) clean
	rm -rf $(BUILD_DIR)

deb:
	@mkdir -p $(BUILD_DIR); rm -f $(BUILD_DIR)/CMakeCache.txt
	cd $(BUILD_DIR) && cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DOPENRAVE_PLUGIN_QTOSGRAVE=OFF -DOPT_EXTRA_ROBOTS=OFF -DOPT_OCTAVE=OFF -DOPT_MATLAB=OFF -DCMAKE_CXX_STANDARD=11 -DOPT_BUILD_PACKAGES=ON ..
	cd $(BUILD_DIR) && $(MAKE) $(PARALLEL_JOBS)
	cd $(BUILD_DIR) && cpack -G DEB

install-deb:
	dpkg -i \
		$(BUILD_DIR)/OpenRAVE-0.9.0.0-Linux-openrave0.9-dp-base.deb \
		$(BUILD_DIR)/OpenRAVE-0.9.0.0-Linux-openrave0.9-dp.deb \
		$(BUILD_DIR)/OpenRAVE-0.9.0.0-Linux-openrave0.9-dp-plugins-base.deb \
		$(BUILD_DIR)/OpenRAVE-0.9.0.0-Linux-openrave0.9-dp-plugin-fclrave.deb \
		$(BUILD_DIR)/OpenRAVE-0.9.0.0-Linux-openrave0.9-dp-python.deb


uninstall-deb:
	apt-get autoremove "openrave*"
