rm -rf build-quick/
git checkout . 
bash -x ../shogun-build-subset/shogun-classes-cleanup.sh src/shogun/classifier/svm/OnlineLibLinear.h
bash -x ../shogun-build-subset/shogun-build.sh build-quick --skip-tests
